# Local backend — Phase 3.1 foundation

Initialized with CLI **2.120.0**, pinned in `../.supabase-version`. Configuration
is for the synthetic `dourstuff-local` project only. No remote project is linked.
Three migrations now provide private account/device/log storage, RLS, restricted
device-registration/pull RPCs and atomic title/priority edits on existing tasks.
Apply stores canonical fields, immutable receipts, recovery candidates and device
watermarks together. Other commands, snapshots and resolution remain unfinished.
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
python tool/test_backend_foundation.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-foundation-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-foundation-wire.json
python tool/test_backend_apply.py --supabase .tools/supabase/supabase.exe --wire-output .tools/backend-apply-wire.json
.tools/flutter/bin/dart.bat run tool/check_backend_wire.dart .tools/backend-apply-wire.json
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
and late commits. It seeds existing tasks through SQL because creation is not
implemented yet. The Dart checker decodes real replies and compares title validity
with the app's validator, including Unicode whitespace and UTF-16 length cases.

Unsupported commands/groups/dependencies fail whole-batch preflight without
consuming sequences. No scheduled pruning is installed; expiry tests remove only
synthetic receipts. JSONB cannot represent embedded NUL and normalizes some input
number spellings before validation; complete wire/semantic parity remains a gate
before client activation. Native GitHub PKCE, snapshots, full command
validation, explicit resolution and two-device integration remain open. See the
[verification report](../docs/verification/phase-3.md) for failures and exact results.
