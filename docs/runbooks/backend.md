# Optional backend and controlled deployment

Local configuration prepared; reviewed 18 October 2026. The local
`supabase/config.toml` was initialized with pinned CLI 2.120.0 and reviewed.
There is no remote project, client authentication adapter or deployment workflow.
A real local stack now runs with five migrations and tested registration/pull
RPCs plus ownership isolation. Atomic apply handles core task creation and
title/priority/status edits, with receipts, recovery candidates, status history
and durable sequence progress.
Other commands and the remaining replication protocol are unfinished.
The guest app ignores sync configuration.

## Running local foundation — 16 October 2026

The Docker update is verified: Desktop 4.95.0, Engine 29.8.2/API 1.56, Linux amd64.
Pinned CLI 2.120.0 starts PostgreSQL 17.11 and its local services. Image identities
are in `supabase/images.lock.json`; `python tool/local_backend.py` verifies them,
health and actual loopback-only publishing. Use `--start` for an existing-stack
restart. Do not recreate the containers with plain CLI startup on this host:
its network-default loopback setting was ignored. The project-only repair and
preserved stopped originals are described in [local setup](../../supabase/README.md).

The first migration assigns account ownership under RLS and exposes only
registration/pull. A second forward migration supplies private fixed-path
identity helpers because the managed `auth` schema's usage grant cannot be
delegated by the ordinary migration owner. Real HTTP tests caught that failure.
Eight integration groups now pass, including synthetic Auth X/Y, raw REST/RPC
bypass denial, cursor retention and actual PostgreSQL lock ordering. These are
local server checks; no native GitHub OAuth or real two-device evidence is implied.
See the verification report for the failed first attempts and exact commands.

17 October adds `20261017000100_causal_task_edits.sql` and the real HTTP apply
harness. Canonical changes, recovery candidates, receipts, log revisions and
watermarks commit under the account lock. Unsupported commands fail preflight;
invalid supported values receive terminal rejection receipts with retained repair
data. Synthetic fault injection verifies rollback after entity/receipt writes.
The migration suite rehearses all three migrations without resetting live data.
See `supabase/README.md` for exact commands, partial scope and wire-parity limits.

## Core creation/status — 18 October 2026

18 October adds the forward migration `20261018000100_task_create_status.sql`.
The pre-migration application dump is `.tools/backend-before-create-status.sql`;
it is not a restore rehearsal. Creation collisions never merge fields; status
and completion time form one group. Private status history survives reopening
and detailed-receipt removal. History download and deletion/retention integration
are pending. Run all three backend suites in `supabase/README.md` sequentially:
the foundation suite temporarily rebuilds the application schema inside a
rollback-only transaction, so it must not overlap other integration suites.

Review adds migration 005, `20261018000200_status_history_identity.sql`:
unchanged status values add no history, and history retains exact operation
envelopes beyond receipt expiry. Backfill uses available receipts only; older
events with expired receipts remain intact with unknown payloads. Their operation
IDs still cannot be assigned to new work. The pre-fix local dump is
`.tools/backend-before-history-fix.sql`. Neither dump is a restore rehearsal.

## Local configuration / runtime gate — 13 October 2026

`supabase init` succeeded through approved escalation. The project ID is
`dourstuff-local`; API auto-exposure of new objects, seed execution, analytics
and the unused edge runtime are disabled. TOML syntax and these settings were
checked locally. See [local backend setup](../../supabase/README.md).

