import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dourstuff/data/auth/github_sign_in.dart';
import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart';
import 'package:dourstuff/data/local/sign_in_coordinator.dart';
import 'package:dourstuff/domain/ports.dart';
import 'package:dourstuff/domain/sign_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

import 'account_commands_test.dart' show createFields;
import 'account_store_test.dart' show id, now, manifest, page, task;

final endpoint = Uri.parse('https://backend.invalid');
final redirect = Uri.parse('app.dourstuff.probe://auth/callback');
final x = id(1), y = id(2);

class _Clock implements Clock {
  DateTime time = now;
  @override
  DateTime nowUtc() => time;
}

// Opaque test handles stand in for native authenticated ciphertext.
class _Vault implements CredentialProtection {
  final records = <(String, String)>[];
  Future<void> Function(String)? beforeSeal;
  bool locked = false;
  @override
  Future<Uint8List> seal(String context, String secret) async {
    await beforeSeal?.call(secret);
    if (locked) throw StateError('locked');
    records.add((context, secret));
    return Uint8List.fromList([records.length - 1]);
  }

  @override
  Future<String> open(String context, Uint8List ciphertext) async {
    final (binding, secret) = records[ciphertext.single];
    if (locked || binding != context) throw StateError('cannot open');
    return secret;
  }
}

class _Provider implements SignInProvider {
  @override
  final Uri backend = endpoint;
  int calls = 0;
  String owner = x;
  String? returnedOwner;
  Uri issuer = endpoint;
  Completer<void>? started;
  Completer<void>? release;

  @override
  Future<PreparedSignIn> prepareGithub(Uri target) async =>
      PreparedSignIn(target, 'synthetic-verifier');

  Future<VerifiedSession> _reply() async {
    calls++;
    final response = VerifiedSession(
      issuer,
      returnedOwner ?? owner,
      'synthetic-refresh-$owner',
    );
    started?.complete();
    final gate = release;
    started = release = null;
    await gate?.future;
    return response;
  }

  @override
  Future<VerifiedSession> exchange(String code, String verifier) {
    expect(verifier, 'synthetic-verifier');
    return _reply();
  }

  @override
  Future<VerifiedSession> refresh(String refreshToken) {
    expect(refreshToken, 'synthetic-refresh-$owner');
    return _reply();
  }
}

