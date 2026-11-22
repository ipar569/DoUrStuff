import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import '../../domain/account_sync.dart' show isAccountUuid;
import '../../domain/ports.dart' show Clock, SystemClock;
import '../../domain/sign_in.dart';

enum SignInResult { committed, ignored, reauthenticate, storageUnavailable }

typedef SignInLaunch = ({String generation, Uri browserUrl});
typedef SignedInOwner = ({String generation, String owner});

/// Dormant prototype. The guest entry point never opens this journal.
/// One private file for the installation, shared by every callback receiver.
/// No profile DB handles, SDK listeners or network calls in local transactions.
final class SignInCoordinator {
  SignInCoordinator._(
    this._db,
    this._provider,
    this._vault,
    this._redirect,
    this._backend,
    this._clock,
  );

  final Database _db;
  final SignInProvider _provider;
  final CredentialProtection _vault;
  final Uri _redirect;
  final Uri _backend;
  final Clock _clock;
  bool _closed = false;
  static const _lifetime = Duration(minutes: 10);

  static SignInCoordinator open(
    Directory installation,
    SignInProvider provider,
    CredentialProtection vault,
    Uri redirect, {
    Clock clock = const SystemClock(),
  }) {
    final backend = provider.backend;
    if (!redirect.hasScheme ||
        !redirect.hasAuthority ||
        redirect.host.isEmpty ||
        redirect.authority.contains('@') ||
        redirect.hasQuery ||
        redirect.hasFragment ||
        redirect.path.isEmpty) {
      throw ArgumentError('Expected an exact callback endpoint.');
    }
    final db = sqlite3.open(
      File.fromUri(installation.absolute.uri.resolve('sign-in-v1.sqlite')).path,
    );
    try {
      db.execute('PRAGMA busy_timeout = 5000');
      db.execute('PRAGMA synchronous = FULL');
      db.execute('PRAGMA secure_delete = ON');
      db.execute('BEGIN IMMEDIATE');
      db.execute('''CREATE TABLE IF NOT EXISTS auth_slot (
        singleton INTEGER PRIMARY KEY CHECK(singleton=1),
        backend TEXT NOT NULL, redirect TEXT NOT NULL,
        phase TEXT NOT NULL CHECK(phase IN
          ('guest','preparing','pending','exchanging','active','refreshing')),
        generation TEXT, owner TEXT, expires INTEGER, secret BLOB
      )''');
      db.execute(
        "INSERT INTO auth_slot(singleton,backend,redirect,phase) "
        "VALUES(1,?,?,'guest') ON CONFLICT(singleton) DO NOTHING",
        [backend.toString(), redirect.toString()],
      );
      final row = db.select('SELECT backend,redirect FROM auth_slot').single;
      if (row['backend'] != backend.toString() ||
          row['redirect'] != redirect.toString()) {
        throw StateError(
          'Sign-in configuration differs from retained journal.',
        );
      }
      db.execute('COMMIT');
      final coordinator = SignInCoordinator._(
        db,
        provider,
        vault,
        redirect,
        backend,
        clock,
      );
      coordinator._expire();
      return coordinator;
    } catch (_) {
      db.close();
      rethrow;
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _db.close();
  }

  int get _now => _clock.nowUtc().millisecondsSinceEpoch;
  static const _clear =
      "UPDATE auth_slot SET phase='guest',generation=NULL,"
      "owner=NULL,expires=NULL,secret=NULL ";

  void _expire() => _db.execute('$_clear WHERE expires <= ?', [_now]);

  String _context(String kind, String generation, String? owner) => jsonEncode([
    _backend.toString(),
    _redirect.toString(),
    kind,
    generation,
    owner,
  ]);

  bool _current(String generation, String phase) {
    if (_closed) return false;
    _expire();
    return _db.select(
      'SELECT 1 FROM auth_slot WHERE generation=? AND phase=?',
      [generation, phase],
    ).isNotEmpty;
  }

  /// Persisted lease metadata for refresh/sign-out. A cold start must first
  /// refresh successfully before using this identity to reopen an account DB.
  SignedInOwner? get retainedSession {
    final rows = _db.select(
      "SELECT generation,owner FROM auth_slot "
      "WHERE phase='active'",
    );
    if (rows.isEmpty) return null;
    return (
      generation: rows.single['generation'] as String,
      owner: rows.single['owner'] as String,
    );
  }

  String? get pendingGeneration {
    _expire();
    return _db
            .select(
              "SELECT generation FROM auth_slot "
              "WHERE phase IN ('preparing','pending','exchanging')",
            )
            .firstOrNull?['generation']
        as String?;
  }

  /// An explicit new sign-in signs out the previous generation immediately.
  /// The browser URL is released only after its verifier commits.
  Future<SignInLaunch?> begin({String? expectedOwner}) async {
    if (expectedOwner != null && !isAccountUuid(expectedOwner)) {
      throw ArgumentError('Invalid expected account.');
    }
    final generation = const Uuid().v4();
    _db.execute(
      "UPDATE auth_slot SET generation=?,owner=?,phase='preparing',"
      "expires=?,secret=NULL",
      [generation, expectedOwner, _now + _lifetime.inMilliseconds],
    );
    final target = _redirect.replace(queryParameters: {'attempt': generation});
    try {
      final prepared = await _provider.prepareGithub(target);
      if (!_current(generation, 'preparing')) return null;
      if (prepared.verifier.isEmpty) throw StateError('Missing verifier.');
      final sealed = await _vault.seal(
        _context('verifier', generation, expectedOwner),
        prepared.verifier,
      );
      if (_closed) return null;
      _db.execute(
        "UPDATE auth_slot SET phase='pending',secret=? "
        "WHERE generation=? AND phase='preparing' AND expires>?",
        [sealed, generation, _now],
      );
      if (_db.updatedRows == 0) {
        _expire();
        return null;
      }
      return (generation: generation, browserUrl: prepared.browserUrl);
    } catch (_) {
      if (_closed) return null;
      cancel(generation);
      throw StateError('Could not prepare secure sign-in.');
    }
  }

  bool cancel(String generation) {
    _db.execute(
      "$_clear WHERE generation=? AND phase IN ('preparing','pending','exchanging')",
      [generation],
    );
    return _db.updatedRows == 1;
  }

  /// Invalidates only the caller's generation. No account task data is owned
  /// by the coordinator, including on a failed or repeated sign-out.
  bool signOut(String generation) {
    _db.execute('$_clear WHERE generation=?', [generation]);
    return _db.updatedRows == 1;
  }

  /// Compare the original endpoint spelling before Dart URI normalization.
  /// The round-tripped attempt parameter correlates old successes AND errors.
  Future<SignInResult> callback(String raw) async {
    _expire();
    final query = raw.indexOf('?');
    if (raw.length > 8192 ||
        query < 0 ||
        raw.substring(0, query) != _redirect.toString() ||
        raw.contains('#')) {
      return SignInResult.ignored;
    }
    final values = <String, String>{};
    try {
      for (final part in raw.substring(query + 1).split('&')) {
        final split = part.indexOf('=');
        if (split < 1) return SignInResult.ignored;
        final key = Uri.decodeQueryComponent(part.substring(0, split));
        final value = Uri.decodeQueryComponent(part.substring(split + 1));
        if (values.containsKey(key) || value.trim().isEmpty) {
          return SignInResult.ignored;
        }
        values[key] = value;
      }
    } on ArgumentError {
      return SignInResult.ignored;
    } on FormatException {
      return SignInResult.ignored;
    }
    final generation = values['attempt'];
    if (generation == null || !isAccountUuid(generation)) {
      return SignInResult.ignored;
    }
    if (values.containsKey('error') &&
        values.keys.every(
          const {
            'attempt',
            'error',
            'error_description',
            'error_code',
          }.contains,
        )) {
      _db.execute("$_clear WHERE generation=? AND phase='pending'", [
        generation,
      ]);
      return _db.updatedRows == 1
          ? SignInResult.reauthenticate
          : SignInResult.ignored;
    }
    final code = values['code'];
    if (values.length != 2 || code == null) return SignInResult.ignored;
    return _redeem(generation, code);
  }

  Future<SignInResult> refresh(SignedInOwner lease) =>
      _redeem(lease.generation, null, refreshOwner: lease.owner);

  Future<SignInResult> _redeem(
    String generation,
    String? code, {
    String? refreshOwner,
  }) async {
    final exchange = code != null;
    final from = exchange ? 'pending' : 'active';
    final claimed = exchange ? 'exchanging' : 'refreshing';
    // BEGIN IMMEDIATE gives all connections one claim order. Destroy the
    // persisted input at claim time: a crashed exchange/rotation cannot replay.
    _db.execute('BEGIN IMMEDIATE');
    late final Row row;
    try {
      _expire();
      final rows = _db.select(
        'SELECT owner,secret FROM auth_slot WHERE generation=? AND phase=?',
        [generation, from],
      );
      if (rows.isEmpty || (!exchange && rows.single['owner'] != refreshOwner)) {
        _db.execute('COMMIT');
        return SignInResult.ignored;
      }
      row = rows.single;
      _db.execute('UPDATE auth_slot SET phase=?,secret=NULL', [claimed]);
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    final owner = row['owner'] as String?;
    var failure = SignInResult.storageUnavailable;
    try {
      final secret = await _vault.open(
        _context(exchange ? 'verifier' : 'session', generation, owner),
        row['secret'] as Uint8List,
      );
      if (!_current(generation, claimed)) return SignInResult.ignored;
      failure = SignInResult.reauthenticate;
      final session = exchange
          ? await _provider.exchange(code, secret)
          : await _provider.refresh(secret);
      if (!_current(generation, claimed)) return SignInResult.ignored;
      if (session.backend != _backend ||
          !isAccountUuid(session.owner) ||
          (owner != null && session.owner != owner) ||
          session.refreshToken.isEmpty) {
        throw StateError('Invalid authenticated session.');
      }
      failure = SignInResult.storageUnavailable;
      final sealed = await _vault.seal(
        _context('session', generation, session.owner),
        session.refreshToken,
      );
      if (_closed) return SignInResult.ignored;
      _db.execute(
        "UPDATE auth_slot SET phase='active',owner=?,secret=?,expires=NULL "
        "WHERE generation=? AND phase=? AND (expires IS NULL OR expires>?)",
        [session.owner, sealed, generation, claimed, _now],
      );
      if (_db.updatedRows == 1) return SignInResult.committed;
      _expire();
      return SignInResult.ignored;
    } catch (_) {
      if (_closed) return SignInResult.ignored;
      _db.execute('$_clear WHERE generation=? AND phase=?', [
        generation,
        claimed,
      ]);
      return _db.updatedRows == 1 ? failure : SignInResult.ignored;
    }
  }
}
