Implement phase 4 of DoUrStuff: recurrence, calendar, offline local reminders and
snooze on the tested sync foundation. Read root AGENTS.md, README, backlog,
current code and verification reports, accepted architecture at
docs/proposals/2026-10-03-offline-first-architecture.md (especially sections 6–10),
ADRs and docs/runbooks/two-device-testing.md. Apply the repository migration,
sync-protocol and release-verification skills where relevant. Preserve existing
work and use the current repository path/toolchain.

Read docs/proposals/2026-10-09-phase-3-plan.md and
docs/architecture/phase-3-sync.md for the sync boundaries, then use the actual
Phase 3 implementation/report as the current evidence. Read
docs/verification/phase-4.md if it exists; create it when Phase 4 work begins.
Resume the earliest unfinished milestone and preserve working features. Do not
repeat stack selection, reset profiles or restart an already implemented phase.

First verify the phase 3 real Android/Windows two-device acceptance evidence.
If the gate has not passed, complete available phase 3 prerequisites and report
missing external requirements; do not build recurrence/reminders on an unproven
mock integration. The architecture is approved; proceed with implementation
once the gate is met. Ask focused questions only where design materially depends
on the answer. Verify notification packages and OS constraints using current
official documentation before choosing/configuring adapters.

Sequence the work into reviewable milestones: (4.0) audit the Phase 3 gate and
native notification feasibility; (4.1) recurrence domain rules and retained-data
migrations; (4.2) server/client recurrence protocol with real two-device races;
(4.3) month/agenda and occurrence/series editing; (4.4) local reminder planner,
OS adapters and permissions; (4.5) snooze and profile-safe reconciliation;
(4.6) installed notification acceptance. Keep the app usable at each step and
record the milestone's evidence before depending on it. Milestone labels are
delivery organization, not additional product scope or automatic acceptance.

Deliver recurrence offline with daily/weekly/selected-weekday/monthly rules,
intervals and optional end date/count. Follow the accepted civil-date, named-zone,
DST gap/fold and month-end policies. Separate occurrence completion/skipping
from ending a series; preserve completed history. Support editing one occurrence
or the series with explicit future scope. Use the specified bounded generation,
deterministic UUID identities, versioned engine/rule inputs, missed-slot handling
and immutable future segments. Reconcile stale offline generation and recurrence
edits using the documented conflict/recovery policy without duplicate identities
or loss of modified/history occurrences.

Add month and agenda views sharing the task query/filter model. Distinguish
date-only/timed, completed/overdue values; create on a selected day and open task
details. Keep undated tasks available elsewhere. Display deadlines, not duration
blocks. Recurring occurrences must agree between lists and calendar.

Implement real local notifications on supported Android/Windows configurations:

- No reminder, at due, preset/custom offsets and multiple rules within the
  accepted practical limit; configurable date-only reminder time. Ask permission
  when enabling reminders and explain denied/revoked/unsupported states.
- Idempotent reconciliation after edits, sync, resume/restart and relevant system
  changes. Cancel completion/cancellation/deletion. Use bounded nearest-reminder
  scheduling and document platform limits, including rolling-window replenishment
  when the app cannot run in the background.
- Stable logical reminder identities with registration IDs local to each device,
  profile generation guards and per-device enablement. Enabled devices each
  remind by default. Connected completion/snooze reconciles promptly, but offline
  devices may still show stale alerts; never promise exactly-once delivery.
- Preset/custom snooze in-app and from notifications where supported. Snooze
  changes the reminder, never the due date; implement the documented suppression,
  other-rule, recurrence and conflict semantics. Sync logical snooze state.
- Correct account-switch cleanup, fresh-profile isolation and no sensitive
  notification/task content in diagnostic logs.

Use deterministic domain tests for month ends, leap years, count/end rules,
selected weekdays, date-only travel, DST gaps/folds and cache bounds. Test real
SQLite migration/reconciliation and two-device simultaneous offline generation,
recurrence edits, snooze/completion and replay. Run meaningful calendar/widget
tests with large text, keyboard and narrow/wide layouts.

Execute the installed-device notification matrix in the two-device runbook:
Android closed/swiped/force-stop/reboot/Doze/battery/OEM restrictions and permission
changes; Windows installed package identity, close/reboot/sleep/suppression/actions
and upgrade behavior. Use synthetic data and record observed delivery and misses,
OS/package versions and conditions. Widget tests and compilation do not establish
closed-app reliability. Report unsupported/missing-device cases explicitly; no
claims for untested iOS/macOS/Linux.

Once the Phase 3 gate is met, missing Phase 4 devices or platform configuration
must not prevent independent implementation/tests. Leave dependent acceptance
rows explicitly unverified. Local package preparation for identity/notification
testing is within scope; publication and trusted installation on another user's
device require their applicable authorization. Never imply an unpackaged window
proves installed Windows notification behavior.

Update README, backlog, architecture if implementation requires a justified ADR,
and docs/verification/phase-4.md with exact commands/results, observed platform
limits and next steps. Run full quality checks and available builds. Do not push,
deploy, tag or publish without separate authorization. Finish with a concise
delivery/verification/limitations report.

Keep a dated "Next-session handoff" in docs/verification/phase-4.md with current
milestone, delivered versus planned behavior, relevant files, exact commands and
results, device/build identities, failed or unverified gates, missing prerequisites
without secrets, and the next executable action. Preserve previous evidence;
compilation and mocks cannot replace native delivery or two-device tests.
