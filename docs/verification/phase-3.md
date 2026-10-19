# Phase 3 verification

Status: milestone **3.0 local readiness passed; 3.1 in progress**, reviewed
19 October 2026. The user accepted
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
Five migrations and real synthetic-account registration/pull/apply/ownership
tests ran on PostgreSQL 17.11. Apply now covers core task creation and
title/priority/status edits, with private durable status history. Full draft
fields, history download, native OAuth and client sync remain unfinished.

| Gate | Evidence/status |
| --- | --- |
| Phase 2 entry acceptance | Accepted by user using emulator evidence; physical-device gate retained |
| Protocol and SQLite upgrade | Six RPC codecs/goldens and field/relationship/recovery policy fixtures implemented; real server enforcement and local v2 upgrade pending |
| Local backend readiness | Existing local stack verified; guarded restart and image pins recorded; fresh Windows recreation needs the documented binding repair |
| Real PostgreSQL command/RLS integration | Registration/pull, core creation and title/priority/status edits tested, including receipts/recovery/history/RLS; remaining groups/commands, snapshots and resolution unfinished |
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
