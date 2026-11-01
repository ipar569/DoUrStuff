# Local backend — Phase 3.1 foundation

## Deleted-content cleanup (migration 022)

Preserve all 22 applied migrations and existing containers/volumes. Start only
with `python tool/local_backend.py --start`. After the user started Docker Desktop,
rollback rehearsals and local application passed, with matching migration IDs
and no advisor findings. The new suite passed 12 groups/87 decoded replies;
consult the latest verification handoff/PR for final regression and review status.

The new real suite is `python tool/test_backend_deleted_content.py --supabase
.tools/supabase/supabase.exe --wire-output .tools/backend-deleted-content-wire.json`,
followed by `dart run tool/check_backend_wire.dart .tools/backend-deleted-content-wire.json`.
Use `--candidate` only before applying 022 for rollback-only retained-data checks.
Run all seventeen suites sequentially; the foundation schema rehearsal must not
overlap another suite. Never reset the database to run tests.

Maintenance is explicit: `python tool/run_backend_retention.py --owner <local-uuid>
--policy deleted-content --batch-size 200 --batches 1`. It compacts current
720-hour-old deleted shadows and bounded ledger payloads, preserving permanent
identities, history and unresolved candidates. Old snapshots are immutable;
new log revisions carry compaction. The policy does not erase separately retained
logs/receipts/history/captures. No schedule, remote target or native account
activation is introduced. See the [protocol](../docs/architecture/account-protocol-v2.md).

## Bounded local retention (migration 021)

All twenty prior migrations are preserved. The app remains guest-only. Run the
sixteen backend suites sequentially, including:

```powershell
python tool/test_backend_retention.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-retention-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-retention-wire.json
```

The optional `--candidate` flag is only for a rollback-only rehearsal before 021
is applied; omit it on the applied schema. Foundation rehearsals must not overlap
other backend tests. The new suite creates and cleans up synthetic accounts only.

Operator maintenance for one explicitly selected **local** account:

```powershell
python tool/run_backend_retention.py --owner <local-owner-uuid> --batch-size 200 --batches 1
```

This command checks the existing stack through `local_backend.py`; it never
starts/recreates services or accepts a remote endpoint. Startup remains only
`python tool/local_backend.py --start`. Each batch commits independently with a
2-second lock timeout and 10-second statement timeout. Batch size is 1–1000
whole revisions and up to that many receipts; passes are capped at 100 batches
and stop early when neither stream deletes a row. Output is counts/cursor only.
Transport failure or subprocess timeout reports an unconfirmed batch outcome,
since COMMIT may have succeeded before acknowledgement was lost. Repeating the
pass is safe; earlier confirmed batches remain committed.
The private invoker function is executable by the database operator, not any API
role. No automatic schedule is installed by this migration or runner.

The 180-day cutoff is 4320 elapsed hours, inclusive at equality. A contiguous log
prefix and its floor commit atomically under the account lock; nonmonotonic old
timestamps cannot create holes. Compact immutable hashes are backfilled from
available receipts and written with every future receipt. They prevent payload,
operation-ID and sequence reassignment after pruning. No canonical content,
history, watermarks, unresolved candidates, deletion/mutation ledgers or captures
are pruned. Missing predecessor receipts require recovery; hashes are not field
revision evidence. See the [contract](../docs/architecture/account-protocol-v2.md).

## Earlier implementation record

