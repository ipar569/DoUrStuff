# 001: Native stack

Status: Accepted, 3 October 2026 (user architecture review).

Decision: Flutter with Drift/SQLite and a shared Dart codebase.

Flutter offers consistent native persistence/UI for Android and Windows. PWA lacks the offline scheduled-reminder contract; Tauri adds Rust/webview work; React Native Windows is a separate platform; MAUI has a weaker Linux path. Native integration still needs per-platform evidence.

Detailed behavior and official comparisons are in the
[accepted design](../proposals/2026-10-03-offline-first-architecture.md).
Acceptance is a design decision, not proof of implementation. See the
[phase report](../verification/phase-1.md) for evidence.
