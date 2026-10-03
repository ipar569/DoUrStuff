# 003: Sync consistency

Status: Accepted, 3 October 2026 (user architecture review).

Decision: Field revisions and a transactional per-account change cursor.

Lock account_state across mutation/log/receipt commit. Device timestamps and ordinary SQL sequences cannot substitute for reliable commit ordering. Retain conflict candidates, tombstone identities and device high-water marks; the custom protocol is significant engineering.

Detailed behavior and official comparisons are in the
[accepted design](../proposals/2026-10-03-offline-first-architecture.md).
Acceptance is a design decision, not proof of implementation. See the
[phase report](../verification/phase-1.md) for evidence.