Initialized with CLI **2.120.0**, pinned in `../.supabase-version`. Configuration
is for the synthetic `dourstuff-local` project only. No remote project is linked.
Eighteen migrations now provide private account/device/log storage, RLS, restricted
device-registration/pull RPCs, atomic core task creation and title/priority/status/
description/estimate/due edits, plus task deletion, exact-deletion restore and
atomic milestone creation with immutable same-account parents/dependencies,
independent milestone title/completion edits, durable child deletion and atomic
task milestone ordering.
Migration 014 additionally freezes tag-name normalization and exact name-group
validation, without enabling tag commands.
Migration 015 adds atomic tag creation/renaming/deletion with distinct-UUID
collision recovery and durable deletion identities. Migration 016 adds versioned
task/tag memberships with exact parent dependencies, independent removal records
and visibility suppression by either parent. No UUID redirection is performed.
Migrations 017–018 add saved views with atomic canonical query specifications,
independent names and deletion, plus versioned default-view references and atomic
conditional clearing. The second is a forward fix for empty-name validation.
Apply stores canonical fields, immutable receipts, recovery candidates and device
watermarks together, with durable status history. Creation requires the four
core groups documented in the [v2 contract](../docs/architecture/account-protocol-v2.md),
with optional description, nullable estimate and a complete due tuple;
other task groups, history downloads, commands, snapshots and resolution remain unfinished.
The Flutter app remains guest-only. Test users are created
temporarily by the integration harness and removed afterwards.
New public objects are not automatically exposed to API roles. Seed execution,
analytics and the unused edge runtime are disabled.

