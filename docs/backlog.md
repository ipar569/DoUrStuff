# Phased backlog

Use the [fresh-session prompts](prompts/README.md) to continue each phase in a
new session. Always check current verification evidence before its next gate.

## Phase 1: foundation

Source delivered: Flutter guest shell, capture/complete/reopen, schema v1,
atomic journal/history/dirty writes, profile guard, migration/downgrade boundary,
protocol/occurrence fixtures, docs/skills and quality/native/release CI.

Remaining gates: installed Android/Windows launch evidence, Windows C++ tooling,
hosted CI run, secure-storage and notification feasibility on installed targets.
See the phase report for actual compilation results. Phase 1 is not fully
platform-verified and does not implement cloud sync or reminders.

## Phase 2: offline application

Full task CRUD/edit/delete/undo; due date/time and duration validation; priority
indicators; tags/milestones; search/filter/group/sort queries; Today/Upcoming/
Overdue/All; saved views and preferences; responsive navigation and accessibility.
Add Riverpod only when shared controller state warrants it. All commands remain
atomic with the journal.

## Phase 3: accounts and tested two-device sync

Real Supabase migrations/RPC/RLS tests; secure tokens and GitHub PKCE; explicit
adoption; resumable bootstrap; field conflicts and recovery UI; cursor/receipts/
tombstones/high-water; catch-up/realtime/retries; sign-out/switch/deletion.
Prove p95 <=5 seconds over 100 changes under the documented test conditions.
Add protected migration deployment only with real tested migrations and recovery.
This gate precedes recurrence and reminders.

## Phase 4: recurrence, calendar and reminders

Bounded deterministic generation/history; immutable future segments and offline
series conflicts; month/agenda; DST/month-end fixtures; OS adapters, permissions,
snooze and reconciliation; closed/reboot/force-stop installed-device evidence.

## Phase 5: backup, hardening and releases

Versioned export/import validation, mapping/preview/safe replace; migration and
crash recovery; accessibility; signed APK/MSIX and upgrade evidence; protected
signing and optional store jobs with real credentials; screenshots and docs.

Deferred: iOS/macOS/Linux verification, light theme, other auth providers,
optional encryption/E2EE ADR and OS-permitted background improvements. No
sharing, attachments, AI or calendar time-block scheduling in v1.
