# 004: Account isolation

Status: Accepted, 3 October 2026 (user architecture review).

Decision: Separate guest/account SQLite files, explicit adoption and secure tokens.

Immutable profile metadata guards files. Switching closes jobs/streams and cancels prior notifications; callbacks carry profile generations. Guest data never uploads silently. OS-profile trust does not imply encrypted task files or E2EE.

Detailed behavior and official comparisons are in the
[accepted design](../proposals/2026-10-03-offline-first-architecture.md).
Acceptance is a design decision, not proof of implementation. See the
[phase report](../verification/phase-1.md) for evidence.