The installed Docker Engine 23.0.5 responds, but current
[Docker documentation](https://docs.docker.com/engine/network/port-publishing/)
documents localhost-port exposure to the same L2 network before Engine 28.
This project requires Engine 28+ before starting the port-published local stack;
this is a project isolation prerequisite, not a tested CLI compatibility failure.
The user was asked about updating Docker while independent protocol work
continued. No Supabase service/container was started. After updating, use a
dedicated loopback-bound network as documented by
[Supabase](https://supabase.com/docs/guides/local-development), then check actual
bindings/health and retain image digests. Do not treat generated config or a
responsive daemon as successful server integration.

16 October recheck: the installed Desktop executable still reports
4.19.0.106363; the discovered Docker client is 23.0.5 and `docker version`
fails with the daemon pipe absent. The user previously said they would update
Docker; completion has not been verified. Recheck the actual running engine
after the update rather than treating the client version as server evidence.

## CLI setup unblocked — 13 October 2026

After the user changed the permission mode to allow approval requests, an
explicit `require_escalated` request for the official download/check/extract/
version/help sequence succeeded. CLI **2.120.0** is installed in the optional,
ignored `.tools/supabase/` directory and pinned in `.supabase-version`. The ZIP
SHA256 matched
`0db5224fc5d92ae5f15e675ed65dad376967326921122ab8d9a78e790874c92e`.
`supabase.exe --version`, `start --help` and `init --help` all passed.

An initial sandboxed `init --help` attempt failed with EPERM writing the CLI's
normal `C:/Users/ipar5/.supabase/telemetry.json.tmp.*` configuration. Retrying
through approved escalation succeeded. Docker Desktop was started with hidden
`Start-Process`; the sandboxed engine check then failed with pipe access denied.
Approved `docker version` returned client/server 23.0.5, API 1.42, Linux amd64
engine on Desktop 4.19.0. These supersede the installation block below without
erasing the earlier failures.

No Supabase project was initialized or stack started. The pin is tested for
CLI execution/help, not full stack compatibility. Next complete the 3.0 wire
and policy fixtures, then initialize/review local-only configuration, start the
stack through the normal approval flow and verify health before 3.1 tests.
Do not use `--ignore-health-check` as evidence of successful setup. No production
endpoint, OAuth configuration or deployment was changed.

## Readiness update — 12–13 October 2026

The user accepted emulator entry evidence for local Phase 3. After starting
Docker Desktop, `docker version` reached both client and Linux server 23.0.5
(API 1.42); Docker Desktop 4.19.0 (106363), containerd 1.6.20, runc 1.1.5.
The first startup check still failed on `docker_engine_linux`; the later check
passed. `wsl --status` reported version 2. This does not prove compatibility with
the eventual Supabase stack; no project/containers/health checks ran.

Official release metadata identified [CLI v2.120.0](https://github.com/supabase/cli/releases/tag/v2.120.0),
published 6 October, as a candidate. The Windows amd64 ZIP metadata SHA256 was
`0db5224fc5d92ae5f15e675ed65dad376967326921122ab8d9a78e790874c92e`.
It is **not a tested pin**. Automatic approval review rejected the combined
download/check/extract/`--version`/`start --help` command before execution,
reporting only `blocked by policy`, without a more specific reason. No alternate
installation path was attempted. CLI setup remains unresolved; an operator
must supply an installed approved CLI before version/help and stack checks can
continue. Do not assume Docker will still be running next session.

Independent work now includes the [account v2 contract foundation](../architecture/account-protocol-v2.md)
and executable field-chain model. Full wire codecs, server semantics, dependency
pins and real PostgreSQL/RLS evidence remain pending. No endpoint or OAuth
configuration was provisioned; no paid resources were selected.

13 October permission follow-up: the user explicitly set the desktop app to
Full Access to allow CLI setup. One scoped retry of the same official ZIP
download, expected SHA256 check, extraction and version/help commands was still
rejected before process creation with `blocked by policy`. Full Access did not
clear the execution restriction; no more specific rationale was returned.
The suggested `/approve` command was unavailable in this user's desktop app.
Do not repeat that guidance or claim an app override is verified. CLI setup
remains blocked; no alternate execution mechanism was attempted.

## Readiness checked on 10 October 2026

`docker version` found client 23.0.5 but failed to connect to the default
`docker_engine` named pipe. No working daemon or local Supabase stack was
established. `Get-Command supabase -ErrorAction SilentlyContinue` found nothing
on PATH; neither `supabase/` nor `.tools/supabase` exists in this checkout.
This is not a machine-wide installation search. Node is v24.14.0; no CLI version
has been installed/pinned/tested for this project.

After the Phase 2 Android entry gate passes, start a Docker-compatible runtime,
confirm both client and server in `docker version`, select and pin the Supabase
CLI, inspect its help, then initialize/start a local project and test its health.
The [official CLI guide](https://supabase.com/docs/guides/local-development/cli/getting-started)
requires Node 20+ for npm/npx usage and a working container runtime. These setup
steps are pending, not executed results. Native OAuth also needs a restricted
development endpoint reachable from the phone and exact redirect registration.
No endpoint, provider configuration or credentials were verified here.

The [upstream Flutter README](https://github.com/supabase/supabase-flutter/blob/main/packages/supabase_flutter/README.md#custom-session-storage),
reviewed on 10 October, now describes `AuthAsyncStorage` through `asyncStorage`
for both sessions and PKCE verifiers. Default persistence uses
`SharedPreferencesAsync`; `persistSession: false` still persists PKCE verifiers.
Replace persistence explicitly and scope pending sign-in attempts as well as
account sessions. This is moving-main documentation, not a tested dependency
pin; verify APIs and native restart/sign-out cleanup against the selected release.

The accepted architecture sections 8–9 define server tables, cursor locking,
field revisions, receipts, bootstrap snapshots, retention and account isolation.
Supabase supplies primitives, not this replication implementation.

## Configuration when phase 3 ships

Create an optional Free project, configure GitHub OAuth/PKCE and strict native
redirect allowlists. Store the OAuth secret in provider configuration. App
configuration contains only project URL and publishable key. Database passwords,
management tokens and service-role credentials never belong in the app or Git.
Auth tokens use secure platform storage, isolated by account.

Every exposed owned table needs RLS and ownership-checked composite references.
RPCs derive the owner from auth.uid(), fix search_path and restrict EXECUTE.
Deny anonymous access and writes bypassing command sequencing. Test raw REST/RPC
with accounts X/Y including logs/conflicts/snapshots. Public keys are not access
controls.

## Deployment procedure to implement with real migrations

Use manual workflow_dispatch on a reviewed commit, a protected environment,
contents:read, timeout and one concurrency group per environment. Put
SUPABASE_ACCESS_TOKEN, project reference and database password in that
environment only; no production secrets in PR jobs.

Before apply: empty/reset and retained-data upgrade tests, RLS/protocol tests,
old-client compatibility, reviewed diff and verified backup. Apply the exact
migrations, then synthetic-owner smoke/access checks. Use expand/contract since
offline clients may be old. Fail visibly; no automatic destructive rollback.
Prefer a tested forward fix. If restoring older server state, increment server
epoch and require snapshot/recovery. Record deployed commit and migration IDs.

Free tier has no automatic backups. Dumps contain private data and must not go
in public Actions artifacts or logs. Rehearse restoration; a successful dump
alone is not recovery evidence.

## Account/data deletion

Until the in-app path ships, an operator can export requested data, revoke
sessions, delete owned records including snapshots/logs/conflicts/receipts, then
delete the Auth user in the Dashboard and verify cleanup. Phase 3 must provide
a recent-auth, resumable server-side deletion path; admin keys stay server-side.
Offline copies cannot be remotely erased. Explicitly remove retained local
copies. Phase 1 has no account data to delete remotely.
