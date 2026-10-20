# Local backend — Phase 3.1 foundation

Initialized with CLI **2.120.0**, pinned in `../.supabase-version`. Configuration
is for the synthetic `dourstuff-local` project only. No remote project is linked.
Six migrations now provide private account/device/log storage, RLS, restricted
device-registration/pull RPCs, atomic core task creation and title/priority/status/
description/estimate edits.
Apply stores canonical fields, immutable receipts, recovery candidates and device
watermarks together, with durable status history. Creation requires the four
core groups documented in the [v2 contract](../docs/architecture/account-protocol-v2.md),
with optional description and nullable estimate;
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
