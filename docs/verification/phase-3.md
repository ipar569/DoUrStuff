# Phase 3 verification

Status: milestone **3.0 local readiness passed; 3.1 in progress**, reviewed
25 October 2026. The user accepted
the Android emulator offline/restart evidence on 12 October for local Phase 3
entry. Immutable v2 operations, six strict RPC codecs and causal/policy fixtures exist;
accounts and sync are not enabled. See the latest handoff below.

The [delivery plan](../proposals/2026-10-09-phase-3-plan.md) defines milestones,
entry requirements and exit evidence under the accepted architecture.
The [Phase 2 report](phase-2.md) remains the source for current application checks
and open installed-platform gates. Its prior test results do not verify Phase 3.

The initial planning inspected protocol, repository account guard, schema and
runbooks. Subsequent checks reached Docker's Linux daemon and the Android
emulator. Supabase CLI 2.120.0 is now installed and checksum/version/help verified
through approved escalation after the permission change. Local configuration is
initialized. The user subsequently updated Docker to Desktop 4.95.0 / Engine
29.8.2. Local services, image pins and explicit loopback bindings passed checks.
Fifteen migrations and real synthetic-account registration/pull/apply/ownership
tests ran on PostgreSQL 17.11. Apply now covers core task creation and
title/priority/status/description/estimate/due edits, task deletion, exact-deletion restore
and milestone creation/edit/deletion/order with parent dependencies, plus tag creation/edit/deletion
with frozen-name collision recovery and private durable status history. Full draft
fields, history download, native OAuth and client sync remain unfinished.

| Gate | Evidence/status |
| --- | --- |
| Phase 2 entry acceptance | Accepted by user using emulator evidence; physical-device gate retained |
| Protocol and SQLite upgrade | Six RPC codecs/goldens and field/relationship/recovery policy fixtures implemented; real server enforcement and local v2 upgrade pending |
| Local backend readiness | Existing local stack verified; guarded restart and image pins recorded; fresh Windows recreation needs the documented binding repair |
| Real PostgreSQL command/RLS integration | Registration/pull, core creation and title/priority/status/description/estimate/due edits tested, including receipts/recovery/history/RLS; remaining groups/commands, snapshots and resolution unfinished |
| Android/Windows PKCE and secure session storage | Not implemented or verified |
| Full command replication/conflict recovery | Not implemented or executed |
| Adoption, bootstrap, account lifecycle/deletion | Not implemented or executed |
| Installed two-device fault/restart tests | Not executed |
| Foreground and polling latency distributions | Not measured |
| Backend recovery/deployment readiness | Not implemented or rehearsed |

Record exact commands, versions, fixtures, devices/build hashes, expected/actual
results and sanitized timing evidence here as work proceeds. No cloud resources
were provisioned. The initial planning did not rerun application tests/builds;
subsequent dated entries record local checks.
No deployment or publication occurred. Phase 4 remains gated on tested sync.

## Next-session handoff — 9 October 2026

Current milestone: before 3.0 implementation; Phase 2 Android entry acceptance
is still open. Planning deliverables are the delivery plan, the
[architecture diagrams](../architecture/phase-3-sync.md), and refreshed
[session prompts](../prompts/README.md) for Phases 3–5 and platform verification.
The prompts include milestone order, prerequisite checks and resume instructions.
Phase 2/platform prompts now reflect the latest recorded offline-app baseline.

For the prompt refresh, `git diff --check` passed. Only documentation changed;
application tests/builds were not rerun. Existing unrelated working-tree changes
were preserved. No new device, backend, auth or timing evidence was produced.

Next action: run the platform-verification prompt against an available Android
test device, record the exact APK/device and offline/restart results in Phase 2,
then use the Phase 3 prompt to start 3.0 once the entry gate is satisfied. Recheck
current code and reports first; later evidence may supersede this handoff.

## Readiness review — 10 October 2026

Reviewed clean HEAD `894766a27e7a241e5f8c8dc260e523d209220f84` and all documents
required by the Phase 3 prompt, including the full accepted proposal and both
architecture diagrams. Applied `.agents/skills/sync-protocol/SKILL.md` and
`.agents/skills/database-migrations/SKILL.md`. Existing source was preserved;
this session adds only documentation, with no commit/push/deployment/publication.

The user confirmed Android offline/restart acceptance has **not** been completed
and requested that the gate remain open. The earliest unfinished milestone is
still **3.0**, before implementation. No account code, protocol fixture, backend
migration, schema upgrade or provider dependency was introduced.

Delivered planning: [readiness inventory](../proposals/2026-10-10-phase-3-readiness.md)
maps current commands/schema gaps to required fixtures and describes a candidate
durable-held-operation approach to contiguous sequencing. It explicitly requires
executable proof after entry acceptance; a written scenario is not a passed test.
README/backlog and setup/backend/cost/recovery runbooks now reflect current gates.

