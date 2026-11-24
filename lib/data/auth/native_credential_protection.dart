import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../../domain/sign_in.dart';

/// The journal owns the ciphertext. Neither platform stores a second copy.
final class NativeCredentialProtection implements CredentialProtection {
  const NativeCredentialProtection();

  static const _channel = MethodChannel('app.dourstuff/credential-record/v1');

  Future<Uint8List> _transform(
    String method,
    String context,
    Uint8List data,
  ) async {
    final result = await _channel.invokeMethod<Uint8List>(method, {
      'context': utf8.encode(
        'app.dourstuff/credential-record/v1\u0000$context',
      ),
      'data': data,
    });
    if (result == null || result.isEmpty) {
      throw StateError('Credential protection unavailable.');
    }
    return result;
  }

  @override
  Future<Uint8List> seal(String context, String secret) async {
    if (secret.isEmpty) throw ArgumentError('Expected a credential.');
    final plain = utf8.encode(secret);
    if (!Platform.isWindows) return _transform('seal', context, plain);
    // DPAPI can accept some modifications to its blob. Authenticate its
    // entire output with an independent random key inside the protected data.
    final random = Random.secure();
    final key = List.generate(32, (_) => random.nextInt(256));
    final blob = await _transform(
      'seal',
      context,
      Uint8List.fromList([...key, ...plain]),
    );
    return Uint8List.fromList([
      ...Hmac(sha256, key).convert(blob).bytes,
      ...blob,
    ]);
  }

  @override
  Future<String> open(String context, Uint8List ciphertext) async {
    if (!Platform.isWindows) {
      return utf8.decode(await _transform('open', context, ciphertext));
    }
    if (ciphertext.length <= 32) throw StateError('Invalid credential record.');
    final blob = Uint8List.sublistView(ciphertext, 32);
    final plain = await _transform('open', context, blob);
    if (plain.length <= 32) throw StateError('Invalid credential record.');
    final key = Uint8List.sublistView(plain, 0, 32);
    final mac = Hmac(sha256, key).convert(blob).bytes;
    var different = 0;
    for (var i = 0; i < mac.length; i++) {
      different |= mac[i] ^ ciphertext[i];
    }
    if (different != 0) throw StateError('Invalid credential record.');
    return utf8.decode(Uint8List.sublistView(plain, 32));
  }
}
