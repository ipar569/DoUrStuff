Implement phase 4 of DoUrStuff: recurrence, calendar, offline local reminders and
snooze on the tested sync foundation. Read root AGENTS.md, README, backlog,
current code and verification reports, accepted architecture at
docs/proposals/2026-10-03-offline-first-architecture.md (especially sections 6–10),
ADRs and docs/runbooks/two-device-testing.md. Apply the repository migration,
sync-protocol and release-verification skills where relevant. Preserve existing
work and use the current repository path/toolchain.

First verify the phase 3 real Android/Windows two-device acceptance evidence.
If the gate has not passed, complete available phase 3 prerequisites and report
missing external requirements; do not build recurrence/reminders on an unproven
mock integration. The architecture is approved; proceed with implementation
once the gate is met. Ask focused questions only where design materially depends
on the answer. Verify notification packages and OS constraints using current
official documentation before choosing/configuring adapters.

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

Update README, backlog, architecture if implementation requires a justified ADR,
and docs/verification/phase-4.md with exact commands/results, observed platform
limits and next steps. Run full quality checks and available builds. Do not push,
deploy, tag or publish without separate authorization. Finish with a concise
delivery/verification/limitations report.
