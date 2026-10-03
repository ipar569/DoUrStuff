# 002: Optional backend

Status: Accepted, 3 October 2026 (user architecture review).

Decision: Optional Supabase Auth/PostgreSQL after immediate guest start.

Free managed hosting reduces recurring costs. The app owns sync and recovery; free pauses/read-only limits must not block local edits. GitHub OAuth avoids required production SMTP. No paid replication service.

Detailed behavior and official comparisons are in the
[accepted design](../proposals/2026-10-03-offline-first-architecture.md).
Acceptance is a design decision, not proof of implementation. See the
[phase report](../verification/phase-1.md) for evidence.
