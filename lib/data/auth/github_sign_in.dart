import 'dart:isolate';

import 'package:gotrue/gotrue.dart';

import '../../domain/sign_in.dart';

/// The dormant native adapter has no link observer, session storage, SDK
/// event subscription or automatic refresh. Each call owns its verifier.
final class GithubSignIn implements SignInProvider {
  GithubSignIn(this.backend, this._publishableKey) {
    if ((backend.scheme != 'https' &&
            !(backend.scheme == 'http' && backend.host == '127.0.0.1')) ||
        backend.host.isEmpty ||
        backend.authority.contains('@') ||
        backend.hasQuery ||
        backend.hasFragment ||
        (backend.path.isNotEmpty && backend.path != '/')) {
      throw ArgumentError('Expected a trusted Supabase origin.');
    }
  }

  @override
  final Uri backend;
  final String _publishableKey;

  Future<T> _withClient<T>(
    _Verifier memory,
    Future<T> Function(GoTrueClient) operation,
  ) => Isolate.run(() async {
    // GoTrue can emit complete sessions at FINEST. Its private isolate has
    // neither the application's logging configuration nor any log listeners.
    final auth = GoTrueClient(
      url: backend.resolve('/auth/v1').toString(),
      headers: {'apikey': _publishableKey},
      autoRefreshToken: false,
      asyncStorage: memory,
    );
    try {
      return await operation(auth);
    } catch (_) {
      throw StateError('GitHub authentication request failed.');
    } finally {
      auth.dispose();
    }
  });

  @override
  Future<PreparedSignIn> prepareGithub(Uri redirect) {
    final memory = _Verifier();
    return _withClient(memory, (auth) async {
      final result = await auth.getOAuthSignInUrl(
        provider: OAuthProvider.github,
        redirectTo: redirect.toString(),
      );
      return PreparedSignIn(Uri.parse(result.url), memory.value!);
    });
  }

  VerifiedSession _session(Session session) =>
      VerifiedSession(backend, session.user.id, session.refreshToken ?? '');

  @override
  Future<VerifiedSession> exchange(String code, String verifier) => _withClient(
    _Verifier(verifier),
    (auth) async => _session((await auth.exchangeCodeForSession(code)).session),
  );

  @override
  Future<VerifiedSession> refresh(String refreshToken) => _withClient(
    _Verifier(),
    (auth) async =>
        _session((await auth.refreshSession(refreshToken)).session!),
  );
}

final class _Verifier extends GotrueAsyncStorage {
  _Verifier([this.value]);
  String? value;
  @override
  Future<String?> getItem({required String key}) async => value;
  @override
  Future<void> setItem({required String key, required String value}) async {
    this.value = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    value = null;
  }
}
