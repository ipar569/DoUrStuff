# Phase 2 verification — 3 October 2026

Status: offline application source implemented; host quality checks and Android
debug compilation pass. Installed-device acceptance remains open.

## Starting state and scope

Repository: D:\Projects\DoUrStuff. Initial branch `main`, clean working tree,
HEAD `86f7eed69cf0f0de966a706ede7499e5745ea210`. Read AGENTS, the full Phase 2
prompt, README, backlog, architecture/ADRs and Phase 1 evidence before editing.
Applied the sync-protocol workflow to commands; retained the account guard.
Schema remains v1 with no structural change, migration or snapshot replacement.
No old web code was restored.

Before edits, `gh run list --limit 6` and `gh run view` with
`--json conclusion,headSha,jobs,url` confirmed:

- [Quality 37097428010](https://github.com/ipar569/DoUrStuff/actions/runs/37097428010): success.
- [Native builds 37097428015](https://github.com/ipar569/DoUrStuff/actions/runs/37097428015): Android debug and Windows release jobs succeeded.

Those runs validate the committed Phase 1 baseline only. Phase 2 changes remain
local/uncommitted/unpushed. No hosted run validates them yet. No push, deployment,
release, store operation, account setup or publication was performed.

## Delivered

Full task viewing/editing, all statuses/priorities, description, civil and timed
due values, effort estimates and provenance timestamps; reusable tags with
rename/delete and independent membership; ordered milestones with independent
completion; guarded saves, soft deletion, status undo and deletion undo with a
tombstone precondition; destructive bulk confirmation.

Token search, combined status/tag/priority/date/undated/overdue filters, any/all
tags, status/due-day/tag/priority groups and due/priority/created/title/effort
sorts; Today, Upcoming, Overdue and All Tasks; versioned saved views with
create/update/delete/select and a shared default persisted across restarts.
Malformed views remain recoverable without blocking tasks. Dark responsive
sidebar/drawer/editor, priority labels/icons, keyboard shortcuts, 200% text,
local-save feedback and failed-save draft retention are implemented.

Every domain mutation remains atomic with journal, sequence, history and
notification-dirty intent. Account writes still fail atomically. See the
[offline behavior and command contract](../architecture/phase-2-offline.md)
for semantics, limitations and the expanded guest command vocabulary.

## Exact checks and results

Commands ran from the repository root in PowerShell. `flutter` below resolves to
`.tools/flutter/bin/flutter.bat`; `dart` to `.tools/flutter/bin/dart.bat`.
That ignored SDK location remains optional on other machines.

| Command/check | Actual result |
| --- | --- |
| `flutter --version` | Flutter 3.47.6, Dart 3.13.5; framework 5fc346839b |
| `flutter pub get` | Pass; pinned timezone 0.11.1 and transitive http 1.6.0 added to lockfile |
| `flutter pub get --enforce-lockfile` | Pass |
| `dart run build_runner build` | Pass, 93 seconds; committed database.g.dart unchanged |
| `dart format --output=none --set-exit-if-changed lib test tool` | Pass, zero changes |
| `flutter analyze` | Pass, no issues |
| `flutter test test/local_database_test.dart test/domain_test.dart test/schema_test.dart --reporter expanded` | 14 passed |
| `flutter test test/widget_test.dart --reporter expanded` | 3 passed |
| `flutter test test/phase2_repository_test.dart test/phase2_query_test.dart --reporter expanded` | Initial completed batch: 24 passed; subsequent SQLite projection/dependency test is included in the final suite |
| `flutter test test/phase2_widget_test.dart --reporter expanded` | Initial completed batch: 7 passed; subsequent failed-view-save retry test is included in the final suite |
| `flutter test --reporter expanded` | **50 passed**: original 17 plus 33 new tests |
| `flutter test tool/render_preview.dart --reporter expanded` | **3 renders passed**: 1100×760 list, 390×844 list, 800×1200 editor; visually inspected |
| `git diff --exit-code -- lib/data/local/database.g.dart drift_schemas` | Pass; generated database and retained schema unchanged |
| `flutter build windows --release` | **Blocked/fail**: no suitable Visual Studio toolchain |
| `flutter build apk --debug --target-platform android-arm64` | **Fail**: Flutter selects Java 11.0.15; Gradle 9.3.1 requires JVM 17+ |
| `./android/gradlew.bat -p android assembleDebug -Ptarget-platform=android-arm64 --no-daemon` with the JDK override below | **Pass**, BUILD SUCCESSFUL in 1m 23s |
| `C:/Users/ipar5/AppData/Local/Android/sdk/platform-tools/adb.exe devices` | No connected Android devices |
| `Get-FileHash build/app/outputs/flutter-apk/app-debug.apk -Algorithm SHA256` | Hash below |
| `git diff --check` | Pass after normalizing documentation line endings/EOF |

For the successful Gradle retry, the same PowerShell process first executed
`$env:JAVA_HOME = (Get-Content .tools/android-java-home.txt -Raw).Trim()`.
It uses the existing local Microsoft JDK 21.0.12.1+1. No global Flutter JDK
setting, PATH or Visual Studio installation changed. Gradle reports existing
AGP/Kotlin/Gradle deprecations; future Gradle 10 compatibility remains work.
No Windows Phase 2 binary was produced.

Intermediate checks caught timezone API differences (Duration offsets and the
special UTC location), lint issues, test import/scrolling issues and a missing
priority font glyph in the first preview. These were corrected before final
passing checks. The initial native command failures remain reported above.

## Meaningful coverage

Real SQLite tests cover full edits and field patches; independent milestone
completion/order/deletion; reusable normalized tags and membership removal;
deduplicated bulk deletion, hidden children, tombstones and guarded restore;
stale editor/foreign milestone rejection; and late child-journal failure rolling
back the parent. Fault injection covers tag/view/default/delete/restore commands
and compares complete before/after state including sequence/history/dirty rows.
Saved defaults, malformed views, account guards and invalid fields are tested.
File close/reopen preserves tasks, timed instants, steps, tags, views, metadata
and journal content. Existing v1 schema/snapshot, backup and downgrade tests pass.

Query tests cover AND tokens/dimensions, OR choices, any/all tags, built-ins,
inclusive due bounds, undated tasks, reversed null placement, priority/ID tie
breaking, normalized title order, tag duplication/unique counts, fixed grouping
and malformed specs. A SQLite stream test verifies a committed edit changes the
query projection and checks membership dependencies on parent operations.

Time fixtures cover New York/Auckland gaps and folds, explicit later fold choice,
Lord Howe's half-hour gap, invalid dates/times, civil-day travel invariance and
UTC/device-day boundaries. This is host IANA resolution evidence, not native
clock-change testing or recurrence/reminder implementation.

Widgets exercise capture/completion/reopen, full edits, failed detail-save retry,
filter validation, view update/default/delete, failed view-name retention,
grouped bulk selection/confirmation/undo, keyboard capture, empty search, and
390px/200% editor/filter layouts. Actual Flutter renders use synthetic SQLite:

- [Desktop list](../screenshots/phase-2-1100.png)
- [Narrow list](../screenshots/phase-2-390.png)
- [Task editor](../screenshots/phase-2-800.png)

## Local artifact

`build/app/outputs/flutter-apk/app-debug.apk`

- Size: **102,574,785 bytes**.
- SHA256: `7bc233c992572238426f464a8c6231694b47b05529badff4cba382cbb786f6c0`.
- Debug output from the working tree; not a published release, signed production
  package, installed-device result or Windows MSIX.

## Remaining acceptance and limitations

1. Install offline on Android, exercise all flows, kill/restart the process and
   verify tasks/defaults. No device was connected.
2. Add Windows C++ prerequisites, compile these changes and verify installed
   launch/persistence and packaging. Hosted Windows evidence is Phase 1 only.
3. Check TalkBack/Narrator, native scaling, keyboard/focus, date/time entry,
   sleep/resume and OS clock/zone changes on installed targets. Widget tests and
   screenshots do not establish these behaviors.
4. Keep Phase 1 secure-storage and notification feasibility gates visible.
   Accounts/sync remain Phase 3; recurrence/calendar/reminders remain Phase 4.
   No server integration, network transport or notification delivery is claimed.
5. Queries project a whole consistent SQLite snapshot in Dart, with lazy list
   rendering. No SQL pushdown, FTS, pagination or large-workspace performance
   measurement. Preserve tested semantics when scaling this implementation.
6. Entry zones are explicit and start at UTC; display uses the device zone.
   Views refresh on resume and every minute, so date/deadline transitions can
   appear up to one minute later. Bundled IANA data is version 2025c.
7. Undo covers in-session deletion/status actions. No persistent trash,
   arbitrary edit-history restoration or portable export/import UI. There is
   no adjustable split pane/layout preference; the implemented persistent
   preference is the shared default view. Device storage remains separate.
8. No real disk-full, power loss, interrupted physical migration, installed
   native upgrade or Phase 2 hosted CI was tested. Schema stayed at v1: retained
   compatibility is verified, not a fictitious v1→v2 upgrade.

Next: review local changes and close installed-platform gates. Phase 3 requires
real accounts/two-device sync and recovery before recurrence/reminder work.

## Windows launch follow-up — 5 October 2026

The user requested opening the app and explicitly authorized installing the
missing Windows prerequisites. Modified the existing Visual Studio Build Tools
2026 18.3.2 installation using its Microsoft installer:

```text
setup.exe modify --installPath "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools" --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive --norestart
```

The installer was launched elevated with `Start-Process -Verb RunAs`. Existing
workloads were preserved; no restart was requested. This added the compiler,
CMake tools, Windows SDK and recommended workload dependencies. Afterward:

- `.tools/flutter/bin/flutter.bat doctor -v`: Visual Studio check passed,
  Windows SDK 10.0.26100.0 detected. The Android Java 11 warning is unchanged.
- `.tools/flutter/bin/flutter.bat build windows --release`: **passed in 63.8s**.
- Started `build/windows/x64/runner/Release/dourstuff.exe` in its release
  directory with a normal visible window. `Get-Process` reported a responding
  process, window title `dourstuff`, and a nonzero main-window handle.
- Executable SHA256:
  `ddc8de4e08cb15784652ed20c7f126b0daba22ec429cb3fb36a39a00330b20ec`.

The app was left open for the user to test. This supersedes the earlier local
Windows toolchain/compile blocker and establishes an unpackaged window launch.
It does not establish successful interactive task operations, process-restart
persistence, accessibility, signed MSIX installation or notification behavior.
No application source changed during this launch follow-up, and nothing was
pushed or published. Keep the executable with its generated DLLs/data folder.

## Capture and editor refinement — 5 October 2026

User feedback: due date should accompany the title during capture; the separate
Add with details flow exposed too much at once. Capture now groups title, due
date and Add task in one area (one row on desktop, wrapping on narrow/large-text
layouts). Dates offer Today, Tomorrow, a calendar with text-entry mode, and
removal. Dates remain optional. Title and date commit through one existing
SQLite saveTask transaction; success clears both inputs and failure retains both.

The editor initially shows title and due date, with Add time available for a
selected date. Notes, status, priority, estimate, tags, milestones and metadata
are collapsed under More details. Collapsing keeps draft values. Existing timed
deadlines still show their time and zone. No schema or command contract changed.

Checks for this refinement:

- `.tools/flutter/bin/dart.bat format --output=none --set-exit-if-changed lib test tool`:
  **passed**, 26 files, zero changed.
- `.tools/flutter/bin/flutter.bat analyze`: **passed**, no issues (6.8s).
- `.tools/flutter/bin/flutter.bat test --reporter expanded`: **55 passed**.
  Five added widget scenarios exercise date capture and a single journal entry,
  rollback/draft retention/retry, custom date cancellation/entry/removal,
  preservation of collapsed details, and timed/date-only/undated editor changes.
  Existing SQLite, query, failure recovery and 200% text checks still pass.
- `.tools/flutter/bin/flutter.bat test tool/render_preview.dart --reporter expanded`:
  **3 passed**. Regenerated and visually inspected the 1100px and 390px home
  previews and 800px editor preview in `docs/screenshots/phase-2-*.png`.
- The first targeted widget run had one failing new assertion because it queried
  a nonexistent `changes_json` column. Corrected the test to inspect the existing
  `envelope_json`; the targeted rerun and final full suite passed.
- `.tools/flutter/bin/flutter.bat build windows --release`: **passed in 28.5s**.
- The previous app process was already closed. Opened the rebuilt release
  directory's `dourstuff.exe`; process 48068 reported `Responding=True`, window
  title `dourstuff` and a nonzero window handle. Left it open for user testing.
- `git diff --check`: **passed**.

These are host/widget results. Native interaction, accessibility and Android
installation gates remain open; earlier Android artifacts predate this UI change.
No push, deployment or publication was performed.