void main() {
  late Directory directory;
  late _Vault vault;
  late _Clock clock;
  late _Provider provider;
  late SignInCoordinator auth;
  SignInCoordinator reopen() => SignInCoordinator.open(
    directory,
    provider,
    vault,
    redirect,
    clock: clock,
  );
  String callback(SignInLaunch launch) => '${launch.browserUrl}&code=synthetic';
  Future<SignInLaunch> begin([String? owner]) async =>
      (await auth.begin(expectedOwner: owner))!;
  Future<SignedInOwner> login(String owner) async {
    provider.owner = owner;
    final launch = await begin(owner);
    expect(await auth.callback(callback(launch)), SignInResult.committed);
    return auth.retainedSession!;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sign-in-');
    vault = _Vault();
    clock = _Clock();
    provider = _Provider();
    auth = reopen();
  });
  tearDown(() async {
    auth.close();
    await directory.delete(recursive: true);
  });

  test(
    'SDK GitHub request carries the correlated redirect and S256 challenge',
    () async {
      final sdk = GithubSignIn(endpoint, 'synthetic-public-key');
      final target = redirect.replace(queryParameters: {'attempt': id(7)});
      final result = await sdk.prepareGithub(target);
      final params = result.browserUrl.queryParameters;
      expect(result.browserUrl.origin, endpoint.origin);
      expect(result.browserUrl.path, '/auth/v1/authorize');
      expect(params['provider'], 'github');
      expect(params['redirect_to'], target.toString());
      expect(params['code_challenge_method'], 's256');
      expect(params['code_challenge'], hasLength(43));
      expect(result.browserUrl.toString().contains(result.verifier), isFalse);
    },
  );

  test('SDK exchanges with the retained verifier and rotates only the Supabase refresh token', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final sdk = GithubSignIn(
      Uri.parse('http://127.0.0.1:${server.port}'),
      'synthetic-key',
    );
    final requests = <(String?, Object?)>[];
    server.listen((request) async {
      requests.add((
        request.uri.queryParameters['grant_type'],
        jsonDecode(await utf8.decoder.bind(request).join()),
      ));
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'access_token': 'synthetic-access',
          'token_type': 'bearer',
          'user': {'id': x},
          'provider_token': 'synthetic-github-token',
          'refresh_token': 'synthetic-rotation-${requests.length}',
        }),
      );
      await request.response.close();
    });
    final otherDir = await Directory.fromUri(directory.uri.resolve('sdk/'))
        .create();
    final sdkAuth = SignInCoordinator.open(otherDir, sdk, vault, redirect);
    try {
      final launch = (await sdkAuth.begin(expectedOwner: x))!;
      final target = launch.browserUrl.queryParameters['redirect_to']!;
      expect(
        await sdkAuth.callback('$target&code=synthetic'),
        SignInResult.committed,
      );
      expect(
        await sdkAuth.refresh(sdkAuth.retainedSession!),
        SignInResult.committed,
      );
      expect(requests.first.$1, 'pkce');
      expect(requests.first.$2, {
        'auth_code': 'synthetic',
        'code_verifier': vault.records.first.$2,
      });
      expect(requests.last.$1, 'refresh_token');
      expect(requests.last.$2, {'refresh_token': 'synthetic-rotation-1'});
      expect(vault.records.map((r) => r.$2).skip(1), [
        'synthetic-rotation-1',
        'synthetic-rotation-2',
      ]);
    } finally {
      sdkAuth.close();
    }
  });

  test('restart after a durable claim requires a fresh attempt', () async {
    final attempt = await begin();
    final started = provider.started = Completer<void>();
    final release = provider.release = Completer<void>();
    final lost = auth.callback(callback(attempt));
    await started.future;
    auth.close();
    auth = reopen();
    expect(await auth.callback(callback(attempt)), SignInResult.ignored);
    expect(auth.retainedSession, isNull);
    expect(provider.calls, 1);
    expect((await login(y)).owner, y);
    release.complete();
    expect(await lost, SignInResult.ignored);
  });

  test('restart resumes pending attempt and committed owner, cancellation survives reopen', () async {
    final first = await begin();
    auth.close();
    auth = reopen();
    expect(auth.pendingGeneration, first.generation);
    expect(auth.cancel(first.generation), isTrue);
    final second = await begin();
    auth.close();
    auth = reopen();
    expect(await auth.callback(callback(first)), SignInResult.ignored);
    expect(
      await auth.callback('${first.browserUrl}&error=denied'),
      SignInResult.ignored,
    );
    expect(await auth.callback(callback(second)), SignInResult.committed);
    auth.close();
    auth = reopen();
    expect(auth.retainedSession, (generation: second.generation, owner: x));
    expect(await auth.callback(callback(second)), SignInResult.ignored);
    expect(await auth.refresh(auth.retainedSession!), SignInResult.committed);
  });

  test('only exact, unambiguous code or provider error reaches a pending attempt', () async {
    final attempt = await begin();
    final raw = callback(attempt);
    for (final invalid in [
      raw.replaceFirst('auth/', 'user@auth/'),
      raw.replaceFirst('auth/', 'auth:81/'),
      raw.replaceFirst('probe:', 'other:'),
      raw.replaceFirst('auth/', 'other/'),
      raw.replaceFirst('/callback', '/wrong/../callback'),
      '$raw#',
      '$raw#access_token=a',
      '${attempt.browserUrl}',
      '$raw&code=again',
      '$raw&%63ode=again',
      '$raw&owner=$y',
      '$raw&error=denied',
      '$raw&',
      '$raw&%xx=b',
      '${attempt.browserUrl}&code=%20',
      '${attempt.browserUrl}&code=%ff',
      '$redirect?code=synthetic',
    ]) {
      expect(await auth.callback(invalid), SignInResult.ignored);
    }
    expect(provider.calls, 0);
    expect(
      await auth.callback(
        '${attempt.browserUrl}&error=access_denied&error_description=cancelled',
      ),
      SignInResult.reauthenticate,
    );
    expect(await auth.callback(raw), SignInResult.ignored);
  });

  test(
    'expiry before claim or while exchange is in flight retires the verifier',
    () async {
      var attempt = await begin();
      clock.time = clock.time.add(const Duration(minutes: 10));
      expect(await auth.callback(callback(attempt)), SignInResult.ignored);
      expect(provider.calls, 0);
      attempt = await begin();
      final started = provider.started = Completer<void>();
      final release = provider.release = Completer<void>();
      final pending = auth.callback(callback(attempt));
      await started.future;
      clock.time = clock.time.add(const Duration(minutes: 10));
      release.complete();
      expect(await pending, SignInResult.ignored);
      expect(auth.retainedSession, isNull);
    },
  );

  test('clock correction across restart or during a secure write retires the attempt', () async {
    final first = await begin();
    auth.close();
    clock.time = clock.time.subtract(const Duration(days: 1));
    auth = reopen();
    expect(auth.pendingGeneration, isNull);
    expect(await auth.callback(callback(first)), SignInResult.ignored);
    expect(provider.calls, 0);

    void rewind() {
      clock.time = clock.time.subtract(const Duration(days: 1));
    }

    vault.beforeSeal = (_) async => rewind();
    expect(await auth.begin(), isNull);
    expect(auth.pendingGeneration, isNull);

    vault.beforeSeal = null;
    final next = await begin();
    vault.beforeSeal = (_) async => rewind();
    expect(await auth.callback(callback(next)), SignInResult.ignored);
    expect(auth.retainedSession, isNull);
    expect(auth.pendingGeneration, isNull);
  });

  test('pinned GoTrue error redirect retires only its correlated attempt', () async {
    // Go net/url form-encodes the description, then URL-escapes its fragment.
    const fields =
        'error=access_denied&error_code=bad_oauth_callback&error_description=Denied%3A+cancelled';
    const mirror =
        'error=access_denied&error_code=bad_oauth_callback&error_description=Denied%253A+cancelled&sb=';
    final first = await begin();
    final second = await begin();
    expect(
      await auth.callback('${first.browserUrl}&$fields#$mirror'),
      SignInResult.ignored,
    );
    final error = '${second.browserUrl}&$fields';
    for (final fragment in [
      'sb=',
      '$mirror&code=x',
      '$mirror&access_token=x',
      '$mirror&sb=',
      mirror.replaceFirst('denied', 'other'),
      mirror.replaceFirst('sb=', 'sb=x'),
    ]) {
      expect(await auth.callback('$error#$fragment'), SignInResult.ignored);
    }
    expect(auth.pendingGeneration, second.generation);
    expect(await auth.callback('$error#$mirror'), SignInResult.reauthenticate);
    expect(await auth.callback(callback(second)), SignInResult.ignored);
    expect(provider.calls, 0);
  });

  for (final refresh in [false, true]) {
    test(
      'duplicate and late X ${refresh ? "refresh" : "exchange"} across two connections',
      () async {
        final attempt = await begin(x);
        if (refresh) {
          expect(
            await auth.callback(callback(attempt)),
            SignInResult.committed,
          );
        }
        final lease = auth.retainedSession;
        final started = provider.started = Completer<void>();
        final release = provider.release = Completer<void>();
        final pending = refresh
            ? auth.refresh(lease!)
            : auth.callback(callback(attempt));
        await started.future;
        final other = reopen();
        try {
          expect(other.retainedSession, isNull);
          expect(
            await (refresh
                ? other.refresh(lease!)
                : other.callback(callback(attempt))),
            SignInResult.ignored,
          );
          final next = (await other.begin(expectedOwner: y))!;
          provider.owner = y;
          expect(await other.callback(callback(next)), SignInResult.committed);
          release.complete();
          expect(await pending, SignInResult.ignored);
          expect(auth.signOut(attempt.generation), isFalse);
          expect(auth.retainedSession, (generation: next.generation, owner: y));
          expect(
            await other.refresh(other.retainedSession!),
            SignInResult.committed,
          );
        } finally {
          other.close();
        }
      },
    );
  }

  test(
    'late seal cannot recreate X after sign-out or replace a newer login',
    () async {
      final started = Completer<void>(), release = Completer<void>();
      vault.beforeSeal = (secret) async {
        if (secret == 'synthetic-refresh-$x') {
          started.complete();
          await release.future;
        }
      };
      final attempt = await begin(x);
      final pending = auth.callback(callback(attempt));
      await started.future;
      expect(auth.signOut(attempt.generation), isTrue);
      final other = await login(y);
      release.complete();
      expect(await pending, SignInResult.ignored);
      expect(auth.retainedSession, other);
    },
  );

  test(
    'unexpected account or backend on exchange and refresh fails closed',
    () async {
      provider.owner = y;
      expect(
        await auth.callback(callback(await begin(x))),
        SignInResult.reauthenticate,
      );
      expect(auth.retainedSession, isNull);
      provider.issuer = Uri.parse('https://other.invalid');
      expect(
        await auth.callback(callback(await begin())),
        SignInResult.reauthenticate,
      );
      provider.issuer = endpoint;
      final lease = await login(x);
      provider.issuer = Uri.parse('https://other.invalid');
      expect(await auth.refresh(lease), SignInResult.reauthenticate);
      expect(auth.retainedSession, isNull);
      provider.issuer = endpoint;
      final retry = await login(x);
      provider.returnedOwner = y;
      expect(await auth.refresh(retry), SignInResult.reauthenticate);
      expect(auth.retainedSession, isNull);
    },
  );

  test('secure storage failures during prepare, open and commit require fresh sign-in', () async {
    vault.locked = true;
    await expectLater(begin(), throwsStateError);
    expect(auth.pendingGeneration, isNull);
    vault.locked = false;
    final attempt = await begin();
    vault.locked = true;
    expect(
      await auth.callback(callback(attempt)),
      SignInResult.storageUnavailable,
    );
    expect(provider.calls, 0);
    vault.locked = false;
    final next = await begin();
    vault.beforeSeal = (_) async {
      vault.locked = true;
    };
    expect(
      await auth.callback(callback(next)),
      SignInResult.storageUnavailable,
    );
    expect(await auth.callback(callback(next)), SignInResult.ignored);
    auth.close();
    auth = reopen();
    expect(auth.retainedSession, isNull);
  });

  test(
    'SQLite error committing a session leaves no active owner on restart',
    () async {
      final attempt = await begin();
      final journal = sqlite3.open(
        File.fromUri(directory.uri.resolve('sign-in-v1.sqlite')).path,
      );
      try {
        journal.execute(
          "CREATE TRIGGER fail BEFORE UPDATE ON auth_slot WHEN NEW.phase='active' "
          "BEGIN SELECT RAISE(ABORT,'injected failure'); END",
        );
        expect(
          await auth.callback(callback(attempt)),
          SignInResult.storageUnavailable,
        );
      } finally {
        journal.close();
      }
      auth.close();
      auth = reopen();
      expect(auth.retainedSession, isNull);
      expect(await auth.callback(callback(attempt)), SignInResult.ignored);
    },
  );

  test(
    'default sign-out preserves exact pending task operation in owner database',
    () async {
      final lease = await login(x);
      final file = File.fromUri(directory.uri.resolve('owner-x.sqlite'));
      final db = AppDatabase.file(file);
      late String original;
      try {
        await db.initializeProfile('account-$x');
        final store = await AccountStore.open(db, x);
        final m = manifest(count: 0);
        await store.beginSnapshot(m, now);
        await store.stagePage(page(m, records: []), now);
        await store.installSnapshot(now);
        final op = await store.commitCommand(
          operationId: id(10),
          entity: task,
          command: 'task.create',
          patches: createFields(),
          occurredAtUtc: now,
        );
        original = op.payloadIdentity;
        expect(auth.signOut(lease.generation), isTrue);
        expect(auth.retainedSession, isNull);
      } finally {
        await db.close();
      }
      await login(y);
      await login(x);
      final reopened = AppDatabase.file(file);
      try {
        final store = await AccountStore.open(reopened, x);
        final projection = await store.projection(task);
        expect(projection.proposals.single.operation.payloadIdentity, original);
        expect(projection.proposals.single.transportState, 'pending');
      } finally {
        await reopened.close();
      }
    },
  );
}
