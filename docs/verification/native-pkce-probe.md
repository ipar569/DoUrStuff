# Reproduce the native auth feasibility probe

Use Flutter 3.47.6 in a new scratch directory outside the application package.
The Windows test uses synthetic session values and a fresh directory beneath
the scratch project for its encrypted file. It needs the same Windows user for
both invocations. The GitHub authorization URL is generated locally.

Save this as `pubspec.yaml` in the scratch directory.

```yaml
name: native_pkce_feasibility
publish_to: none
environment:
  sdk: ^3.13.5
dependencies:
  flutter:
    sdk: flutter
  app_links: 7.2.2
  crypto: 3.0.8
  flutter_secure_storage: 11.2.0
  flutter_secure_storage_windows: 4.2.2
  gotrue: 2.27.3
  path_provider_platform_interface: 2.1.2
  supabase_flutter: 2.18.3
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  uses-material-design: false
```

Run `flutter pub get`. Keep the scratch lockfile for a rerun with
`flutter pub get --enforce-lockfile`. From the published `supabase_flutter-2.18.3/test`
directory in the pub cache, copy `deep_link_test.dart`, `storage_test.dart`,
`utils.dart` and `widget_test_stubs.dart` into the scratch project's `test`
directory. Run the two upstream suites with mock link delivery, HTTP and
preferences.

```shell
flutter test --no-pub --concurrency=1 --reporter expanded test/deep_link_test.dart test/storage_test.dart
```

Save the following as `test/windows_storage_test.dart`. The only substituted
platform service is the support-directory path. The Windows plugin performs
its normal file reads and writes through current-user DPAPI.

```dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_windows/flutter_secure_storage_windows.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gotrue/gotrue.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class ScratchPath extends PathProviderPlatform {
  final directory = Directory('probe-vault-windows').absolute;

  @override
  Future<String?> getApplicationSupportPath() async => directory.path;
}

const vault = FlutterSecureStorage();

class AttemptStorage extends GotrueAsyncStorage {
  @override
  Future<String?> getItem({required String key}) =>
      vault.read(key: 'probe/attempt/1/$key');

  @override
  Future<void> setItem({required String key, required String value}) =>
      vault.write(key: 'probe/attempt/1/$key', value: value);

  @override
  Future<void> removeItem({required String key}) =>
      vault.delete(key: 'probe/attempt/1/$key');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isWindows) throw UnsupportedError('Windows host required');
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.windows);
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  final scratch = ScratchPath();
  PathProviderPlatform.instance = scratch;
  FlutterSecureStorageWindows.registerWith();
  final challengeFile = File('probe-public-challenge');
  const x = 'probe/session/x', y = 'probe/session/y';
  const verifierKey = 'supabase.auth.token-code-verifier';
  final attempt = AttemptStorage();

  test('write', () async {
    expect(await scratch.directory.exists(), isFalse);
    expect(await challengeFile.exists(), isFalse);
    await scratch.directory.create();
    final auth = GoTrueClient(url: 'https://probe.invalid/auth/v1',
        autoRefreshToken: false, asyncStorage: attempt);
    addTearDown(auth.dispose);
    final result = await auth.getOAuthSignInUrl(provider: OAuthProvider.github,
        redirectTo: 'app.dourstuff.probe://auth/callback');
    final params = Uri.parse(result.url).queryParameters;
    expect(params['code_challenge_method'], 's256');
    await challengeFile.writeAsString(params['code_challenge']!);
    await vault.write(key: x, value: 'synthetic-x');
    await vault.write(key: y, value: 'synthetic-y');
  });

  test('reopen', () async {
    final verifier = (await attempt.getItem(key: verifierKey))!;
    final digest = sha256.convert(ascii.encode(verifier));
    final challenge = base64Url.encode(digest.bytes).replaceAll('=', '');
    expect(challenge == await challengeFile.readAsString(), isTrue);
    expect(await vault.read(key: x) == 'synthetic-x', isTrue);
    await attempt.removeItem(key: verifierKey);
    await vault.delete(key: x);
    expect(await attempt.getItem(key: verifierKey) == null, isTrue);
    expect(await vault.read(key: x) == null, isTrue);
    expect(await vault.read(key: y) == 'synthetic-y', isTrue);
    await vault.delete(key: y);
  });
}
```

Run each test in its own process, in order, from the same scratch directory.

```shell
flutter test --no-pub --plain-name write test/windows_storage_test.dart
flutter test --no-pub --plain-name reopen test/windows_storage_test.dart
```

### Compile the native candidates

For the compilation check, copy the tracked `android/` or `windows/` runner
from the baseline commit into the scratch package, including its build files.
Create `lib/main.dart` containing `void main() {}`. Run
`flutter pub get --enforce-lockfile` **after** adding the runner. Inspect its
generated plugin registrant for both `app_links` and `flutter_secure_storage`.
A bare shell can compile without either registration.

Use Java 21 for Android. On this Windows host the Kotlin incremental caches
failed to close with plugin sources on C: and the runner on D:. The retry
added `kotlin.incremental=false` only to the scratch `android/gradle.properties`.
The candidate Windows C++ plugin requires the ATL headers for the selected
MSVC toolset. The host DPAPI test above runs independently of that build.

```shell
flutter build apk --debug --no-pub --target-platform android-arm64
flutter build windows --release --no-pub
```
