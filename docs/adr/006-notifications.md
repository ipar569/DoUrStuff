# 006: Notifications

Status: Accepted, 3 October 2026 (user architecture review).

Decision: OS-local scheduling with per-device enablement and bounded reconciliation.

Plan nearest 48 reminders within 30 days with visible coverage. Snooze changes reminder state, not due dates. Offline devices can show stale alerts. No global exactly-once promise; physical closed/reboot tests are mandatory.

Detailed behavior and official comparisons are in the
[accepted design](../proposals/2026-10-03-offline-first-architecture.md).
Acceptance is a design decision, not proof of implementation. See the
[phase report](../verification/phase-1.md) for evidence.
