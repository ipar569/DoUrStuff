# Phase 1 verification — 3 October 2026

Status: foundation source implemented and Android compilation verified;
the complete platform acceptance gate remains open.

## Delivered

Flutter 3.47.6 / Dart 3.13.5 Android and Windows projects; a responsive dark
guest task list with capture, completion and reopening; real Drift/SQLite
persistence; atomic task/history/outbox/notification-dirty writes; immutable
profile metadata; schema v1 and retained-data fixtures; protocol and deterministic
occurrence identity contracts. No account/network is needed for this preview.

Repository deliverables include root README/AGENTS, seven accepted ADRs,
architecture/backlog, setup/recovery/backend/release/cost/two-device runbooks,
three validated project skills, public-only config example, issue/PR templates
and SHA-pinned quality/native/draft-release workflows.

The schema reserves later features. Full task editing, tags, milestones,
priorities, saved views, recurrence, calendar, notifications, account sync and
portable export/import are not implemented UI features. No placeholder provider
or deployment is reported as working.

## Checks actually run

Commands ran in D:\Projects\DoUrStuff with the ignored .tools/flutter SDK.
No commits, pushes, tags, releases, backend deployments or store operations ran.

| Command/check | Result |
| --- | --- |
| flutter --version | Flutter 3.47.6, Dart 3.13.5; framework 5fc346839b |
| flutter doctor -v | Windows C++ workload missing; original Android SDK/JDK outdated |
| flutter pub get --enforce-lockfile | Pass |
| dart run build_runner build | Pass; generated database SHA unchanged on repeat |
| dart format --output=none --set-exit-if-changed lib test tool | Pass, zero changes |
| flutter analyze | Pass, no issues |
| flutter test --reporter expanded | **17 passed** |
| dart run drift_dev schema dump lib/data/local/database.dart drift_schemas/drift_schema_v1.json | Pass; snapshot SHA unchanged on repeat |
| dart run drift_dev schema generate drift_schemas test/generated | Pass, two generated fixture files |
| flutter test tool/render_preview.dart --reporter expanded | **2 preview renders passed**, 1100×760 and 390×844; visually inspected |
| actionlint 1.7.12 | Pass, no workflow findings; hosted CI not run |
| skill-creator quick_validate.py on all three .agents/skills directories | All three pass |
| dart run tool/verify_release.dart v0.1.0 | Pass |
| dart run tool/verify_release.dart v9.9.9 | Expected failure, mismatched tag rejected |
| flutter build windows --release | Blocked: no suitable Visual Studio C++ toolchain |
| flutter build apk --debug --target-platform android-arm64 | Initial failure: Flutter selected Android Studio Java 11 |
| android/gradlew.bat -p android assembleDebug -Ptarget-platform=android-arm64 --no-daemon with JDK 21 | **Pass** |
| android/gradlew.bat -p android assembleRelease -Ptarget-platform=android-arm64 --no-daemon with JDK 21 | **Pass** |
| apksigner verify --print-certs app-debug.apk | Pass; Android Debug signing certificate |
| apksigner verify --print-certs app-release.apk | Expected failure: unsigned release, no debug-key substitution |
| adb devices | No connected Android devices |
| git diff --check | Pass for tracked changes; initial line-ending warnings addressed by .gitattributes |

The 17 tests cover three domain/wire identity cases, nine SQLite repository/
durability cases, two schema cases and three widget cases. They exercise civil
date validation, protocol fixture, independently generated UUIDv5 fixture,
fresh storage/reopen/preferences, injected outbox rollback, completion
idempotency/reopen history, concurrent sequence allocation, wrong-profile
rejection, account-command fail-closed behavior, invalid title/foreign key,
newer-schema preservation, WAL-consistent backup, schema equality/snapshot
reopening, real-SQLite capture/complete/reopen UI, 200% text at 390px, and failed
save draft retention. These are host tests, not installed-device acceptance.

Early checks found two unquoted SQL keywords, lint/deprecation issues, a widget
test cleanup timer and a large-text layout overflow. They were corrected before
the final passing suite. The pinned Drift CLI required an explicit snapshot
filename. Gradle reports deprecated upstream features that need review before
a future Gradle 10 upgrade; the pinned Gradle 9.3.1 builds succeeded.

## Build artifacts

Ignored local build outputs, not published releases:

| Artifact | Bytes | SHA256 |
| --- | --- | --- |
| build/app/outputs/flutter-apk/app-debug.apk | 83147192 | dc1b57e51d4bfd6255fc948e6b20b0107ff4494bd400e07c48782e20fde72f55 |
| build/app/outputs/flutter-apk/app-release.apk | 20185731 | 82a955245a3df10e7ff8b611908f020a7ff5be430e0a20f3c4b7406884d05790 |

