import 'dart:typed_data';

/// The SDK adapter must use an isolated, memory-only client for each call.
/// Only the exchange/refresh result is authoritative. SDK events cannot write
/// credentials, select a profile or start a worker.
abstract interface class SignInProvider {
  Uri get backend;
  Future<PreparedSignIn> prepareGithub(Uri redirect);
  Future<VerifiedSession> exchange(String code, String verifier);
  Future<VerifiedSession> refresh(String refreshToken);
}

final class PreparedSignIn {
  const PreparedSignIn(this.browserUrl, this.verifier);
  final Uri browserUrl;
  final String verifier;
}

/// Constructed from the configured Auth server's response. Deliberately has
/// no fields for the GitHub access token or other provider credentials.
final class VerifiedSession {
  const VerifiedSession(this.backend, this.owner, this.refreshToken);
  final Uri backend;
  final String owner;
  final String refreshToken;
}

/// Native implementation must authenticate [context] along with each record,
/// resist key extraction, and fail closed on lock, tampering or key loss.
/// Encryption has no persistence side effects. The journal decides which
/// encrypted record commits after the asynchronous operation returns.
abstract interface class CredentialProtection {
  Future<Uint8List> seal(String context, String secret);
  Future<String> open(String context, Uint8List ciphertext);
}
