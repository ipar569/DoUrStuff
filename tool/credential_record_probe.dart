// Alternate Flutter target for disposable native acceptance fixtures only.
// The production main never imports this file.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dourstuff/data/auth/native_credential_protection.dart';
import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart';
import 'package:dourstuff/data/local/sign_in_coordinator.dart';
import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:dourstuff/domain/sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

String id(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
final owner = id(1);
final task = SyncEntity(SyncEntityKind.task, [id(2)]);
const vault = NativeCredentialProtection();

void check(bool passed) {
  if (!passed) throw StateError('Probe assertion failed.');
}

class _Provider implements SignInProvider {
  @override
  final backend = Uri.parse('https://synthetic.invalid');
  int calls = 0;
  @override
  Future<PreparedSignIn> prepareGithub(Uri redirect) async =>
      PreparedSignIn(redirect, 'synthetic-verifier');
  @override
  Future<VerifiedSession> exchange(String code, String verifier) async {
    check(code == 'fixture' && verifier == 'synthetic-verifier');
    return VerifiedSession(backend, owner, 'synthetic-refresh');
  }

  @override
  Future<VerifiedSession> refresh(String refreshToken) async {
    calls++;
    check(refreshToken == 'synthetic-refresh');
    return VerifiedSession(backend, owner, refreshToken);
  }
}

class _ExitAfterSeal implements CredentialProtection {
  @override
  Future<Uint8List> seal(String context, String secret) async {
    await vault.seal(context, secret);
    exit(0);
  }

  @override
  Future<String> open(String context, Uint8List ciphertext) =>
      vault.open(context, ciphertext);
}

Future<void> expectUnavailable(Future<Object> call) async {
  try {
    await call;
  } on PlatformException catch (error) {
    if (error.code == 'unavailable') return;
    rethrow;
  } on StateError catch (error) {
    if (error.message == 'Invalid credential record.') return;
    rethrow;
  }
  throw StateError('Unexpected access.');
}

Future<String> pendingIdentity(File file, {required bool create}) async {
  final db = AppDatabase.file(file);
  try {
    if (create) await db.initializeProfile('account-$owner');
    final store = await AccountStore.open(db, owner);
    if (create) {
      final now = DateTime.now().toUtc();
      final at = (serverEpoch: id(3), revision: 0);
      final m = SnapshotManifest(
        token: id(4),
        at: at,
        expiresAtUtc: now.add(const Duration(hours: 1)),
        pageCount: 1,
        recordCount: 0,
        deviceHighWaters: {},
      );
      await store.beginSnapshot(m, now);
      await store.stagePage(
        RecoverySnapshotPage(
          HistorySnapshotPage(
            SnapshotPage(
              token: m.token,
              at: at,
              page: 0,
              isLast: true,
              records: [],
              recovery: [],
            ),
            [],
          ),
          [],
        ),
        now,
      );
      await store.installSnapshot(now);
      await store.commitCommand(
        operationId: id(5),
        entity: task,
        command: 'task.create',
        occurredAtUtc: now,
        patches: {
          'title': FieldPatch(const AbsentBase(), 'Pending synthetic edit'),
          'status_group': FieldPatch(const AbsentBase(), {
            'status': 'todo',
            'completed_at': null,
          }),
          'priority': FieldPatch(const AbsentBase(), 'none'),
          'existence': FieldPatch(const AbsentBase(), true),
        },
      );
    }
    final pending = (await store.projection(task)).proposals.single;
    check(pending.transportState == 'pending');
    return sha256
        .convert(utf8.encode(pending.operation.payloadIdentity))
        .toString();
  } finally {
    await db.close();
  }
}

Future<void> run(Directory dir, String mode) async {
  File file(String name) => File.fromUri(dir.uri.resolve(name));
  final provider = _Provider();
  final redirect = Uri.parse('app.dourstuff.probe://auth/callback');
  final seed = mode == 'seed';
  final journal = file('sign-in-v1.sqlite');
  check(journal.existsSync() != seed);
  final auth = SignInCoordinator.open(
    dir,
    provider,
    mode == 'interrupt-refresh' ? _ExitAfterSeal() : vault,
    redirect,
  );
  Future<void> login() async {
    final attempt = (await auth.begin(expectedOwner: owner))!;
    check(
      await auth.callback('${attempt.browserUrl}&code=fixture') ==
          SignInResult.committed,
    );
  }

  try {
    if (seed) {
      check(!file('profile.sqlite').existsSync());
      await login();
      file('identity').writeAsStringSync(
        await pendingIdentity(file('profile.sqlite'), create: true),
        flush: true,
      );
      file('x.record')
          .writeAsBytesSync(await vault.seal('X', 'synthetic-X'), flush: true);
      file('y.record')
          .writeAsBytesSync(await vault.seal('Y', 'synthetic-Y'), flush: true);
      return;
    }
    final x = file('x.record').readAsBytesSync();
    final y = file('y.record').readAsBytesSync();
    switch (mode) {
      case 'verify':
        check(await vault.open('X', x) == 'synthetic-X');
        await expectUnavailable(vault.open('Y', x));
        final damaged = Uint8List.fromList(x);
        damaged[damaged.length ~/ 2] ^= 1;
        await expectUnavailable(vault.open('X', damaged));
        await expectUnavailable(vault.open('X', Uint8List.fromList([...x, 0])));
        check(await vault.open('Y', y) == 'synthetic-Y');
        check(
          await auth.refresh(auth.retainedSession!) == SignInResult.committed,
        );
      case 'interrupt':
        // Exit with a real uncommitted, already-sealed replacement. The next
        // process must recover the previous token and exact pending operation.
        final lease = auth.retainedSession!;
        final context = jsonEncode([
          provider.backend.toString(),
          redirect.toString(),
          'session',
          lease.generation,
          owner,
        ]);
        final replacement = await vault.seal(context, 'uncommitted');
        final db = sqlite3.open(journal.path);
        db.execute('BEGIN IMMEDIATE');
        db.execute('UPDATE auth_slot SET secret=?', [replacement]);
        check(db.updatedRows == 1);
        exit(0);
      case 'interrupt-refresh':
        await auth.refresh(auth.retainedSession!);
        throw StateError('Expected exit during refresh.');
      case 'recover-refresh':
        check(auth.retainedSession == null && auth.pendingGeneration == null);
        await login();
        check(
          await auth.refresh(auth.retainedSession!) == SignInResult.committed,
        );
      case 'locked':
      case 'lost':
        await expectUnavailable(vault.open('X', x));
        if (mode == 'locked') {
          await expectUnavailable(vault.seal('X', 'fixture'));
        }
        check(
          await auth.refresh(auth.retainedSession!) ==
              SignInResult.storageUnavailable,
        );
        check(auth.retainedSession == null && provider.calls == 0);
        if (mode == 'lost') {
          await login();
          await expectUnavailable(vault.open('X', x));
          check(
            await auth.refresh(auth.retainedSession!) == SignInResult.committed,
          );
        }
      case 'unlock':
        check(await vault.open('X', x) == 'synthetic-X');
        check(auth.retainedSession == null);
        await login();
      default:
        throw StateError('Unknown probe mode.');
    }
    check(
      await pendingIdentity(file('profile.sqlite'), create: false) ==
          file('identity').readAsStringSync(),
    );
  } finally {
    auth.close();
  }
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = Platform.isAndroid
      ? Directory.fromUri(
          (await getApplicationSupportDirectory()).uri.resolve(
            'credential-record-probe/',
          ),
        )
      : Directory(args.single);
  final mode = File.fromUri(dir.uri.resolve('mode')).readAsStringSync().trim();
  final result = File.fromUri(dir.uri.resolve('result'));
  try {
    await run(dir, mode);
    result.writeAsStringSync('passed $mode', flush: true);
    exit(0);
  } catch (_) {
    result.writeAsStringSync('failed $mode', flush: true);
    exit(1);
  }
}
