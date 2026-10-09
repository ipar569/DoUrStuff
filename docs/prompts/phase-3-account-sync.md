Implement phase 3 of DoUrStuff: optional accounts and real automatic two-device
sync. Use the repository opened in this session; do not assume an absolute path.
Start or resume by reading AGENTS.md, README.md, backlog,
latest verification reports, architecture/ADRs and the complete accepted proposal
at docs/proposals/2026-10-03-offline-first-architecture.md, especially sections
5, 8 and 9. Also read docs/proposals/2026-10-09-phase-3-plan.md,
docs/architecture/phase-3-sync.md, docs/architecture/phase-2-offline.md and
docs/verification/phase-3.md. The diagrams are planned behavior, not evidence.
Read docs/runbooks/backend.md, costs.md, recovery.md and
two-device-testing.md. Apply .agents/skills/sync-protocol/SKILL.md and the migration
skill. Inspect Git status/code and preserve existing work. Resume the earliest
unfinished milestone from the report; do not recreate delivered components or
overwrite unrelated changes. If a later session has already implemented part of
Phase 3, verify that work and continue its missing behavior and acceptance checks.

The architecture is approved: Flutter/Drift local authority with optional Supabase
and GitHub OAuth/PKCE, isolated profile databases and secure token storage. Do not
restore the legacy web app or replace the accepted consistency model with
whole-record last-write-wins. The 9 October planning baseline has implemented
Phase 2 features, user-confirmed Windows offline/restart persistence and an open
Android fresh-install/offline/process-restart gate. Recheck the latest report;
do not treat this dated baseline as current proof. Preserve the condition that
Phase 2 finishes before Phase 3 implementation. Complete available prerequisite
fixes/tests first. If required device evidence is unavailable, continue useful
Phase 2 verification and Phase 3 planning, leave dependent implementation gated,
and record the exact missing device/setup action. Keep separate retained native
accessibility, clock-change and platform feasibility gates visible.

Once the entry gate passes, this prompt authorizes Phase 3 implementation and
testing; the delivery plan's original planning-only status does not require a
second architecture approval. Ask only material design questions or for missing
external configuration. Keep guest mode usable and account features gated until
all existing commands and recovery paths are supported.
Verify current provider capabilities, limits, free-tier inactivity and pricing
from official sources; document changes. Avoid paid sync services/custom servers.

Follow the delivery plan in reviewable milestones, recording evidence after each:

1. 3.0: readiness and protocol fixtures. Specify original base values, typed RPC
   results, immutable payload identity, field groups and predecessor binding.
   Resolve how held dependent edits coexist with contiguous device sequences
   without blocking unrelated work. Prove this with a conflict/dependent/unrelated
   operation fixture; never skip assigned sequences or silently rebase an edit.
   Define entity-kind/composite identities, tag-name collisions, deleted default
   views and explicit restore preconditions. Plan the minimal local upgrade.
2. 3.1: real server migrations, apply/pull, revisions, receipts and ownership tests.
3. 3.2: retained-data local migration, account profiles, secure auth and native
   GitHub PKCE feasibility. Verify default SDK persistence is replaced wherever
   sessions or PKCE verifiers require secure storage; pin the tested dependencies.
4. 3.3: a complete create/title/status slice from SQLite through a real backend
   to a second client, with crash/retry tests. This is an engineering milestone,
   not permission to claim Phase 3 complete.
5. 3.4: every Phase 2 command, snapshots, conflict recovery and automatic catch-up.
6. 3.5: consent/adoption, account lifecycle, recovery export and deletion.
7. 3.6: installed two-device acceptance, measured latency, backend CI and recovery
   rehearsal before preparing the protected deployment workflow.

Implement the full backend and client contract:

- Versioned PostgreSQL migrations, ownership/RLS for all user data, narrowly
  authorized RPCs and tests proving other accounts/anonymous users cannot read
  or mutate records, logs, snapshots or conflicts. No privileged app keys.
- Atomic local mutations and durable outbox; stable client IDs; immutable
  idempotent operations; device epochs/sequences and durable high-water marks;
  original field base values/revisions and dependent operations. Complete the
  guest-only command guard with proper account behavior, not guessed base versions.
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
  caches, callbacks and notification intents. An expired session in an open
  account permits offline editing; reopening an explicitly signed-out profile
  requires authentication. Default sign-out retains pending work. Provide a
  usable recovery export before offering removal of unsynced data or account
  deletion; full portable import/export UX remains Phase 5. Account/data deletion
  needs recent auth, explicit confirmation, immediate access denial and resumable
  server cleanup. Old devices must not recreate a deleted account.
- Protected, least-privilege backend deployment workflow only after real
  migrations, dry-run/test gates and a concrete recovery procedure exist. Keep
  secrets out of PRs and logs. Preparing deployment is authorized; production
  migration execution requires separate authorization.

Use a real local/development Supabase stack where available. Complete meaningful
server integration, RLS, client fault-injection and end-to-end tests. Exercise
duplicate/dropped responses, crashes, interrupted downloads, expired auth and
cursor, both reconnect orders, backend outage and account switching. Mock
transport checks supplement, but cannot replace, real backend/device evidence.
Check Docker/runtime and CLI readiness instead of assuming PATH discovery proves
a working stack. Use a restricted development endpoint reachable from the phone,
not PC localhost. Never put OAuth secrets or privileged keys in app config/chat.
Retain supported SQLite snapshots and upgrade fixtures; do not overwrite v1 to
make tests pass. Test snapshot expiry, retention boundaries, old receipts and
server-epoch changes using controlled fixtures while preserving pending work.

Execute docs/runbooks/two-device-testing.md with synthetic data on Android and
Windows. Measure at least 100 foreground changes with realtime enabled and
another 100 with it disabled: p95 <=5 seconds from local commit to second-device
display normally; polling fallback p95 <=35 seconds. Use a healthy backend,
RTT <=150ms and include a 10,000-task fixture for the accepted scale. Use one
monotonic harness or calibrated clocks. Verify task creation, completion, milestones,
priorities, saved views, offline conflicts and deletion without manual refresh.
Record exact devices/builds/timing method and results. Do not promise continuous
background sync or mark the gate passed without this evidence.

After the Phase 2 entry gate passes, if credentials, endpoints or devices are
missing, continue independent Phase 3 implementation/testing, then state exact
prerequisites and leave the real two-device gate open. Never fabricate integrations
or credentials. Phase 4
recurrence/reminders must wait for that gate. Update docs/verification/phase-3.md,
README, setup/cost/backend/recovery runbooks and backlog. Run quality checks and
available native builds. Do not push or publish unless separately authorized.
Do not execute production migrations or change real account data. Test account
deletion only with synthetic fixtures under this implementation prompt.

Keep a dated "Next-session handoff" in docs/verification/phase-3.md containing
the current milestone; delivered versus planned behavior; relevant files;
exact commands/results and tested revision/working-tree caveats; remaining
failures/unverified gates; external prerequisites without secrets; and the
next executable action. Preserve historical failures and evidence. Do not call
the phase complete while its real integration/native/two-device gates are open.
End with delivered behavior, exact results and remaining limitations.