The 16 October host now runs Desktop **4.95.0**, Engine **29.8.2**, PostgreSQL
**17.11**. This project's local-stack prerequisite remains Engine 28+
because Docker documents that older engines can expose localhost-published ports
to the same L2 network. This is a conservative project restriction, not a claim
that CLI execution itself requires Engine 28. [Docker port-publishing documentation](https://docs.docker.com/engine/network/port-publishing/)

## Tested host restart and checks

The documented loopback network default was **not honored** by CLI 2.120.0 /
Docker Desktop on this host: startup published ports on `0.0.0.0` and `::`.
Services were stopped immediately after inspection. Four publishing containers
were recreated with explicit `HostIp=127.0.0.1`, preserving their volume mounts
and injected configuration. Their originals remain stopped with the suffix
`-before-loopback`; do not start those originals. The ignored local repair helper
is `.tools/rebind_supabase.py`; it is one-time host recovery evidence, not a
portable deployment script. No Docker daemon-wide or firewall settings changed.

Use the checked restart path for the **existing** repaired containers:

```powershell
python tool/local_backend.py --start
python tool/test_backend_http.py
python tool/test_backend_foundation.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-foundation-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-foundation-wire.json
python tool/test_backend_apply.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-apply-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-apply-wire.json
python tool/test_backend_task_create.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-create-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-create-wire.json
python tool/test_backend_task_fields.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-fields-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-fields-wire.json
.tools/flutter/bin/dart.bat run tool/export_due_fixtures.dart .tools/due-fixtures.json
python tool/test_backend_task_due.py --supabase .tools/supabase/supabase.exe --fixtures .tools/due-fixtures.json --wire-output .tools/backend-due-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-due-wire.json
python tool/test_backend_task_delete.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-delete-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-delete-wire.json
python tool/test_backend_task_restore.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-restore-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-restore-wire.json
python tool/test_backend_milestone_create.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-milestone-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-milestone-wire.json
python tool/test_backend_milestone_commands.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-milestone-commands-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-milestone-commands-wire.json
python tool/test_backend_milestone_order.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-milestone-order-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-milestone-order-wire.json
python tool/test_backend_tag_commands.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-tag-commands-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-tag-commands-wire.json
python tool/test_backend_memberships.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-memberships-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-memberships-wire.json
python tool/test_backend_saved_views.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-saved-views-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-saved-views-wire.json
```

`local_backend.py` without `--start` checks the existing stack. It verifies the
engine version, project labels, explicit and actual port bindings, image IDs/
registry digests in `images.lock.json` and service health. It never creates a
container or deletes a volume. Eight services have Docker healthchecks;
PostgREST is checked through the HTTP integration harness. Ports 54321–54324
are loopback-only. The lock records tested Linux amd64 images, not other platforms.
A changed image requires review and re-verification.

On a fresh host, review [Supabase's network guidance](https://supabase.com/docs/guides/local-development)
and verify actual bindings. Do not assume `--network-id` guarantees isolation;
the known Windows behavior above means fresh/recreated-container startup is not
yet automated safely here. Do not run plain `supabase start` to replace this
host's repaired containers. Preserve named volumes and backups during repairs.

Run from the repository root with the pinned CLI (optional local path above).
The CLI can print local development
credentials; do not paste or commit that raw output. No application secrets
belong in this directory. Phone access needs separately restricted development
networking and native OAuth configuration; this loopback baseline does not
establish two-device acceptance.

## Tag normalization prerequisite

```powershell
.tools/flutter/bin/dart.bat run tool/export_tag_normalization.dart .tools/tag-normalization
python tool/test_backend_tag_normalization.py --fixtures .tools/tag-normalization/tag-normalization-parity.json
```

Use native Dart 3.13.5. The exporter measures every Unicode scalar, then emits a
frozen mapping fixture, generated Dart/SQL helper source and 1,399 real parity
cases into the scratch directory. It never updates source migrations itself.
Compare generated data with `test/fixtures/tag-normalization-v1.json`; format the
generated Dart before comparing with `lib/domain/tag_normalization_data.dart`.
The generated SQL is the prefix of migration 014 up to its end-generated marker;
the exact name-group validator and grants are hand-reviewed below it.
Never overwrite an applied migration when updating SDKs or generators.

Before first application only, `--candidate` executes 014 and these tests in a
rollback-only transaction. After application, omit it. The harness verifies
every PostgreSQL-representable Unicode scalar, casing context, whitespace/UTF-16
boundaries and restricted invoker grants. Flutter tests independently compare
the pinned native policy across all scalars and preserve malformed guest strings.
Migration 015 uses this name validator for tag creation/edit/deletion. Memberships
still require atomic dependency, identity, RLS and transaction tests before enablement.

## Explicit recovery verification

Recovery v1 adds `sync_resolve_recovery` plus opt-in `resolution_version: 1`
alongside `history_version: 1` downloads. See the protocol contract for exact
preview/held-choice and immutable retry semantics. Run
`python tool/test_backend_resolution.py --supabase .tools/supabase/supabase.exe
--wire-output .tools/backend-resolution-wire.json`, followed by
`dart run tool/check_backend_wire.dart .tools/backend-resolution-wire.json`.
The suite's `--candidate` is only for rollback rehearsal before applying 023;
never rerun it on an applied schema. All eighteen backend suites run sequentially
when the foundation schema rehearsal is included. Preserve the existing stack,
all applied migrations and original candidates; account writes remain gated.
Migration 024 fixes retained retry response epochs without rewriting 023. The
same suite includes the rollback-only epoch-change regression; `--epoch-only`
runs that focused case. `--epoch-candidate` is only for pre-024 rollback rehearsal,
never for the already-applied schema. Both migration files must remain unchanged.

## Migration and test scope

Apply future migrations only with `supabase migration up --local`; never use
`--linked` under this task. Take a local backup first. The second migration is
a forward fix for managed auth-schema permissions found by real HTTP tests.
Its private, argument-free identity helpers run with the migration owner's
privileges; RPCs use a separate non-login, non-bypass role subject to RLS.
All elevated functions fix their search path and restrict execute grants.

The harness verifies empty **application-schema** initialization inside a
rollback-only transaction, retained device watermarks through the forward
migration, real Auth tokens for synthetic X/Y, REST/RPC access denial, RLS,
registration duplication, log pagination, account-lock concurrency and expired/
missing logs. The separate apply harness exercises real HTTP/JWT command writes:
conflict/held/unrelated progress, predecessor binding, partial merge, lost-reply
retry, receipt expiry, deletion recovery, ownership, injected transaction failure
and late commits. It retains SQL-seeded legacy shadows for focused regression
coverage. The new create/status harness creates every task through HTTP, testing
collisions, completion/edit in both orders, immutable retries, atomic rejection,
rollback including history, and owner isolation. The Dart checker compares status
group, description and estimate validity as well as title validity
with the app's validator, including Unicode whitespace and UTF-16 length cases.
The HTTP helper explicitly disables environment proxies and rejects redirects;
the loopback-only dummy-server tests verify that credentials are never forwarded.
Those two transport tests also run in the Quality workflow without Docker.
An additional helper regression verifies UTF-8 SQL input/output independently
of Windows' default encoding; the shared command runner specifies UTF-8.
The task-fields harness covers optional description/estimate creation, independent
edits versus completion, same-field conflicts/held successors, null clearing,
ownership and the exact 64-KiB operation boundary. Direct SQL and Dart domain
tests cover the larger 100,000-UTF-16-unit description limit. Valid descriptions
larger than the wire envelope remain an explicit pre-activation gap.
The due harness adds 785 generated parity cases across all 342 client zone names,
strict civil/none/timed shapes, gaps/folds and invalid tuples. It exercises due
races, clearing, completion history, held successors, receipt expiry, rollback
and X/Y isolation. Migration 007 pins the zone vocabulary to timezone 0.11.1;
future/historical offset compatibility between separate Dart/PostgreSQL tzdata
remains an activation gate beyond these fixtures. Existing values are never
normalized. `TimePolicy.validAccountDue` shares the guest resolver with the
wire checker. Old creates retain an absent due group; no defaults are backfilled.
The apply harness includes maximum-depth provenance through conflict and pull,
with real responses decoded by Dart using a separate reply-envelope depth budget.
Migration 005 retains original operation payloads with status history, protects
those identities after receipt expiry and excludes no-op status values from
history. The upgrade test preserves both receipt-backed history and older events
whose original receipt is unavailable. The wire checker accepts terminal commands
with several invalid groups without insisting on one specific rejection priority.

Unsupported commands/groups/dependencies fail whole-batch preflight without
consuming sequences. No scheduled pruning is installed; expiry tests remove only
synthetic receipts. JSONB cannot represent embedded NUL and normalizes some input
number spellings before validation; complete wire/semantic parity remains a gate
before client activation. Native GitHub PKCE, snapshots, full command
validation, explicit resolution and two-device integration remain open. See the
[verification report](../docs/verification/phase-3.md) for failures and exact results.

The milestone harness exercises atomic parent/child batches and a shared Dart
wire fixture, creation collisions, exact parent receipt binding, parent conflict/
held/unrelated progress, missing/expired evidence, cross-owner denial, inherited
visibility in both parent-delete orders, restores, retries and transaction faults.
It retains the original SQL-seeded independent child tombstone preservation test;
the subsequent command/order harnesses exercise actual mutations. Completion
is a nullable signed native-range epoch-millisecond value, validated by both SQL
and the Dart wire checker. Canonical child records are retained in pull; account
projection and full two-device behavior remain future work.

The milestone-commands harness adds real text/completion merges and reopening,
same-field conflict/partial/held cases, successors of a held child with no row,
exact predecessor binding, durable delete identity, both parent/child deletion
orders, restore preservation, concurrent edit/delete, column-grant/RLS ownership
and injected batch rollback. Its shared golden create/edit/delete fixture also
runs through Dart. The older SQL-only child tombstone fixture is retained as
regression coverage.

The milestone-order harness tests atomic list conflicts and exact predecessors,
held child-create dependencies, reordered/additional/deleted children in both
arrival orders, parent restore, immutable retries, malformed commands, isolation
and injected rollback. A shared golden fixture covers Dart requests, validation
and projection alongside real SQL/HTTP. Helpers stay private and ownership scoped.
Order changes do not rewrite child records; child changes do not rewrite accepted
order. Capability checks now use still-unsupported view restoration. Run all thirteen suites
sequentially; the foundation migration rehearsal must not overlap another suite.

The tag suite adds real creation/rename/deletion, normalized-name collisions in
both orders and simultaneous requests, whole-name conflicts, held-before-equivalence
successors with no canonical row, original payloads through receipt/log expiry,
Unicode keys, cross-owner denial and batch rollback. `--candidate` is only for
the rollback-only pre-application smoke; omit it after migration 015 is applied.
Run all eleven command/foundation suites sequentially plus normalization parity.
The subsequent membership suite extends the existing apply RPC; no client
account UI is enabled. Run all twelve suites sequentially. It checks both
add/remove orders, exact task/tag dependencies, held/missing/expired evidence,
independent pairs, both parent-delete orders, restore, UUID replacement isolation,
malformed/semantic rejection, RLS and second-log-write rollback. `--candidate`
is only the rollback-only smoke before applying 016; omit it after application.

The saved-view suite tests complete canonical query validation, independent name
edits, atomic filter conflicts, partial results, exact create/field dependencies,
explicit clearing, both default/delete arrival orders and simultaneous races.
Deletion and a matching default clear share a single revision/pull group;
selecting another view first prevents that clear. A later stale selection of the
deleted view is rejected with retained recovery. RLS, raw REST denial, immutable
ledgers, receipt expiry and injected rollback are covered. Run all thirteen
suites sequentially; never overlap the foundation schema rehearsal with others.
Its `--candidate` option is only for the pre-017 rollback-only smoke; do not use it
on the applied schema. Preserve all eighteen migrations and local volumes/backups.

27 October: migration 019 adds `sync_snapshot_begin`/`sync_snapshot_page`.
Run `python tool/test_backend_snapshots.py --supabase .tools/supabase/supabase.exe
--wire-output .tools/backend-snapshots-wire.json`, then
`dart run tool/check_backend_wire.dart .tools/backend-snapshots-wire.json`.
Use the pinned CLI path appropriate to the machine. All fourteen backend suites
run sequentially; do not overlap the foundation schema rehearsal with any suite.
The snapshot `--candidate` mode is only for the pre-019 rollback-only rehearsal.
Its pages preserve current shadows/deletion IDs and original unresolved recovery;
they do not yet transport historical status events. See the
[recovery audit](../docs/architecture/account-recovery-audit.md).

The Windows restart failure was a host reservation: IPv4 TCP exclusion
54227–54326 included 54321–54324, producing WSAEACCES despite no listener.
A user-approved administrator stop of WinNAT, followed by **only**
`python tool/local_backend.py --start` and restoration of WinNAT in `finally`,
recovered all nine existing containers. No migration, container or volume was
reset, recreated or deleted; stopped pre-loopback backups remain stopped.
This is a diagnosed host repair, not an automatic startup action: check
`netsh interface ipv4 show excludedportrange protocol=tcp` and listeners first;
briefly stopping WinNAT affects other WSL/Hyper-V networking and needs separate
host authorization. It does not establish a permanent reservation fix.
The guard now rejects missing or changed actual bindings and reports Docker's
start error without printing credential-bearing inspect/status output.

28 October: migration 020 adds opt-in history transport (`history_version: 1`) to
pull/snapshot requests. Old clients and tokens retain legacy shapes; the new
codecs reject downgrade/missing history. Run
`python tool/test_backend_history.py --supabase .tools/supabase/supabase.exe
--wire-output .tools/backend-history-wire.json`, then
`dart run tool/check_backend_wire.dart .tools/backend-history-wire.json`.
Its `--candidate` mode is only for the pre-020 rollback-only rehearsal. All fifteen
backend suites run sequentially when using the foundation schema rehearsal.
Keep all twenty applied migrations, volumes and stopped backups. No retention
schedule or account/native integration is activated by this change.

31 October: migration 025 adds private bounded resolved-content retention. Run
`python tool/test_backend_resolved_content.py --supabase .tools/supabase/supabase.exe
--wire-output .tools/backend-resolved-content-wire.json`, then
`dart run tool/check_backend_wire.dart .tools/backend-resolved-content-wire.json`.
Use `--candidate` only for rollback-only rehearsal before 025 is applied. All
nineteen backend suites must run sequentially when the foundation schema rehearsal
is included. Preserve all 24 earlier migrations and the existing stack. See the
[recovery runbook](../docs/runbooks/recovery.md) for the explicit `resolved-content`
operator policy and independent content lifetimes. Scheduling and native account
activation are not enabled; production/release actions remain unauthorized.
