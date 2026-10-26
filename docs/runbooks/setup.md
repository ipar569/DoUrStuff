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
This machine's missing C++ workload was installed on 5 October 2026; the local
Windows release build and unpackaged launch passed. See the Phase 2 report for
the installation details and later verification.
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

No environment file, backend, account or Docker is needed for the Phase 2 offline app. The
config/sync.example.json file describes future public configuration and is not
consumed yet. Release APKs are unsigned; there is no debug-key release fallback.

The 10 October readiness check found no connected Android device. On 12 October,
Android 11 x86_64 emulator acceptance passed and the user accepted it for local
Phase 3 entry. Physical-device acceptance remains open. To exercise it, enable USB
debugging and authorize this computer, then verify `adb devices -l` shows it as
`device`. Use the [Phase 2 checklist](../verification/phase-2.md) to record model,
OS, APK SHA256, offline first launch/edit and force-stop/reopen persistence of
tasks and the startup view. Use a fresh test device or isolated Android user;
do not clear an existing personal profile. Application ID is
`app.dourstuff.dourstuff`; after saves, stop it for the test with
`adb -s DEVICE_ID shell am force-stop app.dourstuff.dourstuff`, then reopen from
its launcher. Record actual outcomes; host tests and compilation cannot
substitute for them.

The original 32-bit x86 AVD was unsupported by pinned Flutter. A separate
`DoUrStuff_API_30_x64` AVD used `system-images;android-30;google_apis;x86_64`;
build its debug APK with `android/gradlew.bat -p android assembleDebug
-Ptarget-platform=android-x64 --no-daemon` and the session JDK 21 override below.
Wait for `adb -s DEVICE_ID shell getprop sys.boot_completed` to return 1 before
installing. The [Phase 2 report](../verification/phase-2.md) records the exact
tested image/APK/hash, offline actions and retained screenshot. Preserve this
synthetic profile when resuming; a fresh install must use an isolated profile.

Backend readiness is separately recorded in [backend setup](backend.md): Docker's
Linux daemon responded on 12 October; after initial policy blocks, CLI 2.120.0
installation/checksum/version/help checks passed through interactive approval
on 13 October. `.supabase-version` pins the CLI; the optional ignored executable
is `.tools/supabase/supabase.exe`. Local configuration is now initialized under
`supabase/`, with automatic API exposure disabled. Before starting services,
update this host's Docker Engine 23.0.5 to 28+ for the project's loopback isolation
requirement; see [backend setup](backend.md) and its official-source rationale.
That historical engine prerequisite passed later on 16 October: Engine 29.8.2
and the local stack are verified. The default network binding did not restrict
ports on this Windows host; explicit localhost bindings were applied while
preserving data. Use `python tool/local_backend.py --start` for the existing
stack and follow `supabase/README.md`; plain CLI recreation loses that repair.
Registration/pull/RLS integration passes. The 17 October apply increment also
passes real local command checks for existing-task title/priority edits; full
command coverage, native auth and client integration remain pending.

18 October: forward migration 004 and `tool/test_backend_task_create.py` add
real HTTP core task creation and atomic status/completion checks. Continue using
the existing guarded stack restart; preserve the stopped backup containers and
volumes. No native auth configuration or device endpoint was added.

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

25 October: forward migration 016 and the synthetic membership harness extend
the existing local apply RPC with exact task/tag pairs and independent add/remove
bases. Use the twelve sequential backend suites in `supabase/README.md`. Existing
stack startup remains `python tool/local_backend.py --start`; do not recreate
containers, reset databases or rewrite applied migrations. Native account writes
are disabled. Secure sessions/PKCE, exact Android/Windows OAuth redirects and a
restricted development endpoint reachable by both installed clients remain
unverified prerequisites. Local HTTP and build results do not close those gates.

26 October: migrations 017–018 add saved views/default preferences and a forward
empty-name validation correction. All eighteen migration IDs must remain in
history. Use the thirteen sequential suites and saved-view wire checker documented
in `supabase/README.md`. The pinned SDK/CLI and SQLite v1 are unchanged. Account
writes, native auth/secure storage, endpoint/device and representation gates
remain open; no production deployment or release is authorized by local setup.