Debug APK is a development build. Release APK is unsigned and needs signing
before installation. Windows binaries/MSIX were not produced. Actual Flutter
widget renders with synthetic data are in docs/screenshots; they are not native
Android/Windows screenshots.

Build configuration: min Android API 24, compile/target 36, NDK 28.2.13676358,
Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0. These values do not establish minimum-OS
runtime support.

## Environment changes and remaining gates

Flutter stable was cloned under ignored .tools. A Microsoft OpenJDK 21.0.12.1
ZIP and actionlint 1.7.12 were downloaded from their official sources and checked
against published SHA256 files. PyYAML 6.0.3 was installed only under
.tools/python to run the skill validator. No global PATH/Java setting changed.
Android SDK platform/build-tools 36 were added using existing SDK licenses;
the build installed NDK/CMake dependencies under that SDK. Visual Studio was
not modified. The old Java 11 selected by Flutter remains a setup issue for
ordinary flutter build/run until a developer selects JDK 21.

Remaining: Windows C++ installation and compile/launch; Android installed launch,
process-kill persistence and physical-device checks; secure-storage and local
notification feasibility spikes; actual hosted workflow runs. Notification
permissions, closed-app/reboot/Doze/OEM reliability, accessibility screen readers,
physical keyboard/focus and native upgrade behavior remain unverified.

No Supabase integration/RLS/auth/two-device latency was tested. iOS/macOS/Linux
are planned only. Schema v1 fixture reopening is not a v1→v2 upgrade. No disk-full,
hard power-loss or interrupted real migration test ran. Unit UUID identity tests
are not simultaneous two-device recurrence tests.

## Product acceptance ledger

Each numbered row corresponds to the original request. No full device acceptance
criterion is marked complete by the foundation tests alone.

| # | Criterion | Current evidence / remaining work |
| --- | --- | --- |
| 1 | Fresh offline task use | Host SQLite/widget capture, complete/reopen pass; installed-device test pending |
| 2 | Survive restart | File close/reopen and settings pass; native process restart pending |
| 3 | Filters, priority, milestones, saved views, calendar offline | Not implemented; phases 2/4 |
| 4 | Offline reminders update on edits | Not implemented; phase 4 |
| 5 | Snooze preserves due date | Not implemented; phase 4 |
| 6 | Guest data survives sync enablement | Design only; phase 3 |
| 7 | Two-device automatic appearance | Not implemented/tested; phase 3 |
| 8 | Completion/milestone propagation | Local completion tested; transport absent |
| 9 | Offline conflict reconciliation | Protocol documented; server/resolution absent |
| 10 | Offline delete cannot resurrect | Tombstone schema/design only |
| 11 | Interrupted sync idempotency | Local atomic rollback/sequence tests pass; transport not implemented |
| 12 | Simultaneous recurrence deduplication | UUID identity fixture passes; two-device generation absent |
| 13 | Recurrence history/future slots | Ordinary task history tested; recurrence engine absent |
| 14 | Snooze/priority/views sync | Not implemented; phases 3/4 |
| 15 | New device preserves existing tasks | Bootstrap design only |
| 16 | Interrupted download/expired session recovery | Design only |
| 17 | Sign-out/account isolation | Wrong-file guard passes; account lifecycle absent |
| 18 | Timezone/month-end/DST | Civil-day validation only; scheduling engine absent |
| 19 | Export/import/migrations preserve data | Fresh/v1 reopen/backup/downgrade pass; upgrades and portability pending |
| 20 | Core during backend outage | Current guest app uses no network; authenticated outage path absent |
| 21 | Server ownership controls | Not implemented/tested; phase 3 RLS gate |

Next product phase is the complete offline editor/query/saved-view experience.
Keep the native verification gates visible while progressing that independent
work; do not begin recurrence/reminders before phase 3 two-device verification.

## Hosted baseline evidence inspected during Phase 2

On 3 October 2026, `gh run list --limit 6` and `gh run view` confirmed both
runs at commit `86f7eed69cf0f0de966a706ede7499e5745ea210` succeeded:
[Quality 37097428010](https://github.com/ipar569/DoUrStuff/actions/runs/37097428010)
and [Native builds 37097428015](https://github.com/ipar569/DoUrStuff/actions/runs/37097428015).
The native run contains successful Android debug and Windows release compile
jobs. This closes the previously unverified hosted-run gate for that baseline,
including hosted Windows compilation. It does not establish installed launch,
notification/secure-storage feasibility, or validation of the unpushed Phase 2
changes. Earlier local build/toolchain observations above remain historical.
