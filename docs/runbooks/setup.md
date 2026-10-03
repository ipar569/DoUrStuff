# Setup and local development

Pin Flutter 3.47.6 / Dart 3.13.5, framework commit 5fc346839b. Dependencies and
transitive versions are locked in pubspec.lock. The ignored .tools/flutter SDK
is available in this checkout only; use its bin or install the pinned version
from [Flutter](https://docs.flutter.dev/install/manual).

Android needs current SDK/platform-tools, JDK 21 and the generated Gradle/AGP
requirements. This project pins Gradle 9.3.1, AGP 9.1.0 and Kotlin 2.4.0.
Compile/target/min SDK and NDK initially follow the pinned Flutter constants.
For this pin: compile/target 36, minimum 24, NDK 28.2.13676358. These are build
configuration values, not claims of physical-device coverage.
Record tested OS minimums after device runs. SDK license acceptance belongs
to the developer. [Android setup](https://docs.flutter.dev/platform-integration/android/setup)

Windows needs a Windows host, Visual Studio Desktop development with C++,
MSVC/CMake and a Windows SDK. Build Tools without C++ components is insufficient.
This machine has that gap; the Visual Studio installer was not modified.
[Windows setup](https://docs.flutter.dev/platform-integration/windows/setup)

Run from the repository root:

```sh
flutter doctor -v
flutter pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test --reporter expanded
flutter devices
flutter run -d windows
flutter run -d DEVICE_ID
flutter build apk --debug --target-platform android-arm64
flutter build apk --release --target-platform android-arm64
flutter build windows --release
```

No environment file, backend, account or Docker is needed for phase 1. The
config/sync.example.json file describes future public configuration and is not
consumed yet. Release APKs are unsigned; there is no debug-key release fallback.

Schema tooling uses an explicit filename because this Drift CLI cannot infer
the schema version from the top-level constant:

```sh
dart run drift_dev schema dump lib/data/local/database.dart drift_schemas/drift_schema_v1.json
dart run drift_dev schema generate drift_schemas test/generated
```

Retain old snapshots and generated fixture helpers when adding actual upgrades.
Generated Dart is committed. A code-generation change must not silently rewrite
old schema history.

Flutter may prefer Android Studio's bundled JDK over JAVA_HOME. To change that
preference intentionally, use flutter config --jdk-dir=ABSOLUTE_JDK_PATH. For a
project-only build, run android/gradlew with session JAVA_HOME set to JDK 21.
No local SDK/JDK paths belong in Git. Official JDK downloads and hashes are at
[Microsoft](https://learn.microsoft.com/en-us/java/openjdk/download).
