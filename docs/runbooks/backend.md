# Optional backend and controlled deployment

Design/runbook only in phase 1. No project, migrations, RPCs, authentication,
RLS or deployment workflow has been provisioned. The guest app ignores sync
configuration. Implement local Supabase configuration, pinned CLI, real SQL
tests and migrations in phase 3 before adding an executable deployment job.

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
