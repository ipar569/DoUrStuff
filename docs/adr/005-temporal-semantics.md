# 005: Temporal semantics

Status: Accepted, 3 October 2026 (user architecture review).

Decision: Civil dates, fixed one-off instants and named-zone recurrence.

Do not turn date-only values into UTC midnight. Recurrence retains wall time: advance DST gaps by the gap; choose the earlier fold instant. Monthly dates clamp but retain their anchor. Immutable segments and ordinal UUIDv5 identities deduplicate offline generation.

Detailed behavior and official comparisons are in the
[accepted design](../proposals/2026-10-03-offline-first-architecture.md).
Acceptance is a design decision, not proof of implementation. See the
[phase report](../verification/phase-1.md) for evidence.
