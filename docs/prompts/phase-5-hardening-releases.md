Implement phase 5 of DoUrStuff: backup/portability, hardening and release
readiness. Inspect the current repository and Git status; read AGENTS.md, README,
backlog, all current verification reports, architecture and ADRs, the accepted
proposal at docs/proposals/2026-10-03-offline-first-architecture.md and runbooks
for recovery, releases, backend, costs and two-device testing. Apply the relevant
repository migration, sync-protocol and release-verification skills. Preserve
existing work and never restore the legacy web app.

Read docs/proposals/2026-10-09-phase-3-plan.md and
docs/architecture/phase-3-sync.md for recovery/account boundaries, and inspect the
actual implementation rather than treating planned diagrams as working features.
Read docs/verification/phase-5.md if present; create it when work begins. Resume
its earliest unfinished milestone. Extend any Phase 3 recovery export into the
full portability feature rather than introducing a competing format or losing
unsynced values/conflict candidates.

The architecture is approved. Verify phases 2–4 from code and actual evidence,
finish necessary product gaps, and carry external verification gaps forward
honestly. Proceed with implementation and testing; ask only focused material
questions or for necessary external setup. Verify current build/signing/store
requirements and costs using official documentation. Target no recurring backend
cost for small personal use; distinguish it from signing/distribution costs.

Sequence reviewable milestones: (5.0) audit prior acceptance and artifact
identities; (5.1) versioned export/import with preview and safe recovery;
(5.2) retained-data migration, restore and security hardening; (5.3) installed
accessibility and representative performance; (5.4) package/signing preparation
and upgrade-data retention; (5.5) acceptance ledger, release notes, hashes and
release-readiness report. Independent portability/hardening work may continue
with external gates open, but release readiness requires the relevant earlier
phase/device gates. Never bypass Phase 3's gate to implement Phase 4 dependencies.

Deliver versioned, documented local export/import without an account. Include
tasks, tags, milestones, priorities, recurrence definitions/history, saved views
and portable settings; exclude credentials, profile transport identities and
device notification IDs. Validate schema, values, relationships, sizes and
versions before mutation; preview duplicate handling, merge and replace scope.
Implement stable import mappings and crash-safe retry, preserve existing data,
confirm destructive replacement and create a recoverable backup. In account
profiles, produce valid new sync operations rather than replaying exported
outboxes/revisions. Reconcile notifications after import. Exercise older-format
compatibility and document treatment of snooze state and shared preferences.
Include unresolved recovery data and unsynced current values. Preserve lineage
mapping compatibility with guest adoption and the existing recovery export.
Exclude trusted transport state: imported data gets fresh operation identities
and current authorization, not restored server cursors or old device sequences.

Harden migration and recovery: retain schema snapshots, test real prior-version
upgrades with data, transaction interruption/rollback, downgrade refusal,
WAL-consistent backup/restore, disk-full behavior where safely reproducible and
corrupt/unsupported imports. Never erase a database on migration failure.
Verify server recovery epochs and long-offline device recovery do not resurrect
deleted data or lose unsynced edits. Recheck cross-account access controls.

Audit accessible contrast, 200% text, screen-reader names, keyboard navigation,
focus, touch targets and save/error/sync feedback on installed targets. Verify
performance with representative larger datasets and practical offline behavior
during backend/auth failure. Complete the original 21-point acceptance ledger
with actual evidence, including real two-device and notification checks from
the runbook. Record missing prerequisites instead of claiming untested success.

Prepare Android/Windows releases with stable version/package/signing identities,
upgrade-data retention tests, checksums, release notes, screenshots, setup and
recovery documentation. Distinguish debug APK, unsigned APK, signed personal APK,
unpackaged Windows ZIP, trusted signed MSIX and store artifacts. Add real protected
signing workflows only with explicit required-secret handling and verified
artifact output; no debug-key fallback or pretend successful placeholder jobs.
Keep least-privilege permissions, SHA-pinned Actions and production secrets out
of PR workflows. Store upload/publication remains separate from downloadable
build artifacts. Do not invent credentials or claim signing without verification.

Implementation and local verification are authorized. Do not push, create release
tags, publish GitHub/store releases, spend money or deploy production migrations
unless the user separately authorizes that action. Prepare concrete reviewable
artifacts and notes before requesting any missing publication authorization.
If credentials, signing certificates, store accounts or devices are absent,
complete independent work and document exact blocked operations/setup steps.

Run quality checks, meaningful portability/migration/security/UI tests and native
builds on available hosts. Update README, CHANGELOG, backlog, runbooks, operating
costs/limitations and docs/verification/phase-5.md with exact results, artifact
hashes and the full acceptance ledger. Preserve historical reports and separate
observed behavior from assumptions. Keep iOS/macOS/Linux and deferred features
explicitly unverified until actually tested. End with delivered functionality,
verification results, release readiness and remaining prerequisites.

Keep a dated "Next-session handoff" in docs/verification/phase-5.md with current
milestone, delivered versus planned behavior, relevant files, exact commands and
results, artifact paths/hashes and signing status, failed/unverified acceptance
rows, missing prerequisites without secrets, and the next executable action.
Distinguish "ready for review", "verified release candidate" and "published";
the last state requires an authorized publication and its actual result.