| Exact readiness command/check | Result |
| --- | --- |
| `git status --short`; `git rev-parse HEAD` | Initially clean; revision above; final changes are documentation only |
| `C:/Users/ipar5/AppData/Local/Android/sdk/platform-tools/adb.exe devices -l` | No connected devices; native Android gate unverified |
| `docker version` | **Failed** daemon connection: default `docker_engine` pipe missing; client 23.0.5/API 1.42 discovered, no server readiness established |
| `Get-Command supabase -ErrorAction SilentlyContinue` | No PATH match; not a machine-wide absence claim |
| `Test-Path supabase`; `Test-Path .tools/supabase` | Both false |
| `node --version` | v24.14.0; CLI not installed/pinned/tested |
| Pinned Flutter lockfile/codegen/format/analyze/full tests/native builds | Pass; **55 tests**, Windows release and Android debug compile; exact commands/artifact hashes in the [10 October Phase 2 entry](phase-2.md#phase-3-entry-recheck--10-october-2026) |
| `git diff --exit-code -- lib test pubspec.lock drift_schemas`; `git diff --check` | Pass; no source/schema/lockfile changes |

Official provider documentation rechecked on 10 October:
[pricing](https://supabase.com/pricing),
[pausing](https://supabase.com/docs/guides/platform/free-project-pausing),
[database limits](https://supabase.com/docs/guides/platform/database-size),
[CLI setup](https://supabase.com/docs/guides/local-development/cli/getting-started),
and [Flutter auth persistence](https://github.com/supabase/supabase-flutter/blob/main/packages/supabase_flutter/README.md#custom-session-storage).
Numerical Free/Pro assumptions remain consistent; pausing restoration currently
has a one-year window and database fair-use restriction can return HTTP 402.
The moving upstream Flutter README now documents `asyncStorage`/`AuthAsyncStorage`
covering session and PKCE persistence. Recheck the chosen pinned release before
implementing; neither documentation nor host checks prove native auth behavior.
No real account configuration, credentials, endpoint or cloud resources were used.

## Next-session handoff — 10 October 2026

- **Milestone:** pre-3.0 implementation. Phase 2 Android entry acceptance is open
  by explicit user confirmation. The Phase 3 task prompt authorizes implementation
  once that gate passes; the delivery plan's historical planning-only wording
  does not require another architecture approval.
- **Delivered versus planned:** the guest Phase 2 application and v1 schema are
  unchanged. New readiness notes are planning only. All Phase 3 integration,
  auth, full replication, lifecycle, two-device latency and recovery gates in
  the ledger above remain unverified.
- **Relevant files:** this report, `docs/verification/phase-2.md`,
  `docs/proposals/2026-10-10-phase-3-readiness.md`, README/backlog, and the four
  updated runbooks. Implementation touchpoints remain `lib/domain/sync.dart`,
  `lib/data/local/task_repository.dart`, `database.dart` and `schema.drift`.
- **Evidence:** checks used the revision above with documentation-only working
  tree changes. The Phase 2 entry records exact commands, 55 passing tests,
  successful builds and APK hash. No hosted CI/native acceptance was inferred.
  Prior Java-selection failures, current Android tooling warnings and Docker
  daemon failure remain recorded; no destructive recovery was attempted.
- **External prerequisites:** an authorized Android synthetic-data test device;
  later, a running Docker-compatible backend runtime, tested/pinned Supabase CLI,
  phone-reachable restricted development endpoint and GitHub OAuth redirects.
  Secrets belong only in secure operator/provider configuration.
- **Next executable action:** connect the Android device, run `adb devices -l`,
  then complete the Phase 2 offline fresh-install/edit/force-stop/reopen/default
  checklist with the current APK and record expected/actual evidence. Once it
  passes, implement 3.0 typed protocol and dependency fixtures, then validate
  local backend readiness before 3.1. Retain separate Windows fresh-install/
  abrupt-kill, native accessibility/clock-change and secure-storage/notification
  feasibility gates. Phase 4 remains gated on completed real two-device sync.

## Milestone 3.0 foundation — 12–13 October 2026

Resumed the existing working tree at HEAD
`894766a27e7a241e5f8c8dc260e523d209220f84`; earlier documentation changes were
preserved. The [Phase 2 report](phase-2.md#android-emulator-acceptance--1012-october-2026)
records Android 11 x86_64 fresh offline launch/edit, delete/undo, query/default
view and force-stop/relaunch acceptance, APK identity, screenshot and read-only
SQLite checks. On 12 October the user explicitly replied **"Use emulator
evidence; proceed with local Phase 3"**. Local implementation is authorized;
physical-device and retained native gates remain open.

Delivered source and contracts:

- `lib/domain/account_sync.dart`: separate account protocol v2, immutable
  canonical payloads, original absent/observed/predecessor bases, kind-qualified
  composite identities, operation/batch bounds and pure field comparison.
- `lib/domain/account_sync_rpc.dart`: provider-free typed apply/pull/device/
  snapshot/resolution requests/results, failure categories, receipts versus
  expired-receipt acknowledgement, versioned recovery records and shadow data.
  Only apply has a wire encoder/golden fixture; remaining codecs and boundary
  validation are pending. These are contracts, not an operational adapter.
- `test/fixtures/account-protocol-v2-chain.json`, `test/account_sync_test.dart`
  and `test/support/account_protocol_fixture.dart`: **16 new tests** with a
  test-only field-chain model. Conflict N and held N+1 both consume their
  sequences; independent N+2 applies. Original bases/candidates remain intact,
  accepted predecessor revisions bind without changing payloads, and backward
  clocks do not order conflict resolution. Tests cover duplicate/lost responses,
  identity/sequence violations, partial groups, immutable nested values and
  representation snapshot/reload after receipt expiry without reapplying work.
- [Account protocol v2](../architecture/account-protocol-v2.md): queue states,
  field groups, tag-collision/deleted-default/delete/restore policies and minimal
  retained-data SQLite upgrade plan. Relationship/deletion/resolution policies
  still need executable fixtures; documentation is not proof of those paths.

The model only applies `task.edit` field patches. Its snapshot is an in-memory
serialization exercise, not durable SQLite/PostgreSQL recovery. No backend,
RLS, concurrency lock, HTTP transport, account profile/auth adapter, migration,
sync worker or account UI was implemented. Guest protocol/schema v1, retained
fixtures and the account-write guard are unchanged. No new dependency or paid
service was added. No commit, push, deployment or publication occurred.

### Exact local checks

Commands ran from the repository root using Flutter 3.47.6 / Dart 3.13.5.
12 October checks preceded a session interruption; final analysis/tests/builds
below completed on 13 October against the source changes in this working tree.

| Command | Result |
| --- | --- |
| `.tools/flutter/bin/flutter.bat pub get --enforce-lockfile` | Pass on 12 October; lockfile unchanged; newer package notices were not upgrades |
| `.tools/flutter/bin/dart.bat run build_runner build` | Pass on 12 October, 9s, 7 outputs; committed database/schema unchanged |
| `.tools/flutter/bin/flutter.bat test test/account_sync_test.dart test/domain_test.dart test/local_database_test.dart --reporter expanded` | **28 passed**, including 16 new protocol tests |
| `.tools/flutter/bin/dart.bat format --output=none --set-exit-if-changed lib test tool` | Pass on 13 October; 30 files, zero changed |
| `.tools/flutter/bin/flutter.bat analyze` | Pass on 13 October; no issues, 48.3s |
| `.tools/flutter/bin/flutter.bat test --reporter expanded` | **71 passed** on 13 October; domain, real SQLite, retained schema and widgets |
| `.tools/flutter/bin/flutter.bat build windows --release` | Pass on 13 October, 13.7s; no new installed Windows acceptance |
| `./android/gradlew.bat -p android assembleDebug -Ptarget-platform=android-arm64 --no-daemon` | Pass on 13 October, 59s; session-only JDK override as below |
| `git diff --exit-code -- lib/data/local/database.g.dart drift_schemas pubspec.lock test/fixtures/protocol-v1-create.json` | Pass; generated database, retained snapshots, lockfile and guest golden unchanged |
| `Get-FileHash build/app/outputs/flutter-apk/app-debug.apk,build/windows/x64/runner/Release/dourstuff.exe -Algorithm SHA256` | Artifact identities below |
| `git diff --check` | Pass |

Android used
`$env:JAVA_HOME = (Get-Content .tools/android-java-home.txt -Raw).Trim()`.
Direct `flutter build apk` Java-selection failure remains historical/unfixed;
the documented Gradle route passed. Existing AGP/Kotlin/Gradle deprecations and
SDK XML v3/v4 tooling warnings remain. The first 12 October analyzer run failed
with two `curly_braces_in_flow_control_structures` findings; both were fixed,
then analysis/full tests passed. A Windows build started before interruption
had no retrievable completion result (`Unknown process id` on resume); the
13 October successful build supersedes that unverified attempt.

13 October APK: **121,978,607 bytes**, SHA256
`854dbf2f1e18a6c4b401e812ec633e55129e2c6ae3a72a85e039209697862f40`.
This arm64-target build was not installed in the acceptance emulator; its
separate tested x86_64 artifact is retained in the Phase 2 report. Unused domain
contracts do not change the shipped guest app. Windows runner: **90,112 bytes**,
SHA256 `ddc8de4e08cb15784652ed20c7f126b0daba22ec429cb3fb36a39a00330b20ec`;
this hash identifies only the runner, not its required release DLLs/data.
No new hosted CI or preview rendering was run for these non-UI changes.

### Backend readiness and remaining gates

Starting Docker Desktop made `docker version` reach Linux server 23.0.5/API1.42
(Desktop 4.19.0, containerd 1.6.20, runc 1.1.5). The earlier missing-pipe failure
and the first startup `docker_engine_linux` failure remain historical evidence.
No Supabase stack was started, so daemon response is not backend compatibility.

Official GitHub release metadata identified Supabase CLI v2.120.0 as a candidate;
the [backend runbook](../runbooks/backend.md) records source and ZIP digest.
Automatic approval review rejected its combined download/verification/extraction/
version/help command **before execution**, reporting `blocked by policy` without
further explanation. No workaround was attempted. CLI installation, tested
dependency pins, exact installed help and stack health remain unresolved.
No credentials, provider endpoint, redirects or production resources were used.

Milestone 3.0 remains **in progress**: finish strict RPC wire codecs/goldens,
parent/ownership/normalized-tag policy fixtures, both delete/edit orderings,
restore and deleted-default preconditions, terminal rejection and resolution
races. Add the tested tool/dependency pin before claiming readiness. Real
transactional PostgreSQL/RLS proof belongs to 3.1; native auth and retained-data
migration to 3.2. All two-device, latency, recovery/deployment gates remain open.

## Next-session handoff — 13 October 2026

- **Current milestone:** 3.0 foundation implemented and locally tested, not
  complete. The emulator-based entry decision is accepted; do not ask for it again.
- **Delivered versus planned:** the source/fixture inventory above is executable;
  relationship/delete/restore rules and SQLite v2 are still plans. The guest app
  remains the only supported application mode. Account writes still fail closed.
- **Relevant files:** the two account domain files, account protocol test/fixture/
  test support, `docs/architecture/account-protocol-v2.md`, both verification
  reports, README/backlog and setup/backend/cost/recovery runbooks. Preserve the
  earlier readiness notes and emulator screenshot. `.tools` contains ignored
  local APK/profile evidence and helpers, not portable committed fixtures.
- **Results/limits:** final 71 tests, clean analyzer/format, successful Android
  and Windows builds; exact revision, commands, hashes and failures above. No
  hosted CI/server/native auth/two-device success is implied.
- **External prerequisites:** an installed approved Supabase CLI, compatible
  running Docker stack, later a restricted development endpoint reachable from
  Android/Windows and configured GitHub native redirects. Keep secrets out of
  source/chat. Physical Android and retained Windows/platform tests remain open.
- **Next executable action:** complete v2 request/result wire fixtures and strict
  validation, then executable relationship/delete/restore/resolution policies.
  When an approved CLI is available, inspect its version/help, pin it and verify
  local stack health before 3.1 migrations/RLS tests. Do not retry the blocked
  installation through another mechanism. Do not enable account writes, advance
  to Phase 4, push, publish or execute production migrations.

### Permission follow-up — 13 October 2026

The user set the desktop app to Full Access to allow the blocked CLI setup.
The session reported unrestricted filesystem/network access with approval
policy `never`. A single retry of the official v2.120.0 ZIP download, recorded
SHA256 verification, local extraction, `--version` and `start --help` was again
rejected before process creation: `blocked by policy`, with no specific reason.
Nothing was installed or executed by that attempt. The suggested `/approve`
command was unavailable in this desktop app; that guidance was incorrect for
this user's available controls. No confirmed desktop override has been found.
Full Access alone does not resolve this block. Independent 3.0 contract work
remains possible; the next action and backend integration limits above stand.

### CLI setup unblocked / updated handoff — 13 October 2026

The user changed permission mode again and requested a retry. The environment
now allowed explicit escalation requests. The same scoped official download,
checksum check, local extraction and version/help execution succeeded through
approved `require_escalated` execution. The earlier blanket restriction is no
longer a CLI-installation blocker; approval requests must still be respected.

| Executed check/action | Result |
| --- | --- |
| `Invoke-WebRequest -Uri https://github.com/supabase/cli/releases/download/v2.120.0/supabase_2.120.0_windows_amd64.zip -OutFile .tools/supabase_2.120.0_windows_amd64.zip`, `Get-FileHash -Algorithm SHA256`, `Expand-Archive` | Pass; expected SHA256 `0db5224fc5d92ae5f15e675ed65dad376967326921122ab8d9a78e790874c92e` matched before extraction/execution |
| `.tools/supabase/supabase.exe --version` | Pass: **2.120.0**; pinned in new `.supabase-version` |
| `.tools/supabase/supabase.exe start --help` | Pass; exact installed flags inspected |
| `.tools/supabase/supabase.exe init --help` | Initial sandbox failure: EPERM writing the CLI's user telemetry configuration; approved escalation retry passed |
| `Start-Process -FilePath 'C:/Program Files/Docker/Docker/Docker Desktop.exe' -WindowStyle Hidden` | Started the existing desktop runtime through approved escalation |
| `docker version` | Initially missing daemon pipe, then sandbox pipe access denied; approved escalation passed: client/server 23.0.5, API 1.42, Linux amd64 engine, Desktop 4.19.0 |
| `git diff --check` | Pass |

No project initialization, container stack health check, migrations or provider
authentication ran. CLI version/help success and a responsive engine do not
establish stack compatibility. Only tool setup, its version pin and documents
changed after the 71-test/native-build run; application tests were not repeated.
No push, publication or production change occurred.

**Next action remains milestone 3.0:** finish strict RPC wire fixtures and
relationship/delete/restore/resolution policies. The CLI installation prerequisite
is now met. Next backend prerequisite is initializing/reviewing local-only
configuration and running actual stack health checks with the pinned CLI, then
3.1 migrations/RLS tests. Preserve all existing work and open native/two-device
gates. Use normal scoped escalation when sandbox restrictions require it;
the earlier failed `/approve` guidance is not applicable to this desktop flow.

## Milestone 3.0 wire and policy checks — 13 October 2026

This entry records the completed increment that was not yet written into the
report when the session paused. It supersedes the pending wire/policy work in
the earlier handoff, while preserving its historical results and failures.

- `lib/domain/account_sync_codec.dart` and the retained
  `test/fixtures/account-protocol-v2-rpc.json` cover all six RPC requests/replies:
  registration, apply, pull, snapshot begin/page and resolution. Validation
  rejects missing/extra keys, unsupported versions, unsafe counters, invalid
  identities, contradictory receipts and inconsistent pagination. Apply/pull,
  resolution and snapshot-page correlation checks run before acknowledgement
  or staging. Raw transport body limits remain an adapter responsibility.
- `account_sync_policy.dart` and its tests specify same-owner parent acceptance,
  both delete/edit orders, conditional deleted-default clearing, tag-name
  collisions, exact restore identity/30-day expiry and resolution races.
  `account_sync.dart` includes explicit immutable restore preconditions.
- The field-chain fixture uses the production operation decoder. A terminal
  invalid-title rejection consumes its sequence once, retains repair candidates,
  routes dependent work to recovery and permits unrelated work. It remains a
  test-only `task.edit` model, not full server command validation.
- `supabase init` succeeded with CLI 2.120.0. `supabase/config.toml`, its ignore
  file and README prepare a local-only project with API object auto-exposure,
  seeds, analytics and unused edge runtime disabled. No stack was started.
  TOML syntax and those settings passed local assertions. The user replied
  **"I'll update Docker Desktop"** to the Engine 28+ runtime prerequisite.

There were **43 account tests** (17 field-chain, 20 codec, 6 policy), plus the
existing 55 application tests. No app wiring, account storage/auth, transport,
PostgreSQL migrations/RLS or local schema migration was added. SQL normalization
parity, command semantics, locking and ownership enforcement remain unverified.

| Exact command | Result on 13 October |
| --- | --- |
| `.tools/flutter/bin/flutter.bat pub get --enforce-lockfile` | Pass; lock unchanged |
| `.tools/flutter/bin/dart.bat run build_runner build` | Pass, 6s, 15 outputs written; no retained schema/generated database diff |
| `.tools/flutter/bin/dart.bat format --output=none --set-exit-if-changed lib test tool` | Pass, 34 files, zero changed |
| `.tools/flutter/bin/flutter.bat analyze` | Pass, no issues, 4.1s |
| `.tools/flutter/bin/flutter.bat test --reporter expanded` | **98 passed** |
| `.tools/flutter/bin/flutter.bat build windows --release` | Pass, 11.6s |
| `./android/gradlew.bat -p android assembleDebug -Ptarget-platform=android-arm64 --no-daemon` | Pass, 37s, with the previously documented session JDK override |
| `git diff --exit-code -- lib/data/local/database.g.dart drift_schemas pubspec.lock test/fixtures/protocol-v1-create.json` | Pass |
| `git diff --check` | Pass |

Initial sandbox formatting/tool execution hit user telemetry/cache access
restrictions; the approved escalation succeeded. Initial codec analysis reported
17 findings (two private aliases in public API, 15 missing braces), all fixed;
two policy brace findings were also fixed before the clean final analysis.
The APK and Windows runner sizes/hashes match the earlier 13 October artifact
identities above. Unused domain code does not change the guest app. No fresh
installed-device test, hosted CI or real server integration ran.

## Next-session handoff — 16 October 2026

- **Current milestone:** 3.0 remains in progress because actual backend runtime
  readiness/image verification is open. The Phase 2 emulator entry approval
  remains valid; physical-device and retained native gates remain separate.
- **Working tree:** resumed HEAD `894766a27e7a241e5f8c8dc260e523d209220f84` with all
  earlier edits/untracked files preserved. Results apply to this uncommitted
  working tree, not the unchanged HEAD alone.
- **Delivered this session:** registration and snapshot-begin reply validators
  reject mismatched server epochs; snapshot creation also rejects expired
  manifests before staging. Two regression tests exercise valid replies,
  changed epochs, the exact expiry boundary and non-UTC validation time.
  These provider-free checks do not implement the future profile/generation
  boundary or durable snapshot installation. Corrected stale report/backlog
  wording and the canonical-JSON documentation typo.
- **Runtime recheck:** `docker version` failed because the `docker_engine` pipe
  is absent; the discovered client is still 23.0.5. Reading the installed
  `C:/Program Files/Docker/Docker/Docker Desktop.exe` version reports
  **4.19.0.106363** and no Docker process was listed. This does not prove an
  update is complete or establish the current stopped server version. Asked
  whether the user's update is still pending; no Supabase service was started.
- **Remaining gates:** Engine 28+ and healthy local stack with loopback bindings
  and recorded image digests, then real 3.1 PostgreSQL command/RLS/concurrency
  tests. Full semantic validation and Dart/PostgreSQL tag normalization parity
  are still required. Native auth/secure storage, retained-data migration,
  full replication/recovery, lifecycle, physical acceptance and measured
  two-device latency remain open. Account writes remain guarded; Phase 4 waits.
- **Next executable action:** after the Docker update, recheck `docker version`,
  inspect/create the dedicated loopback network using `supabase/README.md`,
  then start the pinned CLI stack with `--network-id dourstuff-local` and its
  normal health checks. Keep credential output out of chat/source. Record
  actual bindings, health and image digests before proceeding to 3.1 migrations.
  No production configuration, migration execution, push or publication is
  authorized by this handoff.

### Local checks on 16 October

Pinned Flutter 3.47.6 / Dart 3.13.5; scoped approval allowed normal SDK/user-cache
access. No new dependency or schema change required repeating dependency
resolution or code generation after their successful 13 October checks.

| Exact command | Result |
| --- | --- |
| `.tools/flutter/bin/dart.bat format lib/domain/account_sync_codec.dart test/account_sync_codec_test.dart` | Pass; one file formatted |
| `.tools/flutter/bin/flutter.bat test test/account_sync_codec_test.dart test/account_sync_policy_test.dart test/account_sync_test.dart test/domain_test.dart test/local_database_test.dart --reporter expanded` | **57 passed**, including real SQLite invariants |
| `.tools/flutter/bin/dart.bat format --output=none --set-exit-if-changed lib test tool` | Pass, 34 files, zero changed |
| `.tools/flutter/bin/flutter.bat analyze` | Pass, no issues, 31.7s |
| `.tools/flutter/bin/flutter.bat test --reporter expanded` | **100 passed**; 45 account protocol/policy tests plus 55 existing tests |
| `git diff --exit-code -- lib/data/local/database.g.dart drift_schemas pubspec.lock test/fixtures/protocol-v1-create.json` | Pass; retained schema, generated DB, lock and guest golden unchanged |
| `.tools/flutter/bin/flutter.bat build windows --release` | Pass, 15.4s |
| `./android/gradlew.bat -p android assembleDebug -Ptarget-platform=android-arm64 --no-daemon` | Pass, 48s; 123 tasks, 20 executed, 103 up-to-date; session JDK override as above |
| `Get-FileHash build/app/outputs/flutter-apk/app-debug.apk,build/windows/x64/runner/Release/dourstuff.exe -Algorithm SHA256` | Identities below |
| `git diff --check` | Pass |

The local TOML syntax/settings assertions passed again. APK: 121,978,607 bytes,
SHA256 `854dbf2f1e18a6c4b401e812ec633e55129e2c6ae3a72a85e039209697862f40`.
Windows runner: 90,112 bytes, SHA256
`5b5bf42216fe9657c59238780ef08d3879af713a3a7397163bcefaad6b4db858`.
The runner hash covers only that file, not release DLLs/assets. Existing Android
AGP/Kotlin/Gradle deprecations and SDK XML v3/v4 warnings remain. Build success
does not add installed-device acceptance. No real backend/CI/native OAuth or
two-device run occurred; no push, publication or production change occurred.

## Real local backend foundation — 16–17 October 2026

The user confirmed the Docker update. `docker version` now verifies Desktop
4.95.0 (242831), Engine 29.8.2/API 1.56, Linux amd64, containerd 2.3.6 and runc
1.5.1. CLI 2.120.0 remains pinned; the advertised 2.121.0 update was not installed.
The nine service tags/image IDs/registry digests are recorded in
`supabase/images.lock.json`. PostgreSQL reports 17.11. No remote project exists.

The local 3.0 entry/tooling/wire-policy readiness checks have passed. Phase 3.1
has started with two versioned migrations:

- `20261016000100_account_foundation.sql`: private backend epoch, account cursor,
  device watermark and change-log tables; forced RLS and a non-login/non-bypass
  RPC role; versioned device-registration and committed-log pull functions.
  Registration is idempotent and account-qualified. Pull locks the account row,
  returns whole revision groups, bounds payloads, rejects expired cursors and
  fails closed when a retained revision is missing. There is no apply writer yet.
- `20261016000200_auth_identity_boundary.sql`: forward fix for the managed Auth
  schema boundary. Private argument-free identity/liveness helpers run as the
  migration owner; they can only inspect the caller's identity. Public RPCs run
  as the restricted role. Helpers/RPCs fix their search paths and restrict
  execute grants. Revoked accounts and stale JWTs after auth deletion are denied.

`tool/test_backend_foundation.py` exercises real PostgreSQL and local Auth/HTTP
with random synthetic X/Y accounts, then cleans them up. Eight integration
groups passed on 16 October: rollback-only empty application-schema bootstrap;
retained watermark through the forward migration; concurrent registration;
anonymous/X/Y raw REST and private-schema bypass denial; strict requests;
actual RLS/function grants; account-lock commit ordering/whole-group pull and
owner isolation; retention/missing-log behavior; revoked/deleted identities.
The reported eight groups combine related assertions, not eight total requests.
Ten captured successful replies also passed the production Dart codecs through
`tool/check_backend_wire.dart`. No privileged credential enters those fixtures.

Concurrency uses synthetic SQL writers following the account lock, not an apply
RPC. It proves the lock/read primitive on PostgreSQL, not command atomicity,
idempotent command application, field conflict resolution or client convergence.
The migration rehearsal resets only the application schema inside a transaction
that rolls back; it is not a fresh provider-cluster or disaster-recovery test.

### Failures retained and corrected

1. Initial `supabase start --network-id dourstuff-local` failed applying migration
   001: SQLSTATE 42501, must be able to SET ROLE `dourstuff_rpc`. Before successful
   application, the migration was corrected to let the migration user assign
   function ownership and temporarily grant schema CREATE, then revoke it.
2. The retry passed startup health checks, but actual bindings were `0.0.0.0`/
   `::`, despite the network's `host_binding_ipv4=127.0.0.1` option. All nine
   project containers were immediately stopped. A scoped local helper recreated
   only DB/Kong/Studio/mail containers with explicit `HostIp=127.0.0.1`, keeping
   the same image IDs, volume mounts and injected configuration. The originals
   remain stopped with `-before-loopback` suffix. No volumes, unrelated containers,
   Docker daemon settings or firewall rules were removed/changed. After repair,
   ports 54321–54324 were verified loopback-only; all eight defined healthchecks
   passed and PostgREST HTTP was exercised by integration tests.
3. The first HTTP registration test failed 403: permission denied for schema
   `auth`. Migration 002 fixes this through private identity helpers. A local
   schema/data dump was retained before the forward migration; no reset was used.
   Both migrations are recorded in `supabase_migrations.schema_migrations`.
4. Initial analysis of the new Dart wire checker reported two missing-brace
   findings; both were corrected on 17 October. Results below supersede that run.
5. On 17 October the first runtime check found Docker stopped. Docker Desktop was
   started hidden, then the existing repaired containers were resumed through
   the guarded restart helper. No fresh container initialization was requested.

### Commands and evidence

| Command/action | Recorded result |
| --- | --- |
| `docker version` | Engine 29.8.2 verified after update |
| `docker network create --driver bridge --opt com.docker.network.bridge.host_binding_ipv4=127.0.0.1 dourstuff-local` | Network created; option alone did not restrict actual ports on this host |
| `.tools/supabase/supabase.exe start --network-id dourstuff-local` | First failed migration ownership; retry passed health, then was stopped for incorrect port bindings |
| `python .tools/rebind_supabase.py` | Four stopped project containers recreated with explicit localhost bindings; originals and data preserved |
| `docker exec supabase_db_dourstuff-local pg_dump -U postgres -d postgres --schema=sync_private --schema=public --no-owner --no-privileges` | Saved to ignored `.tools/backend-before-auth-boundary.sql` before migration 002; not a tested restore artifact |
| `.tools/supabase/supabase.exe migration up --local --network-id dourstuff-local` | Migration 002 passed; no linked/remote execution |
| `python tool/local_backend.py` | Nine pinned services running; eight healthchecks healthy, PostgREST running; published ports loopback-only |
| `python tool/test_backend_foundation.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-foundation-wire.json` | Eight integration groups passed on 16 October; synthetic account cleanup confirmed |
| `.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-foundation-wire.json` | Ten real backend replies passed Dart validation |

Counts after cleanup were zero application accounts and zero synthetic Auth
users matching the harness prefix. Local credentials stayed in process memory
or ignored startup logs; none were printed into chat or committed. SQLite schema
v1, guest fixtures, lockfile and app account-write guards are unchanged. The
16 October Android/Windows builds above remain the latest native compilation
evidence; this server/tool-only increment does not change the shipped app.

## Interim handoff — 17 October 2026, before command application

- **Current milestone:** 3.1 server foundation in progress; local 3.0 readiness
  passed. Phase 2 emulator entry is already accepted. Do not ask for it again.
- **Revision/worktree:** HEAD remains `894766a27e7a241e5f8c8dc260e523d209220f84`;
  tests apply to the preserved uncommitted tree, including earlier protocol/docs.
- **Delivered:** two local migrations, registration/pull and ownership tests,
  runtime/image/binding verification, and a Dart checker for actual HTTP replies.
  See `supabase/README.md`, `supabase/migrations`, `supabase/images.lock.json`,
  `tool/local_backend.py`, `tool/test_backend_foundation.py` and
  `tool/check_backend_wire.dart`. All other Phase 3 client/backend paths remain
  unfinished; the app remains guest-only.
- **Operational constraint:** restart existing repaired containers with
  `python tool/local_backend.py --start`. Do not restart the stopped originals or
  recreate services with plain CLI startup on this host. Fresh Windows startup
  still needs an explicit binding solution and verification; the local one-time
  repair is not a portable deployment workflow. Keep backups and volumes intact.
- **Next implementation:** a forward migration for atomic command application,
  canonical fields, immutable receipts, durable sequence high-water and recovery
  candidates; reproduce the conflict/dependent/unrelated fixture in PostgreSQL,
  with duplicate/lost replies, terminal rejections and receipt expiry. Preserve
  account locking and deny raw writes. Registration epoch discovery for a new
  client also remains to be integrated with the future authenticated adapter.
- **Remaining gates:** full command/relationship/normalization parity, snapshots
  and explicit resolution, local migration, secure native OAuth, client workers,
  lifecycle/adoption, real two-device/latency and recovery/deployment rehearsal.
  No push, publication or production change occurred. Phase 4 stays gated.

## Atomic task-edit server increment — 17 October 2026

Milestone 3.1 remains in progress. Migration
`supabase/migrations/20261017000100_causal_task_edits.sql` adds private task
shadows, immutable operation receipts and recovery candidates, all protected by
forced RLS and the restricted RPC role. `sync_apply` currently accepts only
existing-task `task.edit` title/priority patches without parent dependencies.
Unsupported capabilities fail whole-batch preflight without consuming sequences.
The app remains guest-only; no Flutter transport, account storage or auth was added.

Under the account row lock, canonical field changes, recovery candidates, receipt,
change-log revision and device watermark commit together. Conflicts/held edits
retain the original envelope. Accepted predecessors bind to their actual accepted
revision. Invalid supported values receive a consumed rejection with repair data;
expired detailed receipts never permit replay. No retention job is installed.

`tool/test_backend_apply.py` uses real local Auth JWTs and HTTP RPCs, with SQL
seeding only for initial canonical tasks because task creation remains unfinished.
Ten integration groups pass:

1. The committed conflict/dependent/unrelated fixture: watermark 3, revisions
   3/4/5, conflicting task unchanged, unrelated task advanced, original held
   payloads retained despite backwards provenance timestamps.
2. Lost-response retry, reordered object keys, immutable payload/sequence mismatch,
   gaps and whole-batch unsupported-capability preflight.
3. Actual predecessor revision binding, equivalent proposals, partial field merge
   and corrupt-base recovery.
4. Terminal rejection, duplicate rejection, simulated detailed-receipt expiry,
   retained held evidence and recovery when accepted predecessor evidence expired.
5. Delete/edit recovery without resurrection; X/Y reference/read/update/insert
   isolation for new tables; anonymous denial and restricted function ownership.
6. An injected log-write failure after earlier writes rolls back the entire
   operation; simultaneous identical HTTP retries produce exactly one revision.
7. Real HTTP apply waits behind an uncommitted account writer, then allocates
   the next committed revision. Another account continues independently.
8. Malformed/null/type/depth/unsafe-number/operation-count/request-size boundaries
   fail without consuming sequences.
9. Exactly 65,536 canonical UTF-8 bytes accepted, one additional byte denied;
   Unicode object keys and unnormalized strings survive immutable retry.
10. Unicode whitespace and 500 UTF-16-unit title boundaries, expired apply cursor
    and revoked-account denial.

This is local server fault injection, not process-kill, native client or two-device
acceptance. Detail expiry is a controlled deletion of synthetic receipts, not
evidence of a working scheduled retention policy. The foundation harness now
rehearses all three migrations on an empty application schema and an existing
device watermark inside a rolled-back transaction; it does not rebuild Auth or
rehearse disaster recovery.

### Commands and results

All commands ran against the preserved uncommitted working tree at HEAD
`894766a27e7a241e5f8c8dc260e523d209220f84`, using the pinned local SDK/CLI.

| Command/action | Result |
| --- | --- |
| `python tool/local_backend.py --start` | Existing repaired services resumed; explicit loopback bindings and pinned images verified |
| `docker exec supabase_db_dourstuff-local pg_dump -U postgres -d postgres --schema=sync_private --schema=public --no-owner --no-privileges` | Saved to ignored `.tools/backend-before-causal-edits.sql` before the migration; not a restore rehearsal |
| `.tools/supabase/supabase.exe migration up --local --network-id dourstuff-local` | Migration `20261017000100` applied successfully; all three migration IDs verified in local history |
| `python tool/test_backend_foundation.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-foundation-wire.json` | Eight integration groups passed with all three migrations and new-table raw REST denial |
| `python tool/test_backend_apply.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-apply-wire.json` | Ten integration groups passed |
| `.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-foundation-wire.json` | Ten real replies passed production codecs/correlation |
| `.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-apply-wire.json` | Thirty real replies passed codecs/correlation; title results also checked against `TaskDraft.validate()` |
| `.tools/flutter/bin/dart.bat format --output=none --set-exit-if-changed lib test tool` | 35 files checked, zero changes |
| `.tools/flutter/bin/flutter.bat analyze` | No issues, 23.1 seconds on the final run |
| `.tools/flutter/bin/flutter.bat test --reporter expanded` | All 100 tests passed, including domain/SQLite/schema/widget regressions |
| `git diff --check` | Passed |

Post-test SQL checks found zero application accounts, zero harness-prefix Auth
users and zero fault-injection triggers. The fixture export contains only synthetic
requests/replies, no credentials. Existing guest SQLite/generated files, schema v1,
guest protocol/occurrence fixtures and `pubspec.lock` have no diff. The native
builds recorded on 16 October remain the latest evidence: this increment changes
only backend/tools/docs, not native app sources. No push, publication or production
migration occurred. Historical failures above are retained.

### Remaining contract limits

Full server/client validation parity is still open. PostgreSQL JSONB cannot
represent embedded NUL and normalizes some raw numeric spellings before function
validation (direct check: `2e0` becomes `2`, whereas `2.0` retains its decimal
spelling). Exact-integer/range/depth checks operate on parsed JSONB; do not claim
strict rejection of every original floating-point spelling. Resolve these
transport representability differences with shared fixtures before enabling
account writes. Title boundary cases now have direct Dart/server comparison;
other entity/relationship/tag/query/date normalization rules remain unfinished.

## Implementation handoff — 17 October 2026, before PR review

- **Current milestone:** 3.1 server foundation in progress. Phase 3.0 local
  readiness and the user-accepted Phase 2 emulator entry remain passed; physical
  Android and other retained native gates stay open.
- **Delivered:** three local migrations; registration, ordered pull and atomic
  existing-task title/priority edits; immutable receipts/watermarks; conflict,
  held and rejected repair records; 18 real backend integration groups and 40
  Dart-validated HTTP replies. Full Flutter suite: 100 passed. All work remains
  uncommitted on the HEAD above, including earlier protocol and documentation work.
- **Relevant files:** `supabase/migrations`, `supabase/images.lock.json`,
  `tool/local_backend.py`, `tool/test_backend_foundation.py`,
  `tool/test_backend_apply.py`, `tool/check_backend_wire.dart`, the v2 domain
  files/fixtures, and `supabase/README.md`. Preserve existing work and applied
  migrations; use forward migrations for subsequent changes.
- **Next executable action:** extend 3.1 with task creation and the atomic
  status/completion group in a forward migration, deriving validation from the
  accepted domain rules. Add real HTTP tests for create collisions, replay and
  completion/edit concurrency in both orders, preserving original bases and
  all-or-nothing creation. Continue remaining command semantics, transport parity,
  snapshots/explicit resolution and retention checks before relying on the full
  backend contract. Do not enable partial account writes in the app.
- **Runtime:** services are running with ports 54321–54324 on `127.0.0.1` only.
  Restart existing repaired containers using `python tool/local_backend.py --start`.
  Keep stopped `*-before-loopback` originals and volumes intact; plain CLI
  recreation can lose explicit bindings. Fresh-host binding setup is still open.
- **External prerequisites:** native GitHub OAuth configuration, secure session/
  verifier storage and a restricted device-reachable development endpoint are
  still needed for later integration. Current tests use temporary local synthetic
  password accounts and do not prove GitHub PKCE. No hosted project is linked.
- **Remaining gates:** full commands/normalization, snapshots/resolution, retained
  local upgrade, profiles/auth, client workers, consent/adoption/lifecycle,
  installed two-device/latency, backend CI and restore/deployment rehearsal.
  Phase 4 remains gated. No additional permission is needed for the next local
  implementation/tests under the user's existing authorization.

## Delivery review — PR #2, 17 October 2026

The user explicitly authorized review and merge of the existing completed Phase 3
changes. This supersedes the earlier no-push constraint for this delivery only;
production deployment/migration and release distribution remain unauthorized.
The separate task-completion workflow was merged in PR #1 at
`e93455b9b225902fa93cd5a0caeb9ab20e4ab049`. All 37 existing changed files were
verified byte-for-byte before this delivery branch was created from that main.

[PR #2](https://github.com/ipar569/DoUrStuff/pull/2), branch
`codex/phase-3-server-foundation`, starts with commit
`09e6dfce314f0b761acfcc4bf43031dbef35e668`. Staging found an extra blank line at
the end of migration 002; only that whitespace was removed. Docker was stopped
at the first runtime recheck; Desktop and the previously repaired containers were
resumed through the guarded path. No containers or data were reset.

Independent server, domain and harness reviews found three actionable issues:

1. Native Dart's minimum signed integer overflowed `abs()` and passed the safe
   JSON integer guard. Explicit lower/upper comparisons now reject it.
2. A valid apply request at depth 16 produced a depth-20 conflict recovery reply
   which the client rejected. Reply envelopes now allow depth 24; embedded
   operations/values retain depth-16 validation and unchanged payload identity.
   Unit regressions cover pull and snapshot wrappers and reject over-deep embedded
   operations. A real apply/conflict/pull regression captures nested provenance
   and decodes it through the production Dart checker.
3. The harness's default HTTP client honored proxy environment variables and
   followed redirects with authentication headers. Its dedicated opener now
   disables proxies and rejects redirects. Two dummy-credential, loopback-only
   HTTP server tests verify that neither destination receives forwarded requests;
   these tests are included in the Quality workflow without requiring Docker.

Before fixes, both targeted Dart regressions and both HTTP isolation regressions
failed as expected; those failures are retained in ignored local logs. After
fixes, the targeted Dart suite passed 41 tests and the HTTP tests passed 2/2.
Full formatting checked 35 files with zero changes; `flutter analyze` found no
issues (8.5 seconds); `flutter test --reporter expanded` passed all 102 tests.
The final backend rerun passed 8 foundation groups and 11 apply groups, including
the real nested-recovery regression. `check_backend_wire.dart` validated all 10
foundation replies and 32 apply/pull replies. Exact harness commands are the
same as in the preceding command table, plus `python tool/test_backend_http.py`.
The production SQL migrations and guest SQLite schema were not changed by these
review fixes. The first PR head's Quality/Android/Windows jobs passed; a changed
head must pass its own CI and independent re-review before merging. Final review
SHAs, CI links and merge state belong to the PR timeline, not an assumed result.

## Next-session handoff — 17 October 2026, PR delivery

- **State:** Phase 3.0 local readiness passed; Phase 3.1 remains partial. The user
  accepted emulator entry evidence; physical/native/two-device gates stay open.
  App accounts and network transport are still disabled.
- **Source:** Phase 3 work is now committed on `codex/phase-3-server-foundation`
  in [PR #2](https://github.com/ipar569/DoUrStuff/pull/2), rather than the earlier
  uncommitted tree. Read its actual merge state and current checkout before
  resuming; do not recreate or recommit delivered work. Local checks above apply
  to the reviewed fixes committed with this section; CI/re-review identify the
  exact subsequent PR head. Preserve historical evidence and ignored local data.
- **Delivered:** v2 contracts/codecs/policies, three local server migrations,
  registration/pull and atomic existing-task title/priority edits, receipts,
  held/conflict/rejected recovery data, and real local integration harnesses.
  Review fixes add integer/depth guards and proxy/redirect isolation tests.
- **Next implementation:** task creation and atomic status/completion in a forward
  migration, with create-collision/replay and both completion/edit concurrency
  orders. Retain original bases and all-or-nothing creation. Continue remaining
  command/normalization parity, snapshots/resolution and retention before enabling
  account writes. JSONB raw-number/NUL representability remains a documented gate.
- **Runtime:** use `python tool/local_backend.py --start` for existing localhost-
  bound services. Keep stopped `*-before-loopback` originals and named volumes.
  Fresh-host binding setup, native GitHub PKCE/secure storage and a restricted
  device-reachable endpoint still need work. No hosted project is linked.
- **Remaining acceptance:** profiles/local migration, full client replication and
  recovery, consent/lifecycle, installed two-device fault/latency tests, full
  backend CI and restore/deployment rehearsal. Phase 4 remains gated. Use the
  new completion workflow subject to each task's explicit publication constraints.

## Core task creation/status increment — 18 October 2026

Started from clean `main` at merged PR #2 commit
`6b27a183fba64b04d1e4521b275e6487ed4d0720`; fetch confirmed no newer baseline.
Work is isolated on `codex/phase-3-task-create-status`. The current user request
authorizes branch push, PR review and merge, superseding the prompt's historical
no-push restriction. Production actions and release distribution remain unauthorized.

Forward migration `20261018000100_task_create_status.sql` adds core `task.create`,
`task.status` and status-group patches in `task.edit`. Creation requires exactly
title, priority, status_group and existence=true with absent bases. A collision
conflicts every group without modifying the existing task; invalid creation
receives a consumed rejection without partial rows. Unsupported draft fields
remain whole-batch capability failures. Completion/edit tests use separate device
epochs and both commit orders; edits preserve completion. Status/time validation
matches the new provider-free Dart validator, including negative/zero and native
DateTime endpoints. No clock selects conflict winners.

Private forced-RLS `task_status_history` records accepted transitions with
previous/current status, accepted field snapshot and device provenance. Reopening
retains earlier completion evidence. History, canonical state, receipts, recovery,
account cursor and device watermark share the existing account-lock transaction.
The app remains guest-only; history download/snapshots/retention and complete
Phase 2 draft creation are not implemented by this increment.

The first restart attempt failed because Docker was stopped. Docker Desktop was
started hidden and `python tool/local_backend.py --start` successfully resumed
the existing repaired containers. All nine pinned services and eight healthchecks
passed, with published ports only on loopback. No container or volume was reset;
stopped `*-before-loopback` backups remain preserved. A local schema/data dump
was saved before applying migration 004; it is not verified disaster recovery.

Checks below apply to this branch's working tree before its first commit; the PR
timeline records the exact reviewed SHA, subsequent fixes, CI and merge result.

| Exact command/action | Result |
| --- | --- |
| `docker exec supabase_db_dourstuff-local pg_dump -U postgres -d postgres --schema=sync_private --schema=public --no-owner --no-privileges` | Saved to ignored `.tools/backend-before-create-status.sql` |
| `.tools/supabase/supabase.exe migration up --local --network-id dourstuff-local` | Migration 004 applied; all four IDs verified in local migration history |
| `python tool/test_backend_foundation.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-foundation-wire.json` | 8 integration groups passed, including rollback-only empty-schema/forward-upgrade rehearsal |
| `python tool/test_backend_apply.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-apply-wire.json` | 11 existing apply regression groups passed |
| `python tool/test_backend_task_create.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-create-wire.json` | 9 integration groups passed; tasks created through HTTP rather than SQL seeds |
| `python tool/test_backend_http.py` | 2 proxy/redirect isolation tests passed |
| `.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart PATH` for the three wire outputs above | 10 foundation, 32 apply and 126 create/status real replies passed production codec/correlation and title/status checks |
| `.tools/flutter/bin/flutter.bat test test/account_task_validation_test.dart test/domain_test.dart test/local_database_test.dart` | 14 tests passed |
| `.tools/flutter/bin/flutter.bat pub get --enforce-lockfile`; `.tools/flutter/bin/dart.bat run build_runner build` | Passed; lockfile/generated database unchanged |
| `.tools/flutter/bin/dart.bat format --output=none --set-exit-if-changed lib test tool` | 37 files checked, zero changes |
| `.tools/flutter/bin/flutter.bat analyze` | No issues, 38.7 seconds |
| `.tools/flutter/bin/flutter.bat test --reporter expanded` | All 104 tests passed |
| `.tools/flutter/bin/flutter.bat build windows --release` | Passed, 13.5 seconds; compilation only |
| `$env:JAVA_HOME='D:\Projects\DoUrStuff\.tools\jdk\jdk-21.0.12.1+1'; android/gradlew.bat -p android assembleDebug -Ptarget-platform=android-arm64 --no-daemon` | Passed, 54 seconds; existing Kotlin/Gradle deprecation warnings, compilation only |
| `git diff --check`; unchanged SQLite/generated/lockfile diff | Passed |

Additional HTTP coverage includes competing creates, held successors, immutable
completion retry, rejected malformed groups, partial content merge with a status
conflict, batch preflight, receipt expiry, tombstone denial, same-UUID X/Y ownership
and history read/insert RLS. Injected log-write failure rolls back creation and
history as well as receipts/cursors. SQL cleanup checks found zero application
accounts, zero harness-prefix Auth users and zero fault triggers after the runs.
These are local HTTP/server fault tests, not native process-kill/two-device tests.

Official pricing/pausing/database-limit pages were rechecked on 18 October;
the free-tier assumptions remain unchanged in `docs/runbooks/costs.md`. No hosted
resource or paid dependency was introduced.

### Independent review corrections

[PR #3](https://github.com/ipar569/DoUrStuff/pull/3) initially published commit
`a6f7b67b75d9d0dbe35d33261e502a4afe258c8f`. Independent read-only review identified
three P2 issues: unchanged current-base status values appended false history
events; retained history IDs were absent from payload preflight after receipt
expiry; and the wire checker incorrectly required a particular rejection code
when several proposed groups were invalid. The new no-op HTTP regression failed
against migration 004 with `Same current-base value is not another completion
event`, before the fix. That failure is retained here.

Forward migration `20261018000200_status_history_identity.sql` preserves applied
migration 004. It compares status values for history creation and retains exact
original envelopes with history, checking them in whole-batch payload preflight.
Backfill copies only available receipts. Older events with missing receipts stay
intact with unknown originals; their IDs cannot be assigned to new operations,
while consumed original sequences still reconcile without replay. A pre-fix local
dump is retained at `.tools/backend-before-history-fix.sql`. The wire checker
now requires rejection of invalid groups and validates the reported semantic
reason without choosing an artificial priority among multiple errors.

The expanded foundation fixture verifies retained high-water and both kinds of
history across all five migrations inside a rollback-only transaction. New HTTP
checks cover unchanged todo/completed, changed old-sequence payloads, title-only
and status ID reuse across epochs, expired originals and combined invalid groups.
Analyzer/format checks passed after the checker fix (8.2 seconds, 37 files).
The initial PR head's Quality/Android/Windows CI all passed; updated-head CI and
independent re-review must also pass before merge. See the PR timeline for exact
reviewed head and merge evidence, rather than treating the earlier checks as final.

### Resume verification — 19 October 2026

Resumed the same PR/branch with the review fixes intact and no newer remote work.
The previous final-suite process handle was no longer available, so its completion
was not assumed. Docker was stopped again; it was started hidden and the guarded
helper resumed the preserved stack, confirming pinned images and loopback ports.
All five local migration IDs remain recorded; no migration was rewritten or reset.

The same three sequential backend commands above passed 8 foundation, 11 apply
and 11 create/status groups. The foundation run includes the retained-history
upgrade fixture, and create/status includes the three review regressions and
unknown-original recovery. Formatting checked 37 files with zero changes;
the Dart wire checker validated 10 foundation, 32 apply and 136 create/status
replies (178 total). Post-run account, harness-user and fault-trigger counts were zero.
analysis passed in 50.0 seconds; both HTTP isolation tests passed. No production
configuration or data was touched. The 18 October full 104-test Flutter suite and
native compilation remain valid for unchanged application code; only SQL,
integration tools and documentation changed in the review fixes.

`.tools/supabase/supabase.exe db advisors --local --type all --level warn --fail-on error`
reported no issues. Newly available Supabase skills, the official changelog and
function/RLS documentation were reviewed. The pinned backend and explicit grants
remain unchanged; these checks do not close hosted/native acceptance gates.

## Next-session handoff — 19 October 2026, core create/status delivery

- **State:** 3.0 passed; 3.1 still partial. Accepted Phase 2 emulator entry stays
  accepted; physical/native gates remain visible. App account writes stay disabled.
- **Delivered:** five local migrations, registration/pull, core create and
  title/priority/status writes, immutable receipts, contiguous watermarks,
  original recovery envelopes and durable private status history. Relevant new
  files are migrations 004/005, `tool/test_backend_task_create.py` and
  `lib/domain/account_task_validation.dart`. Inspect branch/PR/main before resuming.
- **Next executable work:** complete Phase 3.1 task fields and command validation,
  then remaining entity/relationship/delete/restore commands, snapshots,
  resolution, history transport and retention. Preserve the original bases,
  applied migrations and account-lock ordering. Resolve JSONB NUL/raw-number and
  remaining normalization parity gaps before enabling account writes.
- **Later milestones:** retained SQLite upgrade/profiles, secure native GitHub
  PKCE, real two-client workers and crash recovery, consent/adoption/lifecycle,
  installed device/latency tests, backend CI and recovery rehearsal remain open.
  This increment does not close 3.1 or justify starting Phase 4.
- **External prerequisites:** GitHub OAuth application/provider configuration
  with exact native redirects; secure session and PKCE-verifier persistence;
  a restricted development endpoint reachable from Android and Windows; installed
  two-device access. No hosted project is linked and no device evidence was added.
- **Runtime:** use `python tool/local_backend.py --start`, preserving volumes
  and stopped backup containers. Fresh-host binding setup is still unresolved.

## Description/estimate increment — 19 October 2026

PR #3 merged at `47e9e7aebaa52969260359e1539950d3772f6bf0` after independent
re-review of `f1d45bec7d31286f19499c32c57fc0bea94711f0`, with no remaining
actionable findings and successful Quality/Android/Windows CI. GitHub reported
MERGED and local main was fast-forwarded to the verified remote merge. This
increment starts from that commit on `codex/phase-3-task-description-estimate`.
Remote main was rechecked before continuing; no newer work was displaced.

Forward migration `20261019074608_task_description_estimate.sql` adds optional
description and nullable whole-minute estimate groups to core creation and
independent task edits. Four-group creation remains valid, with missing optional
groups left absent until an explicit edit; no defaults or base revisions are
invented. Supplied create groups remain all-or-nothing. Collisions never merge
optional fields. Status-only commands still reject unrelated groups. Existing
account locks, receipts, retained recovery envelopes, history and watermarks
keep their transactional boundaries. No SQLite schema or client account path
changed.

The CLI's `migration new task_description_estimate` generated the filename.
The candidate compiled and passed validator smoke checks in a rollback-only
transaction before being applied forward. An application-schema dump was saved
to ignored `.tools/backend-before-task-fields.sql`; this is not a restore test.
All six migration IDs were verified after application. Existing containers,
volumes and stopped backups remain intact.

The first task-fields run failed its Unicode preservation assertion. PostgreSQL
held the correct value, but the shared Python command runner decoded its UTF-8
output with Windows CP1252. The runner now explicitly uses UTF-8 for SQL stdin
and subprocess stdout. A regression forces the legacy locale while round-tripping
accented and supplementary characters. After the fix, all five field integration
groups passed. A later wire-check invocation incorrectly supplied three paths
to the single-path CLI and failed with `Expected a synthetic wire fixture path`;
each output was then checked individually and passed. These failures are retained
without treating either failed invocation as successful evidence.

| Exact command/action | Result |
| --- | --- |
| `docker exec supabase_db_dourstuff-local pg_dump -U postgres -d postgres --schema=sync_private --schema=public --no-owner --no-privileges` | Pre-migration dump saved locally, not committed |
| `.tools/supabase/supabase.exe migration up --local --network-id dourstuff-local` | Migration 006 applied; six IDs verified |
| `python tool/test_backend_foundation.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-foundation-wire.json` | 8 integration groups passed, including empty/retained-data upgrade through all six migrations |
| `python tool/test_backend_apply.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-apply-wire.json` | 11 integration groups passed |
| `python tool/test_backend_task_create.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-create-wire.json` | 11 integration groups passed |
| `python tool/test_backend_task_fields.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-fields-wire.json` | 5 integration groups passed |
| `.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart PATH`, once per output above | 10 + 32 + 136 + 42 = 220 real replies passed production codec/correlation and semantic checks |
| `python tool/test_backend_http.py` | 3 tests passed: proxy isolation, redirect denial and UTF-8 subprocess regression |
| `.tools/flutter/bin/flutter.bat test test/account_task_validation_test.dart test/domain_test.dart test/local_database_test.dart` | 16 tests passed |
| `.tools/flutter/bin/flutter.bat pub get --enforce-lockfile`; `.tools/flutter/bin/dart.bat run build_runner build` | Passed; lockfile/generated database unchanged |
| `.tools/flutter/bin/dart.bat format --output=none --set-exit-if-changed lib test tool` | 37 files checked, zero changes |
| `.tools/flutter/bin/flutter.bat analyze` | No issues, 6.8 seconds |
| `.tools/flutter/bin/flutter.bat test --reporter expanded` | All 106 tests passed |
| `.tools/flutter/bin/flutter.bat build windows --release` | Passed, 11.8 seconds; compilation only |
| `$env:JAVA_HOME='D:\Projects\DoUrStuff\.tools\jdk\jdk-21.0.12.1+1'; android/gradlew.bat -p android assembleDebug -Ptarget-platform=android-arm64 --no-daemon` | Passed, 43 seconds; existing Kotlin/Gradle and SDK XML warnings, compilation only |
| `.tools/supabase/supabase.exe db advisors --local --type all --level warn --fail-on error` | No issues found |
| Post-run SQL account, harness Auth-user and fault-trigger counts | All zero |

The new HTTP fixtures cover whitespace/supplementary-character preservation,
create collisions and immutable retries, terminal semantic rejection without
partial creation, nullable clearing, completion/edit in both commit orders,
accepted history snapshots, partial conflicts with held successors and original
bases, and X/Y isolation. SQL and Dart tests verify the 100,000-UTF-16-unit domain
limit; HTTP tests separately verify exact 64-KiB operation acceptance and one-byte
overflow with no progress. These are distinct limits: large valid guest
descriptions cannot yet be represented in one account operation. Resolve the
transport/representation contract before enabling writes or adoption; never
truncate the guest content. JSONB NUL/raw-number parity also remains open.

Checks describe this increment's working tree. The PR timeline records exact
reviewed commits, review corrections, CI and eventual merge state. Local backend
evidence is not installed native authentication, replication or recovery evidence.

## Next-session handoff — 19 October 2026, description/estimate delivery

- **State:** 3.0 complete, 3.1 partial; accepted emulator entry is unchanged.
  The application remains guest-only and Phase 4 remains gated.
- **Delivered:** six local migrations support registration/pull, core creation,
  title/priority/status/description/estimate edits, original recovery envelopes,
  immutable receipts, durable watermarks and private status history. Inspect the
  branch/PR/main state before resuming and preserve any subsequent changes.
- **Next executable work:** remaining task due/relationship/delete/restore and
  other entity semantics; complete validation/representation parity. Continue
  account storage/secure native PKCE and the first real two-client slice in the
  delivery plan, then full snapshots/resolution/history transport/retention.
  Applied migrations stay immutable; fixes must be forward migrations.
- **Account activation blockers:** oversized valid descriptions, JSONB NUL/raw
  numeric representation, remaining normalization/command gaps, unimplemented
  client replication and recovery. No account writes or guest upload may be enabled.
- **External prerequisites:** configured GitHub OAuth provider with exact native
  redirects; tested secure session and PKCE-verifier persistence; a restricted
  development endpoint reachable from Android and Windows; installed two-device
  access. No hosted project or device evidence was added by this increment.
- **Later acceptance:** retained SQLite upgrade, crash/retry recovery,
  consent/adoption/lifecycle/deletion, installed two-device and latency results,
  real backend CI and recovery rehearsal remain open. Production execution is
  still unauthorized.
- **Runtime:** `python tool/local_backend.py --start` resumes the repaired stack.
  Preserve all volumes and stopped backup containers. Run the four backend suites
  sequentially; the foundation suite temporarily rebuilds the application schema
  in a rollback-only transaction. Use one wire-file argument per Dart check.

## Atomic due increment — 20 October 2026

Initial Git/GitHub inspection confirmed the clean description/estimate branch
at `8dc5a5b1d77e7207e527bd2efb38895ff95725e2`, PR #4 open, and remote main at
`47e9e7aebaa52969260359e1539950d3772f6bf0`. Independent review subagent
`/root/review_pr4` reviewed the actual diff and reported no actionable findings.
The [review record](https://github.com/ipar569/DoUrStuff/pull/4#issuecomment-6285306029)
records the exact SHA, scope and checks. GitHub had no unresolved threads or
blocking reviews; Quality/Android/Windows CI all passed for that head. PR #4
was squash-merged with the expected-head guard at
`5e5478f1f9bf72297d365f00e4316122556a54f1`, verified MERGED and present on
remote main. Local main was fast-forwarded before creating
`codex/phase-3-task-due`; no newer or unrelated work was displaced.

Forward migration `20261020070017_task_due.sql` adds optional due creation and
independent atomic due edits. Strict none/date/timed shapes reject hybrids,
missing/extra members, impossible civil dates, unknown zone names and mismatched
instants. Civil years are 1–9999. Timed values preserve original wall time,
zone and fixed instant, accept either fold occurrence and advance gaps by their
size. The 342-zone vocabulary is pinned to timezone 0.11.1/default data.
Four-group creation remains compatible: omitted due stays absent until an
explicit edit. Clearing uses `{kind: "none"}`. Invalid due rejects the whole
command; same-group conflicts never combine parts of two deadlines. Original
bases/immutable payloads, account locks, receipts, status history and contiguous
watermarks are preserved. SQLite schema v1 and the guest application path remain
unchanged; no account write or upload path is enabled.

The CLI generated migration 007. All 763 exported client/SQL cases agreed in a
rollback-only candidate transaction before local application. A pre-apply
application-schema/data dump is retained in ignored
`.tools/backend-before-task-due.sql`; no restore rehearsal is implied. All seven
migration IDs were verified locally. The foundation suite also verifies retained
due values, history/original payloads and device watermarks through the upgrade.
Prior applied migrations were not edited.

Failures and diagnostic limits retained:

- Initial sandbox GitHub CLI access failed to connect; authorized network
  escalation succeeded and preserved the verified branch/PR state.
- Reviewer's `python -B tool/test_backend_http.py` passed the UTF-8 regression
  but two loopback tests failed with `WinError 10013` in the sandbox. Parent
  rerun of the same command with loopback permission passed all three.
- Initial `python tool/local_backend.py --start` failed because Docker's daemon
  pipe was absent. After checking help, `docker desktop start --detach` and the
  guarded restart passed. Nine pinned services and actual loopback-only bindings
  were verified; volumes and stopped backup containers were preserved.
- The web reader could not decode the official Markdown documentation content
  type; direct `Invoke-WebRequest` retrieved the changelog and SQL function
  security guidance. No provider upgrade or hosted resource was created.
- `/usr/share/zoneinfo/tzdata.zi` was absent in the PostgreSQL image. `pg_config`
  identifies PostgreSQL's bundled data directory; no exact IANA server version
  was established. The pinned Dart package documents 2025c. Passing current
  zone/gap/fold fixtures does not prove all historical/future offset parity.
- `.tools/flutter/bin/flutter.bat build apk --debug --target-platform android-arm64`
  failed because Flutter selected Java 11.0.15 despite process `JAVA_HOME`
  pointing to the existing JDK 21. Gradle 9.3.1 requires at least Java 17.
  The documented direct Gradle route below avoids changing global Flutter/JDK
  configuration; the failed Flutter invocation remains failed evidence.

| Exact command/action | Result |
| --- | --- |
| `python tool/local_backend.py --start` after Docker startup | Nine pinned services running; eight healthchecks healthy; loopback-only publishing |
| `.tools/supabase/supabase.exe migration new task_due` | Generated migration 007 filename |
| `docker exec supabase_db_dourstuff-local pg_dump -U postgres -d postgres --schema=sync_private --schema=public --no-owner --no-privileges` | Saved local pre-apply dump; not a tested restore |
| `.tools/supabase/supabase.exe migration up --local --network-id dourstuff-local`; `.tools/supabase/supabase.exe migration list --local` | Applied only 007; all seven IDs matched |
| `.tools/flutter/bin/dart.bat run tool/export_due_fixtures.dart .tools/due-fixtures.json` | 763 cases across 342 zone names, using the pinned client resolver |
| `python tool/test_backend_task_due.py --supabase .tools/supabase/supabase.exe --fixtures .tools/due-fixtures.json --wire-output .tools/backend-due-wire.json` | 7 real integration groups passed |
| `python tool/test_backend_foundation.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-foundation-wire.json` | 8 integration groups passed, including rollback-only empty/retained application-schema upgrade |
| `python tool/test_backend_apply.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-apply-wire.json` | 11 integration groups passed |
| `python tool/test_backend_task_create.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-task_create-wire.json` | 11 integration groups passed |
| `python tool/test_backend_task_fields.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-task_fields-wire.json` | 5 integration groups passed |
| `.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart PATH`, one invocation per output above | 10 + 32 + 136 + 42 + 74 = 294 real replies passed production codec/correlation/semantic validation |
| `python -B tool/test_backend_http.py` with loopback access | 3 helper tests passed |
| `.tools/flutter/bin/flutter.bat test test/account_due_validation_test.dart test/account_task_validation_test.dart test/domain_test.dart test/local_database_test.dart` | 18 tests passed |
| `.tools/flutter/bin/flutter.bat pub get --enforce-lockfile`; `.tools/flutter/bin/dart.bat run build_runner build` | Passed; generated database, lockfile and retained schema snapshots unchanged |
| `.tools/flutter/bin/dart.bat format --output=none --set-exit-if-changed lib test tool` | 39 files, no changes |
| `.tools/flutter/bin/flutter.bat analyze` | No issues, 32.3 seconds |
| `.tools/flutter/bin/flutter.bat test --reporter expanded` | All 108 tests passed |
| `.tools/flutter/bin/flutter.bat build windows --release` | Passed, 37.3 seconds; compilation only |
| `$env:JAVA_HOME='D:\Projects\DoUrStuff\.tools\jdk\jdk-21.0.12.1+1'; android/gradlew.bat -p android assembleDebug -Ptarget-platform=android-arm64 --no-daemon` | Passed, 50 seconds; existing Kotlin/Gradle deprecation and SDK XML warnings retained; compilation only |
| `.tools/supabase/supabase.exe db advisors --local --type all --level warn --fail-on error` | No issues before and after application |
| Post-suite account, harness Auth-user and fault-trigger SQL counts | All zero |

The due suite exercises optional creation/collisions/retries; invalid creation
without partial state; completion/edit in both orders and canonical history;
competing due edits in both orders and simultaneous HTTP requests; equivalence,
partial conflicts, held successors, original bases, clearing, invalid-command
atomicity, receipt expiry, X/Y isolation and injected transaction failure.
This is real local backend evidence, not installed native sync/auth acceptance.
The PR timeline records reviewed SHA, findings/fixes, CI and actual merge state.

## Next-session handoff — 20 October 2026, atomic due delivery

- **Milestone:** 3.0 complete; 3.1 partial. Emulator entry acceptance remains
  accepted; physical/native gates remain open. The app stays guest-only and
  Phase 4 stays gated.
- **Delivered:** seven forward local migrations, registration/pull, core create
  plus title/priority/status/description/estimate/due, immutable receipts,
  original recovery envelopes, watermarks and private status history. Relevant
  new files are migration 007, `tool/test_backend_task_due.py`,
  `tool/export_due_fixtures.dart` and `test/account_due_validation_test.dart`.
  Inspect Git/GitHub before resuming and reuse an open task PR if present.
- **Next executable work:** relationship/parent dependency and delete/restore
  semantics, then other Phase 2 entities/commands; history transport, snapshots,
  explicit resolution and retention remain unfinished. Preserve applied
  migrations; use forward fixes. Complete representation/normalization parity
  before enabling any account commands or adoption.
- **Representation gates:** valid 100,000-UTF-16-unit descriptions can exceed
  the 64-KiB operation cap; JSONB NUL/raw numbers and normalization remain open.
  Pin/reconcile complete client/server historical/future timezone rules beyond
  the tested due cases. Do not truncate or alter guest content/deadlines.
- **External prerequisites:** GitHub OAuth application/provider configuration
  and exact Android/Windows redirects; verified secure session and PKCE-verifier
  storage; a restricted development endpoint reachable from both installed
  clients; Android and Windows installed-device access. No hosted project is
  linked. Secrets remain outside the repo/chat/app.
- **Later milestones:** retained SQLite upgrade/profiles, native secure GitHub
  PKCE, complete two-client slice and crash/retry behavior, snapshots/conflict UI,
  consent/adoption/lifecycle/recovery export/deletion, measured two-device
  latency, backend CI and recovery rehearsal remain open.
- **Runtime:** start Docker Desktop if its daemon is unavailable, then use
  `python tool/local_backend.py --start`. Preserve volumes and stopped backup
  containers. Run all five backend suites sequentially and one wire file per
  Dart checker invocation. No production execution, release or publication was
  authorized or performed.

## Independent review correction — 21 October 2026

Resumed clean branch `codex/phase-3-task-due` at
`5937ce6764486fbc077c7427ba20f15134eb6c91`; remote main remained `5e5478f`.
Opened [PR #5](https://github.com/ipar569/DoUrStuff/pull/5). Independent reviewer
`/root/review_pr4` found one P2 issue in migration 007: the gap fallback also
accepted ordinary wall times after the gap. For example Auckland
`2026-09-27T03:30` incorrectly accepted `2026-09-26T15:30Z`, whose actual wall
time is 04:30. The correct exact instant is 14:30Z. No additional actionable
findings were reported for that head. Its Quality/Android/Windows CI passed,
but it was not merged with the finding unresolved.

Read-only SQL reproduced all four initial regression cases (Auckland, New York,
Lord Howe and Apia). Forward migration
`20261021055441_task_due_gap_validation.sql` requires that no exact wall
occurrence exists before accepting a gap-shift candidate. Applied migration
007 remains unchanged. The initial 771-case candidate passed a rollback-only
SQL check; expanding the boundary/ordinary-time matrix produced 785 agreeing
SQL/client cases after application. The pre-fix dump is retained in
`.tools/backend-before-due-gap-fix.sql`, without a restore claim.

Host runtime failure: the daemon was initially stopped. Docker Desktop startup
restored the internal services, but `python tool/local_backend.py --start` and
direct `docker start` failed to bind 54321–54324 with a socket access error.
`netsh interface ipv4 show excludedportrange protocol=tcp` showed those ports
inside exclusions 54224–54323 and 54324–54423. All nine containers run on their
existing isolated network; the four actual published binding lists are empty.
The guard's health/exposure result alone does not establish host HTTP access.
No containers were replaced, volumes removed, stopped backups restarted or
system port reservations changed.

The internal Auth health route returned HTTP 200 from the existing database
container through Kong. Ignored `.tools/run_backend_inside.py` substitutes only
the harness HTTP transport with `docker exec` curl to that fixed internal route;
it keeps real Auth/JWT/Kong/PostgREST/PostgreSQL behavior, passes credentials and
bodies through stdin, and disables proxies/redirects. This is internal-network
evidence; the normal host-loopback path remains blocked. The final migration
was applied via `.tools/apply_due_review_fix.py`: dump, then function replacement
and exact migration source record in one local psql transaction with the
migration table locked. All eight IDs and exact source retention were checked.
Normal host CLI/advisor verification must wait for the reserved ports to become
available; no production migration was executed.

Quality after the correction: 19 targeted tests passed; formatting checked 39
files unchanged; analysis found no issues (37.2 seconds); the full Flutter suite
passed 109 tests. After expanding transition-boundary cases, all three tests in
`test/account_due_validation_test.dart` passed again. Native application code
is unchanged by the review fix; the PR checks must still pass for the final head.
The initial 108-test/42-group/294-reply results above are retained as historical
evidence, not substituted for the affected review checks below.

## Review-fix verification and next-session handoff — 22 October 2026

Resumed at `5937ce6764486fbc077c7427ba20f15134eb6c91` with the migration 008
review correction and its tests/docs still uncommitted. PR #5 remained open;
its passing checks applied only to that original head. The interrupted internal
HTTP run had no retained completion result or output file, so it is not counted
as a passing suite. The first resumed attempt failed because Docker was stopped.
After `docker desktop start --detach`, `python tool/local_backend.py --start`
succeeded. Kong's actual binding was `127.0.0.1:54321` and a proxy-free request
to `/auth/v1/health` returned 200. Containers, volumes, migration history and
stopped backups were preserved; no host reservations were changed.

Affected checks on the final review-fix working tree, through normal host
loopback (no internal transport substitution):

| Command | Result |
| --- | --- |
| `python tool/test_backend_task_due.py --supabase .tools/supabase/supabase.exe --fixtures .tools/due-fixtures.json --wire-output .tools/backend-due-review-wire.json` | 7 groups passed, including 785 cases/342 zones, same-group concurrency, rollback, retained originals and X/Y isolation |
| `python tool/test_backend_foundation.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-foundation-review-wire.json` | 8 groups passed; empty/retained-data upgrade through all 8 migrations rolled back safely; real RLS and account lifecycle denial passed |
| `dart run tool/check_backend_wire.dart .tools/backend-due-review-wire.json` | 75 real responses passed |
| `dart run tool/check_backend_wire.dart .tools/backend-foundation-review-wire.json` | 10 real responses passed |
| `.tools/supabase/supabase.exe migration list --local` | All 8 local/applied IDs matched |
| `.tools/supabase/supabase.exe db advisors --local --type all --level warn --fail-on error` | No issues found |
| `git diff --check` before staging | Passed for tracked files; did not include the new migration |
| `git diff --cached --check` after staging | Flags one extra blank line at EOF in already-applied migration 008; retained verbatim to preserve the applied source. No other whitespace errors |

These runs cleaned their synthetic accounts. Five older harness accounts from
the interrupted run remained; their exact `foundation-<32 hex>@example.invalid`
pattern and lack of other owners were verified before using the normal local
Auth cleanup path. Final counts: account rows 0, harness Auth users 0, injected
test triggers 0. No real account data was used. The CLI advertised 2.121.0;
the tested 2.120.0 pin was retained. The previous 109-test Flutter run and final
three-test boundary run remain the local quality evidence for this correction.

- **Delivery:** PR #4 merged at `5e5478f1f9bf72297d365f00e4316122556a54f1`.
  PR #5 delivers atomic none/date/timed due creation/edits and forward migrations
  007/008. The latest independent review must cover the correction's committed
  SHA; its exact SHA, disposition, final CI and merge result are recorded in the
  PR timeline. Never infer completion from the old head's passing checks.
- **Next executable action:** finish PR #5's updated independent review and
  Quality/Android/Windows checks, then merge only that reviewed head. Once merged,
  fetch main and start a fresh task branch for relationship/parent dependencies
  and delete/restore semantics, following the earliest unfinished delivery-plan
  item. Do not modify any of the eight applied migrations.
- **Activation gates:** 100,000-UTF-16-unit descriptions versus the 64-KiB
  operation cap; JSONB NUL/raw-number and normalization parity; full historical/
  future timezone-data parity. Preserve guest content and original immutable
  payloads. Account storage, secure native GitHub PKCE, complete two-client sync,
  snapshots/conflict recovery, consent/adoption/lifecycle and measured acceptance
  remain unfinished. Phase 3.1 is partial; app guest-only; Phase 4 gated.
- **External prerequisites:** GitHub OAuth/provider configuration with exact
  Android/Windows redirect allowlists; verified secure session/PKCE-verifier
  storage; a restricted development endpoint reachable from both installed
  clients; installed Android and Windows devices. No hosted project is linked.
  Restored PC loopback access does not establish device access. Physical/native,
  two-device latency and recovery gates remain open; accepted Phase 2 emulator
  entry is unchanged. No production migration, deployment or release authorized.

## Task deletion increment — 22 October 2026

PR #5 merged at `d6888063c973f6e011701da947fc6bfc868256ad` after independent
re-review of `9c31ea88a59559df39512fdd2d288c5070cf2459` and passing
Quality/Android/Windows CI. Remote and clean local main matched. This increment
started from that commit on fresh branch `codex/phase-3-task-delete`; no newer
remote work or open PR was present. The small scope is task deletion, a
visibility prerequisite for later parent/child commands.

Forward migration `20261021223308_task_delete.sql` (009) adds `task.delete`
with only an existence true-to-false patch using observed/predecessor bases.
Deletion retains canonical task content and does not fabricate status history.
Edits arriving after deletion go to recovery with original immutable envelopes;
edits arriving before deletion remain in retained canonical content. Competing
deletes keep the first accepted deletion identity. The private, forced-RLS
`task_deletions` ledger retains exact deletion operations, revisions and trusted
server timestamps; the RPC role can select/insert but cannot update/delete it.
Receipt/log expiry cannot authorize replay or reuse of a deletion operation ID.
Visibility, ledger, receipt, recovery, cursor and watermark commit atomically.
All eight earlier applied migrations remain unchanged. No SQLite/app code changed.

Local setup used `python tool/local_backend.py --start` on the preserved stack.
The pinned CLI's `migration new task_delete` generated the new filename. Before
application, the existing empty/retained-data fixture compiled all nine
migrations in a rollback-only transaction, and a real synthetic-owner deletion
RPC smoke test applied then rolled back safely. The first ignored upgrade-helper
attempt failed with a missing Python `json` import; correcting that local helper
made the check pass. This was a helper failure, not a migration reset.
`.tools/backend-before-task-delete.sql` preserves the pre-apply dump; no restore
rehearsal is claimed. `migration up --local --network-id dourstuff-local` applied
only 009, and `migration list --local` matched all nine IDs. Database advisors
reported no issues. Supabase changelog/function-security guidance was checked;
no provider/CLI upgrade occurred. The web reader rejected the Markdown changelog
content type; a direct read succeeded. Existing PostgreSQL 17.11 pins remain.

Local verification before PR review:

- `flutter test test/domain_test.dart test/local_database_test.dart test/account_sync_policy_test.dart`:
  18 tests passed; no guest behavior/schema change.
- `python tool/test_backend_task_delete.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-delete-wire.json`:
  six groups passed on the initial run, including both delete/edit orders,
  concurrent deletes, duplicate/lost-response retries, receipt/log expiry,
  original identity reuse, invalid/stale/held/missing commands, restore gating,
  X/Y isolation and injected transaction rollback. A second run with direct
  cross-owner ledger insertion denial and no-update/delete privilege assertions
  also passed all six groups.
- `dart run tool/check_backend_wire.dart .tools/backend-delete-wire.json`:
  35 real replies passed on the initial run.
- `.tools/supabase/supabase.exe db advisors --local --type all --level warn --fail-on error`:
  no issues found after local application.

All five previous backend suites ran sequentially against migration 009:
`test_backend_foundation.py` 8 groups, `test_backend_apply.py` 11,
`test_backend_task_create.py` 11, `test_backend_task_fields.py` 5 and
`test_backend_task_due.py` 7 (785 due cases/342 zones). Each used
`--supabase .tools/supabase/supabase.exe --wire-output .tools/backend-<suite>-delete-regression-wire.json`;
the due suite also used `--fixtures .tools/due-fixtures.json`. Each output was
checked separately with `dart run tool/check_backend_wire.dart`: respectively
10, 32, 136, 42 and 75 real replies passed. With the final deletion suite,
this is **48 integration groups and 330 real response validations**.
`python tool/test_backend_http.py` passed all three tests. Final synthetic
account/Auth-user, injected-trigger and deletion-ledger row counts were zero.
Final staged diff and relative Markdown links are checked before commit.
App/native source is unchanged; applicable Quality/Android/Windows PR CI must
still pass on the independently reviewed head.

### Next-session handoff

This remains Phase 3.1 partial, with a guest-only app. The task branch must finish
independent review and Quality/Android/Windows checks before guarded merge;
record the exact reviewed SHA, findings/disposition and actual merge commit in
the PR timeline. Do not infer a merge from this pre-merge document.

Next implementation: exact-deletion restore preconditions and 30-day retained
content rules, plus parent/child relationship semantics; then remaining commands,
account storage/secure native GitHub PKCE, complete two-client sync, snapshots/
conflict recovery, consent/adoption/lifecycle and installed acceptance. Restore,
content expiry, child visibility and their device/UI paths are not implemented
by this increment. All nine applied migrations must remain unchanged.

Activation gaps remain: 100,000-UTF-16-unit descriptions versus the 64-KiB cap;
JSONB NUL/raw-number and normalization parity; historical/future timezone-data
parity. Never truncate or silently upload guest data. External prerequisites
remain GitHub OAuth/provider configuration with exact Android/Windows redirects,
verified secure session/PKCE-verifier storage, a restricted development endpoint
reachable from both installed clients, and installed Android/Windows devices.
No hosted project is linked. PC loopback is not device-access evidence. Phase 2
emulator entry remains accepted; physical/native, two-device latency and recovery
gates remain open. Phase 4 stays gated. No production deployment/migration or
release was authorized or performed.

## Exact-deletion restore increment — 22 October 2026

PR #6 merged at `e6a25eec8fba98169b75318ed86e2852369911df`, after independent
review of `21f6b3de3af9f5194669179e083d9369e1f790f4` and successful
Quality/Android/Windows CI. Remote and clean local main matched. This increment
starts from that main on `codex/phase-3-task-restore`; no open PR or newer remote
work was present at inspection.

Forward migration `20261022043755_task_restore.sql` (010) adds exact-deletion
restore only. Preconditions require the current deletion operation ID/revision,
observed false base, deleted visibility, matching same-owner deletion ledger,
retained core content and trusted server age strictly below 720 elapsed hours.
Future deletion timestamps fail closed. The window uses current server time
after the account lock, not client provenance or transaction-start time. The
helper uses an hour duration independent of session DST/calendar arithmetic.

Successful restore changes only existence. It preserves content, old deletion
identity, status history and unresolved late-edit candidates. A private forced-
RLS restoration ledger records original operation, revision, deletion link and
server timestamp atomically with shadow/receipt/log/progress. The RPC role has
no update/delete permission. Old successful retries cannot revive later deletes;
expired receipts/logs do not permit restore-ID reuse. No previous migration,
SQLite schema or app/native source was changed. Physical content purging,
parent/child visibility and account UI remain unimplemented.

`python tool/local_backend.py --start` passed on the existing preserved stack.
Pinned CLI `migration new task_restore` created 010. Candidate checks included
all ten migrations in the rollback-only empty/retained-data fixture and a
real-owner restore RPC plus ledger write rolled back safely against an existing
deleted task. `.tools/backend-before-task-restore.sql` preserves the pre-apply
local dump; this is not a restore rehearsal. `migration up --local --network-id
dourstuff-local` applied only 010. Local migration history matched all ten IDs;
`db advisors --local --type all --level warn --fail-on error` found no issues.
The previously checked Supabase changelog/function-security guidance and the
Postgres foreign-key-index/RLS skill guided this increment; pins were retained.

Retained failures: the first unprivileged `migration new --help` invocation
failed with EPERM writing the CLI telemetry temp file; approved execution of
help and migration creation succeeded. The first restore suite passed three
groups then failed its malformed-command assertion: `task.edit` plus existence
hits the existing `unsupportedProtocol` capability gate (HTTP 200), not HTTP 400.
A diagnostic confirmed all four cases left state unchanged. The structural
fixture was corrected to `task.delete` carrying an illegal restore field;
missing/extra/zero-revision preconditions and the corrected case then returned
HTTP 400 with no writes. No applied SQL was changed to mask the test failure.

Local verification for the restore increment:

- `flutter test test/domain_test.dart test/local_database_test.dart test/account_sync_policy_test.dart`:
  18 tests passed.
- `python tool/test_backend_task_restore.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-restore-wire.json`:
  all 8 groups passed after the fixture correction. Coverage includes visibility-
  only restore, unresolved late edits, immutable retry/expiry, repeated delete/
  restore cycles, stale undo, competing restores, both restore/edit orders,
  malformed/semantic rejection, exact 30-day boundaries in three timezones,
  future/missing-content/identity denial, a real account-lock expiry race, X/Y
  raw REST and direct RLS denial, immutable ledger grants and injected rollback.
- `dart run tool/check_backend_wire.dart .tools/backend-restore-wire.json`:
  57 real responses passed.
- `python tool/test_backend_http.py`: all 3 tests passed.

All six prior backend suites also passed sequentially on migration 010:
foundation 8 groups, apply 11, task_create 11, task_fields 5, task_delete 6 and
task_due 7 (785 cases/342 zones). They used the pinned local CLI, with wire
outputs `.tools/backend-<suite>-restore-regression-wire.json`; due also used
`--fixtures .tools/due-fixtures.json`. Separate Dart wire-checker invocations
passed 10, 32, 136, 42, 35 and 75 replies respectively. With restore, the total
is **56 integration groups and 387 real response validations**. The existing
deletion harness now checks that milestone creation remains capability-gated,
since restore is supported. Final account/Auth-fixture, injected-trigger and
both lifecycle-ledger counts were zero. Relative Markdown links passed; the
staged diff is checked before commit. App/native sources are unchanged; final
Quality/Android/Windows CI is still required for the reviewed PR head.

### Next-session handoff

Finish this branch's independent review and final-head
Quality/Android/Windows CI before guarded merge; record the reviewed SHA,
findings/disposition and actual merge in its PR timeline. Preserve all ten
applied migrations. The next implementation is parent/child relationship
semantics, then remaining entities/commands and retention/snapshot integration.
Physical content purging, full recovery UI and child visibility are not delivered
by this restore slice. Account storage, secure native GitHub PKCE, two-client
replication, consent/adoption/lifecycle and installed acceptance remain open.

The app stays guest-only; Phase 3.1 remains partial and Phase 4 gated. Existing
activation gaps remain 100,000-UTF-16-unit descriptions versus the 64-KiB cap,
JSONB NUL/raw-number and normalization parity, and historical/future timezone
parity. Never truncate or silently upload guest content. External prerequisites
remain GitHub OAuth/provider configuration with exact Android/Windows redirects,
verified secure session/PKCE-verifier storage, a restricted development endpoint
reachable from both installed clients, and installed Android/Windows devices.
No hosted project is linked. PC loopback does not prove device reachability.
Accepted Phase 2 emulator entry stays accepted; physical/native, latency and
recovery gates remain open. No production migration/deployment or release occurred.

## Milestone creation and parent dependencies — 23 October 2026

PR #7 was independently reviewed at `336391f37e02b503b80fe6b2ba96047859afe838`
with no actionable findings. Quality/Android/Windows CI passed, including 109
Flutter tests. Its guarded squash merge is `587d689adf0d87efc14eeb54718645f49badaf12`,
verified on remote main and the clean local checkout. The prior handoff's
review/merge step is complete; details are retained in the PR timeline.

The next increment starts from that main commit on
`codex/phase-3-milestone-create`. Forward migration 011,
`20261022204009_milestone_create.sql`, adds only `milestone.create` and parent
relationship enforcement. All ten previously applied migrations remain unchanged.
The command requires absent bases for title, nullable completion timestamp,
existence true and immutable parent task UUID. Parent dependency receipts bind
exact owner/device/operation/sequence/entity/existence under the account lock.
Parent conflict holds every child group; missing/expired/rejected/deleted evidence
preserves every original group for recovery. Later unrelated commands advance.

Private forced-RLS `milestone_shadow` has an owner-qualified indexed parent
foreign key and retains exact creation envelopes beyond receipt/log expiry.
Whole-entity collisions cannot reparent or merge fields. The private visibility
helper requires both parent and child existence; parent delete/restore does not
rewrite child state. Pull keeps canonical records, so future account projection
must combine parent/child visibility. A SQL-only independent child tombstone
fixture proves parent restore preserves it; milestone deletion is not delivered.
No local schema, retained snapshots, production dependencies or app behavior changed.

The first `python tool/local_backend.py --start` failed because Docker Desktop's
Linux-engine named pipe did not exist. Starting the installed Docker Desktop
runtime, then rerunning the guarded command, verified nine existing pinned
services, eight Docker healthchecks and loopback-only bindings. Volumes and
stopped pre-loopback backup containers were preserved. The pinned CLI remains
2.120.0. Its `migration new --help`, `db dump --help` and `migration up --help`
were checked before use. The Supabase changelog and function-security guidance
were rechecked; no dependency/provider upgrade was made.

Before application, rollback-only checks compiled all eleven migrations,
preserved the existing watermark/history/due fixture, and exercised a real-owner
parent/child creation RPC followed by rollback. Separate pre-apply dumps are
`.tools/backend-before-milestone-create-schema.sql` and
`.tools/backend-before-milestone-create-data.sql`. These are not restore-rehearsal
evidence. `migration up --local --network-id dourstuff-local` applied only 011.
`migration list --local` matched all eleven IDs; `db advisors --local --type all
--level warn --fail-on error` reported no issues.

Retained integration failure: the first milestone run passed four groups, then
its unsupported-command check got HTTP 400 instead of `unsupportedProtocol`.
The fixture builder shared the parent's entity dictionary; an earlier malformed
child case had changed that parent too. Deep-copying the dependency entity fixed
the harness without changing applied SQL. The complete nine-group suite then
passed with 112 Dart-validated real replies. A subsequent shared golden fixture
adds one registration; the final regression totals below supersede that count.

Targeted local verification: `flutter test test/domain_test.dart
test/local_database_test.dart test/account_sync_policy_test.dart` passed 18 tests
before the new golden test. Afterwards `flutter test
test/account_sync_policy_test.dart` passed all 7 policy tests. The shared
`test/fixtures/account-protocol-v2-milestone.json` checks kind-qualified identical
UUIDs, signed completion time, exact dependency binding and immutable child
payloads in Dart and real HTTP. The wire checker also compares completion
validity against Dart's native-range timestamp rules.

Final local regression on migration 011 ran all eight suites sequentially:

- `python tool/test_backend_<suite>.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-<suite>-milestone-regression-wire.json`
  for foundation (8 groups), apply (11), task_create (11), task_fields (5),
  task_due (7), task_delete (6), task_restore (8), milestone_create (9).
  The due invocation additionally used `--fixtures .tools/due-fixtures.json`
  and passed all 785 cases across 342 zones. **65 groups passed**.
- `dart run tool/check_backend_wire.dart` for each output validated respectively
  10, 32, 136, 42, 75, 35, 57 and 113 replies: **500 real responses passed**.
- `python tool/test_backend_http.py`: all 3 HTTP/encoding tests passed.
- `flutter pub get --enforce-lockfile`, `dart run build_runner build`, generated
  Dart diff check, `dart format --output=none --set-exit-if-changed lib test tool`,
  `flutter analyze` (no issues, 33.9 seconds), and `flutter test` all passed:
  **110 Flutter tests**. Commands used the pinned ignored `.tools/flutter/bin`
  SDK on this host. No generated schema/Dart or lockfile changes resulted.
- Changed Markdown relative links and `git diff --check` passed. Synthetic account,
  Auth-fixture, milestone and injected-trigger counts returned to zero.

Final-head Quality/Android/Windows CI and independent review remain required
before merge; record the exact reviewed SHA, findings/disposition and actual
merge in the PR timeline. Local results above precede the documentation-only
handoff update and do not claim installed-platform acceptance.

### Next-session handoff — 23 October 2026

Finish this branch's independent review, final-head CI and guarded merge first.
Preserve all eleven applied migrations and the repaired stack/backup containers.
Then start a fresh task branch from current main for milestone title/completion
edits, deletion and task milestone ordering, followed by tags/memberships and
remaining commands. Parent/child canonical data is available to pull, but native
account projection, history transport, snapshot/retention/resolution, account
storage/PKCE and the complete two-client slice remain unfinished.

The app stays guest-only, Phase 3.1 partial and Phase 4 gated. Before activation,
resolve 100,000-UTF-16-unit descriptions versus the 64-KiB operation cap, JSONB
NUL/raw-number and normalization parity, and historical/future timezone parity.
Never truncate or silently upload guest content. External prerequisites remain
GitHub OAuth/provider configuration with exact Android/Windows redirects,
verified secure session and PKCE-verifier storage, a restricted development
endpoint reachable by both installed clients, and installed Android/Windows
devices. No hosted project is linked; PC loopback does not establish device
reachability. Physical/native, latency and recovery gates remain open without
reopening accepted Phase 2 emulator entry. No production deployment/migration
or release occurred.

## Milestone edits and deletion — 23 October 2026

PR #8 merged as `09256420428e2e53045b5ff19f2ec9358cb49b91`, verified on remote
main and the clean local checkout. Its first independent review attempt hit a
usage limit and was not counted as complete. The resumed independent review
of `d99fa5ae2408ea205fc1d544e6cae20dc3c7a179` found no actionable findings;
Quality/Android/Windows CI passed, including 110 Flutter tests. The PR timeline
records exact review and merge evidence, completing the prior handoff step.

This next increment starts from that main commit on
`codex/phase-3-milestone-edit-delete`. Forward migration 012,
`20261023083413_milestone_edit_delete.sql`, adds independent milestone title/
completion edits and explicit deletion. All eleven earlier applied migrations
remain unchanged. Original creation envelopes, parent links and owner columns
remain immutable; only fields/deletion-ID columns gain update permission.

Edit comparisons retain observed revisions/values and exact same-child
predecessors. Different fields merge, same-field conflicts remain recoverable,
and invalid command mixtures reject atomically. Hidden child/parent edits go to
recovery before equivalence. A held child create may have no row; its causal
edit/delete successors remain held, while missing evidence goes to recovery
without fabricating a row. Later unrelated sequences continue.

Child deletion compares its own existence even if the parent is hidden, ensuring
that restoring the parent cannot undo an independent child delete. The new
private forced-RLS `milestone_deletions` ledger retains the original operation,
revision and server timestamp beyond receipt/log expiry. Ledger, canonical state,
receipt, recovery, log and watermark commit atomically under the account lock.
Repeated deletes cannot replace the winning identity. No milestone restore,
ordering, content purge or native account projection is enabled.

`python tool/local_backend.py --start` verified the existing nine pinned services,
eight Docker healthchecks and loopback-only bindings. The pinned CLI remains
2.120.0; `migration new --help` and version were checked before generating 012.
Supabase changelog/function-security guidance was rechecked; no provider or
package upgrade was made. No stopped backup container or volume was replaced.
Before applying, the rollback-only all-migration rehearsal passed, as did a
real-owner candidate edit/delete/ledger RPC over a retained milestone; rollback
preserved the exact preexisting child, creation envelope and surrounding state.

Separate pre-apply dumps are `.tools/backend-before-milestone-commands-schema.sql`
and `.tools/backend-before-milestone-commands-data.sql`, not recovery rehearsal
proof. `migration up --local --network-id dourstuff-local` applied only 012.
`migration list --local` matched all twelve IDs; `db advisors --local --type all
--level warn --fail-on error` reported no issues.

New checks:

- `python tool/test_backend_milestone_commands.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-milestone-commands-wire.json`:
  all 9 integration groups passed. They cover a shared create/edit/delete batch,
  original identities, retries/expiry, independent fields/children, reopening,
  partial/conflicting/held edits, exact predecessor binding, held children with no
  row, immutable parent, semantic/preflight rejection, both delete/edit and
  parent/child deletion orders, parent restore, simultaneous races, X/Y isolation,
  forced RLS/column grants and injected batch rollback.
- `dart run tool/check_backend_wire.dart .tools/backend-milestone-commands-wire.json`:
  all 91 real responses passed. The shared
  `test/fixtures/account-protocol-v2-milestone-commands.json` also passes Dart
  request round-trip/original-base assertions without changing protocol version.
- `flutter test test/domain_test.dart test/local_database_test.dart test/account_sync_policy_test.dart`:
  all 20 targeted domain/SQLite/policy tests passed.

The existing creation and task-deletion harnesses now capability-check milestone
ordering, because edit/delete are supported. The original SQL tombstone fixture
and prior historical failures remain retained. There were no failed new integration
runs before the successful results above.

Final local regression ran the eight prior suites sequentially on migration 012:
`python tool/test_backend_<suite>.py --supabase .tools/supabase/supabase.exe
--wire-output .tools/backend-<suite>-milestone-commands-regression-wire.json`
for foundation (8 groups), apply (11), task_create (11), task_fields (5),
task_due (7), task_delete (6), task_restore (8), milestone_create (9). The due
invocation also used `--fixtures .tools/due-fixtures.json`, passing all 785 cases
across 342 zones. With the new 9 command groups, **74 integration groups passed**.
Each output passed `dart run tool/check_backend_wire.dart`: respectively 10,
32, 136, 42, 75, 35, 57 and 113 replies; with the new 91, **591 real responses
passed**. `python tool/test_backend_http.py` passed all three HTTP/encoding tests.

Full local quality passed using pinned `.tools/flutter/bin`: `flutter pub get
--enforce-lockfile`, `dart run build_runner build`, generated-Dart diff check,
`dart format --output=none --set-exit-if-changed lib test tool`, `flutter analyze`
(no issues, 41.3 seconds), and `flutter test` (**111 tests**). No generated Dart,
SQLite schema or lockfile changed. Changed Markdown relative links and
`git diff --check` passed. Synthetic account/Auth-fixture, child deletion-ledger
and injected-trigger counts returned to zero. Final-head native CI and independent
review are required before merge; record the reviewed SHA and actual merge in
the PR timeline. These results precede this documentation-only handoff update.

### Next-session handoff — milestone commands, 23 October 2026

Finish this branch's independent review and final-head Quality/Android/Windows
CI, resolve findings, then perform the guarded merge and verify remote/local
main. Preserve all twelve applied migrations and repaired local stack volumes/
stopped backups. Next implementation: task milestone ordering with concurrent
reorder/add/delete behavior, then tags/memberships and remaining commands.
Native account projection/storage, secure GitHub PKCE, complete two-client
replication, snapshot/retention/resolution, consent/adoption/lifecycle and installed
latency/recovery acceptance remain unfinished.

The app stays guest-only; Phase 3.1 remains partial and Phase 4 gated. Activation
still requires resolving 100,000-UTF-16-unit descriptions versus the 64-KiB cap,
JSONB NUL/raw-number and normalization parity, plus historical/future timezone
parity. Never truncate or silently upload guest content. External prerequisites
remain GitHub OAuth/provider configuration with exact Android/Windows redirects,
verified secure session and PKCE-verifier storage, a restricted development
endpoint reachable from both installed clients, and installed Android/Windows
devices. No hosted project is linked and PC loopback is not device reachability
evidence. Keep accepted Phase 2 emulator entry closed and retained physical/native
gates open. No production deployment/migration or release occurred.

## Atomic milestone ordering — 24 October 2026

PR #9 was independently reviewed at `1821b3d7f508ff4319f26915b7394311fac6093b`
against `09256420428e2e53045b5ff19f2ec9358cb49b91`, with no actionable findings.
This completes the previous usage-limited attempt; it is an agent review, not
approval by another GitHub account. Quality run `39927748107` and Native builds
run `39927748190` passed all three jobs for that exact head. No blocking review
or unresolved thread was present. The guarded squash merge is
`2596b662ecc9fde30d22d51b6000118c45d4cee6`, verified on remote and clean local main.
The PR timeline records review/merge evidence. The connected GitHub integration
could read PR state but returned 403 for comments; the authenticated CLI completed
the authorized review comment and guarded merge.

This increment starts from that main commit on `codex/phase-3-milestone-order`.
Forward migration 013, `20261023191045_milestone_order.sql`, enables the separate
atomic `task.milestone_order` command. Its unique canonical UUID list preserves
observed/predecessor bases, whole-list conflict candidates and exact dependencies
on task/child creation. Held child creates can hold an order without fabricating
canonical rows. Missing/expired/foreign/other-parent references require recovery.
Unrelated work continues through contiguous sequences.

Independent additions append deterministically by UUID in reference projection;
deletions filter visibility while canonical ordered IDs remain unchanged. Both
arrival orders preserve the same visible result. Parent restore preserves child
tombstones and never applies late order candidates. Private invoker helpers have
fixed search paths and restricted grants; the existing account lock includes
order, recovery, log, receipt and watermark writes. No table/public API grant,
local SQLite schema, production dependency or app behavior changed. All twelve
previously applied migrations remain unchanged.

The guarded start initially failed because Docker's Linux-engine pipe was absent.
`docker desktop start --detach`, then `python tool/local_backend.py --start`,
verified nine pinned services, eight healthchecks and loopback-only bindings.
Volumes and stopped backup containers were preserved. CLI 2.120.0 version and
`migration new`, `migration up`, `db dump` and `db advisors` help were checked.
No upgrade was made. Supabase changelog/security guidance and relevant PostgreSQL,
table-exposure and TLS notices were rechecked; no hosted resource was provisioned.

Pre-apply verification: the foundation harness compiled all thirteen migrations
and preserved watermark/history/due data in a rollback-only rehearsal. A separate
real-owner ordering/dependency/projection smoke test over retained child data
initially failed with `operator does not exist: boolean -> unknown`. Explicit
parentheses around both JSON containment operands fixed the candidate before
application. The smoke test then passed and verified exact retained-state rollback.
Local pre-apply schema/data dumps are `.tools/backend-before-milestone-order-schema.sql`
and `.tools/backend-before-milestone-order-data.sql`; these are not restore evidence.
`migration up --local --network-id dourstuff-local` applied only 013.
`migration list --local` matched all thirteen IDs; `db advisors --local --type all
--level warn --fail-on error` reported no issues.

The first formatting invocation formatted the file, then exited 1 because the
sandbox denied access to Dart's telemetry log. The authorized SDK/cache invocation
passed afterwards. Targeted `flutter test test/domain_test.dart
test/local_database_test.dart test/account_milestone_order_test.dart` passed
14 tests. Full local quality passed with pinned `.tools/flutter/bin`:
`flutter pub get --enforce-lockfile`, `dart run build_runner build`, generated-Dart
diff check, `dart format --output=none --set-exit-if-changed lib test tool`,
`flutter analyze` (no issues, 32.0 seconds), and `flutter test` (**113 tests**).
No generated Dart, SQLite snapshot or lockfile changed.

The initial regression session was unavailable after a later interruption; Docker
was then stopped. Guarded startup was repeated after `docker desktop start --detach`.
The existing services/ports remained intact, and synthetic Auth-user and injected
trigger counts were zero. The final milestone-command suite was rerun with a
retained local log: all 9 groups and 91 Dart-validated real replies passed.
The earlier eight regression suites had completed successfully; the strengthened
ordering suite subsequently passed all 10 groups and 156 real reply validations.
No interrupted process is counted
as a completed test merely because it wrote a wire-capture file.

Final backend evidence on migration 013:

- `python tool/test_backend_<suite>.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-<suite>-order-regression-wire.json`
  for foundation (8 groups), apply (11), task_create (11), task_fields (5),
  task_due (7), task_delete (6), task_restore (8), milestone_create (9), and
  milestone_commands (9). The due command additionally used
  `--fixtures .tools/due-fixtures.json`, passing 785 cases across 342 zones.
- `python tool/test_backend_milestone_order.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-milestone-order-wire.json`:
  **10 groups passed**, including shared SQL/Dart validity/projection cases,
  exact predecessor/dependency binding, held-before-equivalence, both reorder/
  add/delete arrival orders, a simultaneous three-device race, malformed commands,
  account/parent isolation and failure at the second log write of a batch.
  With the nine earlier suites, **84 integration groups passed**.
- `dart run tool/check_backend_wire.dart` for each output validated respectively
  10, 32, 136, 42, 75, 35, 57, 113, 91 and 156 replies: **747 real responses**.
- `python tool/test_backend_http.py`: all **3** HTTP/encoding tests passed.
  Synthetic account/Auth, milestone/deletion-ledger and injected-trigger counts
  returned to zero. Changed Markdown relative links and `git diff --check` passed.

The latest cost runbook also corrects historical 500-MB/read-only shorthand using
current official documentation: billing quota restrictions and disk-pressure
read-only mode are distinct. No paid service or hosted resource was added.
Local results precede the final documentation-only handoff update. Native CI
builds are still required on the final reviewed head and do not establish installed
Android/Windows acceptance.

### Next-session handoff — milestone ordering, 24 October 2026

PR #9 is merged and verified at `2596b66`. Current branch:
`codex/phase-3-milestone-order`, based on that commit. Ordering implementation,
fixtures, test harness and documentation pass the local checks above. Finish the
task PR's independent review and final-head Quality/Android/Windows CI before
guarded merge. Record the reviewed SHA, findings/disposition and actual merge in
the PR timeline; recheck that timeline before resuming this dated handoff.

Preserve all thirteen applied migrations and repaired volumes/stopped backups.
After this increment merges, use a fresh branch for tags/memberships and remaining
command semantics, resolving pinned client/server normalization before tag writes.
Native account projection/storage, secure GitHub PKCE, automatic two-client sync,
snapshot/retention/resolution, adoption/lifecycle and installed latency/recovery
acceptance remain unfinished.

The app stays guest-only; Phase 3.0 is complete, 3.1 partial and Phase 4 gated.
Before activation resolve valid 100,000-UTF-16-unit descriptions versus the 64-KiB
cap, JSONB NUL/raw-number and normalization parity, and historical/future timezone
parity. Never truncate or silently upload guest content. External prerequisites
remain exact GitHub OAuth Android/Windows redirects, verified secure session and
PKCE-verifier storage, a restricted development endpoint reachable by both
installed clients, and installed Android/Windows devices. No hosted project is
linked; loopback tests and native compilation do not establish device acceptance.
Keep accepted Phase 2 emulator entry closed and retained physical/native gates
open. No production deployment/migration, release or store publication occurred.

## Frozen tag-name normalization — 24 October 2026

PR #10 was refreshed at head `2f2bf924a9730c8968ce6a3e477810c8f615ed53` and base
`2596b662ecc9fde30d22d51b6000118c45d4cee6`. Its recorded independent review at
[comment 6377852545](https://github.com/ipar569/DoUrStuff/pull/10#issuecomment-6377852545)
had no actionable findings. Quality run `40047497996` and Native builds run
`40047497988` passed all three jobs for that head. No blocking submitted review,
unresolved thread or branch rule was present. The CLI guarded squash merge is
`eb128f0d2798db4c26a078737a69ab9941af848f`, confirmed on remote main and clean
local main. The connector merge call failed argument validation; the authenticated
CLI used `--match-head-commit` without bypassing protections.

This prerequisite increment starts from that merge on
`codex/phase-3-tag-normalization`. Migration 014,
`20261024083944_tag_name_normalization.sql`, freezes native Dart 3.13.5 casing,
trim and whitespace collapse, with no ambient SQL locale, NFC/NFKC or case folding.
It contains 1,023 lowercase mappings, 26 trim characters and 25 collapsing
whitespace characters. U+0085 trims at the ends but remains inside a name.
The new pure Dart helper is used for guest tag keys and account collision policy;
it preserves existing native behavior and does not rewrite any stored row.
Exact atomic `{name, normalized_name}` validation preserves proposed payloads,
uses the existing 80-UTF-16-unit name limit, and rejects unrepresentable NUL or
unpaired-surrogate account names without altering guest data. No server tag
command, UUID alias, membership redirect or client account write is enabled.

The first guarded stack check found Docker stopped. `docker desktop start --detach`
then `python tool/local_backend.py --start` verified the same nine pinned services,
eight healthchecks and loopback bindings. No volume or stopped backup was replaced.
CLI 2.120.0 and its migration/dump/advisor help were checked; no upgrade was made.
Official Supabase changelog/function security and PostgreSQL string-function
guidance were rechecked. No cloud resource or production migration was used.

Pre-apply: the real foundation suite rehearsed empty application schema and
retained watermark/history/due data through fourteen migrations, rolling back
to the existing state. The normalization candidate also passed in a rollback-only
transaction as the actual `dourstuff_rpc` role. Pre-apply dumps are
`.tools/backend-before-tag-normalization-schema.sql` and
`.tools/backend-before-tag-normalization-data.sql`; restore rehearsal is unverified.
`migration up --local --network-id dourstuff-local` applied only 014;
`migration list --local` matched all fourteen IDs and `db advisors --local --type
all --level warn --fail-on error` reported no issues. All thirteen prior migration
files remain unchanged.

Checks on the implementation working tree (before this documentation update):

- `dart run tool/export_tag_normalization.dart .tools/tag-normalization` with
  pinned native Dart exported **1,399 parity cases**: 272 chunks containing every
  one of the **1,112,063 PostgreSQL-representable Unicode scalars**, 104 whitespace
  boundary cases and 1,023 case-context strings.
- `python tool/test_backend_tag_normalization.py --candidate --fixtures .tools/tag-normalization/tag-normalization-parity.json`
  passed before application; the same command without `--candidate` passed after
  application. It also checks **23** shared/UTF-16-boundary name validations,
  **26** whitespace boundaries, null handling, fixed paths and restricted invoker
  grants. Native Dart tests independently check every scalar against the frozen
  data and preserve malformed guest strings.
- Targeted domain/SQLite/policy/normalization checks passed **23 tests**. A later
  retained-v1-tag fixture verifies original UUID and membership reuse plus
  whole-transaction rollback of a colliding rename.
- Pinned `flutter pub get --enforce-lockfile`, `dart run build_runner build` and
  generated-Dart diff passed. Initial analysis found three exporter lint issues
  (relative lib import, interpolation braces, print); these were fixed.
  `dart format --output=none --set-exit-if-changed lib test tool`, `flutter analyze`
  (no issues, 4.7 seconds), and full `flutter test` then passed (**117 tests**).
  No SQLite schema, generated database or lockfile changed.

Staged `git diff --check` reports one trailing blank line at EOF in the newly
generated, already locally applied migration 014. Its bytes are retained; this
is a whitespace warning, not a passing check or SQL/runtime failure.

Full regression on migration 014 passed **84 integration groups** using
`python tool/test_backend_<suite>.py --supabase .tools/supabase/supabase.exe
--wire-output .tools/backend-<suite>-normalization-wire.json` for foundation (8),
apply (11), task_create (11), task_fields (5), task_due (7), task_delete (6),
task_restore (8), milestone_create (9), milestone_commands (9), milestone_order (10).
The due suite additionally used `--fixtures .tools/due-fixtures.json` and passed
785 cases across 342 zones. Per-suite logs are retained beside those captures.
`dart run tool/check_backend_wire.dart` for each capture passed respectively
10/32/136/42/75/35/57/113/91/156 replies: **747 real response validations**.
`python tool/test_backend_http.py` passed all **3** helper tests. Synthetic
account/Auth-user and noninternal sync-trigger counts returned to zero.
All 49 changed-document relative links passed.

PR #11's initial independent review covered
`f259a928ce10a39717f405dabd894a6efbd5070f` against `eb128f0`, with no actionable
findings. It independently compared all 1,023 SQL/Dart mappings and confirmed
unchanged earlier migrations. This documentation-only evidence update still
requires refreshed exact-head review and final-head Quality/Android/Windows CI
before guarded merge; record final SHA/results/merge in the PR timeline.
Native compilation does not establish installed-device acceptance.

### Next-session handoff — tag normalization, 24 October 2026

Finish the normalization branch's refreshed independent review and
Quality/Android/Windows CI, then guarded merge and remote-main verification.
Record the reviewed SHA and actual merge in the PR timeline; inspect that timeline
before resuming this dated handoff. Preserve all fourteen applied migrations.
Next increment: server tag creation/edit/deletion, keeping normalized-name
collision candidates under distinct UUIDs with their immutable original bases;
then exact task/tag dependencies and versioned memberships. Never alias IDs or
silently redirect memberships. Saved views/preferences and remaining commands,
snapshot/retention/resolution, native account storage/auth and replication follow.

The app stays guest-only; Phase 3.0 complete, 3.1 partial, Phase 4 gated. Remaining
activation gaps include valid 100,000-UTF-16-unit descriptions versus the 64-KiB
operation cap, JSONB NUL/raw-number and remaining normalization/representation
parity, and historical/future timezone parity. Never truncate or silently upload
guest content. Exact GitHub OAuth Android/Windows redirects, verified secure
session/PKCE-verifier storage, a restricted endpoint reachable by both installed
clients and installed Android/Windows test devices are still external/native
prerequisites. No hosted project is linked. Retain accepted Phase 2 emulator entry
and outstanding physical/native, latency and recovery gates. No production
deployment/migration, release or store publication occurred.

## Server tag commands — 25 October 2026

PR #11 merged as `69e957214619a5b7e8bb7609399c6c735e9c6682`, verified on remote
main and fast-forwarded clean local main. Renewed independent review covered
`e5fd2e85149411eb8d756821f1e62458b40aa735` against `eb128f0` with no actionable
findings. Quality run `40079917945` and Native builds run `40079917934` passed
for that exact head. No blocking reviews/unresolved threads were present; merge
used the reviewed-head guard. Review and merge evidence are in the
[PR timeline](https://github.com/ipar569/DoUrStuff/pull/11). The connector lacks
repository write permission, so the authenticated CLI recorded evidence/merged.

This increment starts from that merge on `codex/phase-3-tag-commands`. Forward
migration 015, `20261025021609_tag_commands.sql`, enables server tag create,
rename and delete. Active normalized-name collisions retain original candidates
under their own UUIDs; neither canonical aliases nor membership redirects are
created. Name is atomic display/key data. Exact predecessors bind before
availability/equivalence, so successors of a conflicted create remain held even
without a canonical row. Unrelated sequences continue. Delete dominates visibility,
retaining content and immutable creation/deletion identities beyond receipt/log
expiry. A replacement UUID may reuse the name without reviving the old tag.
Memberships, tag restoration/purging and native account projection remain absent.

Private forced-RLS tag tables use owner-qualified keys; an active-name unique
index uses C collation and narrow column grants preserve identity. The existing
account lock covers canonical state, recovery, ledger, receipts, log and watermark.
No SQLite schema, provider dependency, new public RPC or client table grant changed.
All fourteen earlier applied migration files remain unchanged.

At resume Docker was stopped; `docker desktop start --detach` followed by
`python tool/local_backend.py --start` restored nine pinned services, eight
healthchecks and loopback-only bindings. Containers, volumes and stopped backups
were preserved. CLI 2.120.0/help and the official Supabase changelog were rechecked;
no upgrade/hosted resource was introduced. The earlier function-security and
PostgreSQL string-function review remains applicable; the partial-index/RLS
schema guidance was also read.

Before applying, `python tool/test_backend_foundation.py --supabase
.tools/supabase/supabase.exe --wire-output .tools/backend-foundation-tag-candidate-wire.json`
passed all eight groups, including empty application schema and retained-data
forward upgrades through fifteen migrations. `python tool/test_backend_tag_commands.py
--supabase .tools/supabase/supabase.exe --candidate` passed a real-owner
create/collision/held/delete batch and verified exact retained task/history/
receipt/watermark rollback. Local pre-apply schema/data dumps are
`.tools/backend-before-tag-commands-schema.sql` and
`.tools/backend-before-tag-commands-data.sql`; restore rehearsal is unverified.
`migration up --local --network-id dourstuff-local` applied only 015;
`migration list --local` matched all fifteen IDs and local advisors found no issues.

Implementation working-tree checks, before this documentation update:

- `python tool/test_backend_tag_commands.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-tag-commands-wire.json`:
  initial 11 groups passed; the strengthened final **13 groups passed**, including
  shared atomic task/tag create/edit/delete, both collision orders, simultaneous
  creates/deletes/edits, original UUIDs/bases, held/expired chains, whole-name
  conflicts, real Unicode distinctions, malformed/semantic rejection, X/Y raw
  REST/RLS denial and a second-log-write rollback of rename/delete.
- `dart run tool/check_backend_wire.dart .tools/backend-tag-commands-wire.json`:
  **121 real replies passed** including name validation parity. Shared tag wire
  fixture round-trips through Dart with original name/existence predecessors.
- Targeted domain/SQLite/tag normalization/wire checks passed **16 tests**.
  Pinned `flutter pub get --enforce-lockfile`, `dart run build_runner build`,
  generated-Dart diff, `dart format --output=none --set-exit-if-changed lib test tool`,
  `flutter analyze` (no issues, 33.8 seconds), and full `flutter test` passed
  (**118 tests**). No lockfile/generated database/SQLite snapshot changed.

The ten prior backend suites are being rerun sequentially on migration 015,
followed by normalization parity and HTTP helpers; retained captures/logs use
`.tools/backend-<suite>-tag-regression-wire.json` and the corresponding `.log`.
Record final results, independent reviewed SHA, final-head CI and guarded merge
in this increment's PR timeline. Native compilation is not installed-device proof.

### Next-session handoff — tag commands, 25 October 2026

Inspect the task PR timeline and current Git/GitHub state first. Finish any
remaining regression/review/checks and merge only its reviewed head; confirm the
merge on remote main. If merged, create a fresh branch for task/tag membership
semantics with exact parent dependencies, independent add/remove bases and
visibility suppression by either parent's tombstone. Never redirect a membership
from a collided/deleted tag UUID to a same-name replacement. Saved views/preferences
and remaining commands follow. Preserve all fifteen applied migrations.

The app remains guest-only; Phase 3.0 complete, 3.1 partial and Phase 4 gated.
Keep the description UTF-16/64-KiB cap, JSONB NUL/raw-number/remaining representation
and historical/future timezone parity gates open. Never truncate or silently
upload guest content. Native account storage/projection, secure session and
PKCE-verifier storage, exact GitHub OAuth Android/Windows redirects, a restricted
endpoint reachable by both installed clients, and installed test devices remain
unverified prerequisites. Snapshots/retention/resolution, adoption/lifecycle,
automatic sync, latency and recovery acceptance remain unfinished. Retain accepted
Phase 2 emulator entry and outstanding physical/native gates. No production
migration/deployment, release or store publication occurred.

## Task/tag memberships — 25 October 2026

Refreshed clean `main` and `origin/main` matched `c50b106` (PR #13). PR #12's
[review/merge timeline](https://github.com/ipar569/DoUrStuff/pull/12) confirms
reviewed head `9c4428847c6c5ea46c26b5b07fa9ca8f8d5014f5`, no actionable independent
review findings, passing Quality/Android/Windows CI, and guarded squash merge
`259bd6b61d683e960ec956df4e7e693779397bcd`. Its final evidence was 118 Flutter tests,
97 backend groups and 868 real Dart response validations. This increment starts
from `c50b106` on `codex/phase-3-task-tag-memberships`.

Migration 016, `20261025080938_task_tag_memberships.sql`, adds `task.tag` through
the existing apply RPC. The boolean field is versioned per exact task/tag UUID
pair. Original absent/observed/predecessor bases and optional exact parent
existence dependencies remain immutable. Conflicted parents hold the entire
relationship while unrelated sequences advance. Additions need both live parents;
explicit removal can persist while a retained parent is hidden. Either tombstone
suppresses visibility without rewriting the pair revision, and task restore never
undoes an independent remove. Same-name replacement tags cannot redirect old pairs.

Owner-qualified foreign keys, forced RLS, restricted column grants and an
append-only accepted membership ledger preserve account/identity boundaries. The
account lock covers canonical changes, recovery, ledger, receipts, logs and device
watermarks atomically. No SQLite version, generated database, dependency, public
RPC or native account UI changed. All fifteen earlier migrations remain unchanged.
The shared Dart/SQL fixture, matching removal policy and real wire checker cover
the new command while account writes remain disabled.

The required guarded startup verified nine pinned running services, eight Docker
healthchecks and loopback bindings, preserving volumes and stopped backups. CLI
2.120.0/help and official Supabase changelog/function/RLS guidance were rechecked;
no upgrade or hosted resource was introduced. The initial sandboxed Git fetch
and CLI telemetry access failed; authorized scoped invocations succeeded. The
web reader could not render the Markdown changelog, and sandbox DNS initially
failed; an authorized read of the official source succeeded.

Pre-apply checks:

- `python tool/test_backend_foundation.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-foundation-membership-candidate-wire.json`:
  all eight groups passed, including rollback-only empty application schema and
  retained-data forward upgrades through sixteen migrations.
- `python tool/test_backend_memberships.py --supabase .tools/supabase/supabase.exe --candidate`:
  real-owner exact dependencies/add/remove/re-add passed in a rollback-only
  transaction, preserving exact retained parent/history/receipt/watermark state.
- `db dump --local --schema public,sync_private` saved ignored schema and data-only
  dumps at `.tools/backend-before-memberships-{schema,data}.sql`; restoration is
  not rehearsed. `migration up --local --network-id dourstuff-local` applied only
  016; `migration list --local` matched all sixteen IDs; `db advisors --local
  --type all --level warn --fail-on error` reported no issues.

Implementation working-tree checks before the final documentation update:

- Pinned `.tools/flutter/bin` `flutter pub get --enforce-lockfile`, `dart run
  build_runner build`, generated-Dart diff, `dart format --output=none
  --set-exit-if-changed lib test tool`, `flutter analyze` (no issues, 40.2 seconds)
  and full `flutter test` passed: **121 tests**. Targeted domain/SQLite/schema/
  membership checks passed 16 tests; the additional matching parent-removal
  policy/fixture run passed 11 tests. No lockfile or schema snapshot changed.
- `python tool/test_backend_memberships.py --supabase .tools/supabase/supabase.exe
  --wire-output .tools/backend-memberships-wire.json`: initial **12 groups passed**.
  `dart run tool/check_backend_wire.dart .tools/backend-memberships-wire.json`
  validated **128 real replies**. An earlier checker invocation ran before the
  capture was finished and failed with a missing file; the completed capture
  subsequently passed. No incomplete capture is counted as passing evidence.
- Coverage includes opposite add/remove arrival orders and simultaneous races,
  independent pairs, exact parents, collided-tag held children, expired evidence,
  dependency-order validation, both tombstone/add orders, remove/restore,
  same-name replacement isolation, semantic/malformed rejections, X/Y raw
  REST/RLS denial and a second-log-write batch rollback. A strengthened thirteenth
  group additionally checks exact same-pair predecessor identity/value/expiry.

At the 25 October interruption, the eleven prior suites were being rerun
sequentially on migration 016. The completed results are recorded below. Captures
and logs use `.tools/backend-<suite>-membership-regression-wire.json` and matching
`.log` paths. Record final results, exact independent reviewed SHA, CI and guarded
merge in this task's PR timeline. Native CI builds remain required and are not
installed-device acceptance.

### Next-session handoff — memberships, 25 October 2026

Refresh Git/GitHub and the membership PR timeline before resuming; preserve newer
work. Finish any outstanding regression, independent review and final-head
Quality/Android/Windows CI. Merge only the reviewed head with the expected-head
guard, then verify the actual merge on remote main. Preserve all sixteen applied
migrations and repaired local volumes/backups. Once this increment is merged,
start a fresh branch for saved views/preferences: atomic query specification,
independent name edits, deletion and safe default-view reference/clearing with
exact bases, dependencies and account isolation. Remaining commands and
snapshot/retention/resolution precede native account integration.

The app stays guest-only; 3.0 complete, 3.1 partial, Phase 4 gated. Keep the
100,000-UTF-16-unit description/64-KiB operation cap, JSONB NUL/raw-number and
remaining representation parity, and historical/future timezone gates open.
Never truncate or silently upload guest data. Native account storage/projection,
secure session/PKCE storage, exact Android/Windows GitHub OAuth redirects,
restricted endpoint reachable by both installed clients, and installed devices
remain prerequisites. Automatic sync, snapshots/recovery/resolution, adoption/
lifecycle, latency and recovery acceptance are unfinished. Retain accepted
Phase 2 emulator entry and all outstanding physical/native gates. No production
deployment/migration, release or store publication was authorized or performed.

### Final local membership verification — 26 October 2026

The 25 October commit/push command did not execute: automatic approval review
hit a usage limit. On 26 October the same authorized workflow resumed; fetch
succeeded and `origin/main` remained `c50b106`, with only this task's staged
changes present and no membership PR yet. Docker was stopped. Starting the
installed Desktop runtime and then `python tool/local_backend.py --start`
verified the preserved pinned services and loopback bindings again.

All ten earlier suites completed on migration 016 before the interruption:
foundation 8, apply 11, task_create 11, task_fields 5, task_due 7, task_delete 6,
task_restore 8, milestone_create 9, milestone_commands 9 and milestone_order 10
(**84 groups**). Due checks included 785 cases across 342 zones. Their retained
captures passed `dart run tool/check_backend_wire.dart` individually:
10/32/136/42/75/35/57/113/91/156 replies (**747 real responses**).

The tag regression stopped at an obsolete assertion that `task.tag` was still
unsupported (`KeyError: 'code'`). The capability check now uses the still-disabled
`view.create` command. Its complete rerun passed all **13 groups**, with **121**
real Dart-validated replies. No applied migration changed to fix that test.
`python tool/test_backend_memberships.py --supabase .tools/supabase/supabase.exe
--wire-output .tools/backend-memberships-final-wire.json` then passed the
strengthened **13 groups**; Dart validated all **138** real replies. Final totals:
**110 backend integration groups and 1,006 real response validations**.

`python tool/test_backend_tag_normalization.py --fixtures
.tools/tag-normalization/tag-normalization-parity.json` passed 1,399 normalization
cases covering all 1,112,063 PostgreSQL-representable scalars plus context,
23 name cases, 26 whitespace boundaries and private helper grants. An earlier
invocation incorrectly supplied `--supabase`; argument parsing rejected it and
the corrected command above passed. `python tool/test_backend_http.py` passed
all three tests. Synthetic sync accounts, fixture Auth users and injected sync
triggers all returned to zero. The 121-test Flutter quality result above remains
applicable: subsequent implementation changes only updated Python regression
coverage and documentation. All fifteen prior migrations and 53 relative Markdown
links were verified; working/staged `git diff --check` passed.

Retained final logs: `.tools/backend-tag_commands-membership-regression-final.log`,
`.tools/backend-memberships-final.log` and
`.tools/backend-membership-normalization-final.log`. The original failed tag log
remains retained. These results precede the final documentation-only update.
Record exact-head independent review, final Quality/Android/Windows CI and actual
guarded merge in the task PR timeline, then refresh that timeline on resume.
The next implementation increment after merge remains saved views/preferences
as described in the handoff above; all activation/representation/external/native
gates and production/release boundaries remain unchanged.
