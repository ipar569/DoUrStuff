# 007: Distribution

Status: Accepted, 3 October 2026 (user architecture review).

Decision: Personal signed Android APK and Windows MSIX before public stores.

Stable signing/package identities protect upgrade continuity. Unsigned APK and unpackaged Windows ZIP are review artifacts. Signing/store jobs wait for real credentials and installed-device evidence. Apple/Linux remain planned.

Detailed behavior and official comparisons are in the
[accepted design](../proposals/2026-10-03-offline-first-architecture.md).
Acceptance is a design decision, not proof of implementation. See the
[phase report](../verification/phase-1.md) for evidence.
