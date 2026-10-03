Implement phase 3 of DoUrStuff: optional accounts and real automatic two-device
sync. Start in the current repository by reading AGENTS.md, README.md, backlog,
latest verification reports, architecture/ADRs and the complete accepted proposal
at docs/proposals/2026-10-03-offline-first-architecture.md, especially sections
5, 8 and 9. Read docs/runbooks/backend.md, costs.md, recovery.md and
two-device-testing.md. Apply .agents/skills/sync-protocol/SKILL.md and the migration
skill. Inspect Git status/code and preserve existing work.

The architecture is approved: Flutter/Drift local authority with optional Supabase
and GitHub OAuth/PKCE, isolated profile databases and secure token storage. Do not
restore the legacy web app or replace the accepted consistency model with
whole-record last-write-wins. Verify phase 2 prerequisites from actual evidence;
finish necessary gaps before depending on them. Proceed with implementation,
asking only material design questions or for missing external configuration.
Verify current provider capabilities, limits, free-tier inactivity and pricing
from official sources; document changes. Avoid paid sync services/custom servers.

Implement a real backend and client:

- Versioned PostgreSQL migrations, ownership/RLS for all user data, narrowly
  authorized RPCs and tests proving other accounts/anonymous users cannot read
  or mutate records, logs, snapshots or conflicts. No privileged app keys.
- Atomic local mutations and durable outbox; stable client IDs; immutable
  idempotent operations; device epochs/sequences and durable high-water marks;
  field base revisions and dependent operations. Complete the guest-only
  command guard with proper account behavior, not empty guessed base versions.
- Transactionally ordered per-account change cursors, apply/pull RPCs, durable
  acknowledgements, incremental pagination and resumable consistent snapshots.
  Do not use device timestamps or a sequence vulnerable to late-commit gaps as
  conflict/download ordering. Follow the documented retention, tombstone and
  expired-cursor recovery policy, preserving pending work through rebootstrap.
- Preserve unrelated concurrent edits; retain meaningful same-field candidates
  with conflict recovery UI. Implement and test completion/edit, delete/edit,
  milestone/order, shared preferences and saved-view policies. Retain compatible
  contracts for recurrence/reminders; those product features remain phase 4.
- Automatic foreground/resume/reconnect sync with retry/backoff, auth-expiry
  recovery, realtime hints and reliable catch-up/polling. SQLite remains the
  only UI read/write path; server/auth failures cannot block local editing.
- Explicit guest adoption consent with stable lineage mappings and retry-safe
  merge, guest preservation, additional-device download progress, no overwrite
  of concurrent local tasks, pending-versus-acknowledged states, last success
  and actionable errors. No silent guest upload.
- Secure tokens and tested deep-link/PKCE handling on Android/Windows; safe
  sign-out/account switching with unsynced edits and isolation of databases,
  caches, callbacks and notification intents. Provide account/data deletion.
- Protected, least-privilege backend deployment workflow only after real
  migrations, dry-run/test gates and a concrete recovery procedure exist. Keep
  secrets out of PRs and logs. Preparing deployment is authorized; production
  migration execution requires separate authorization.

Use a real local/development Supabase stack where available. Complete meaningful
server integration, RLS, client fault-injection and end-to-end tests. Exercise
duplicate/dropped responses, crashes, interrupted downloads, expired auth and
cursor, both reconnect orders, backend outage and account switching. Mock
transport checks supplement, but cannot replace, real backend/device evidence.

Execute docs/runbooks/two-device-testing.md with synthetic data on Android and
Windows. Measure at least 100 foreground changes: p95 <=5 seconds from local
commit to second-device display for healthy backend, RTT <=150ms and <=10k tasks;
polling fallback p95 <=35 seconds. Verify task creation, completion, milestones,
priorities, saved views, offline conflicts and deletion without manual refresh.
Record exact devices/builds/timing method and results. Do not promise continuous
background sync or mark the gate passed without this evidence.

If credentials, endpoints or devices are missing, continue all independent
implementation/testing, then state exact prerequisites and leave the real
two-device gate open. Never fabricate integrations or credentials. Phase 4
recurrence/reminders must wait for that gate. Update docs/verification/phase-3.md,
README, setup/cost/backend/recovery runbooks and backlog. Run quality checks and
available native builds. Do not push or publish unless separately authorized.
End with delivered behavior, exact results and remaining limitations.
