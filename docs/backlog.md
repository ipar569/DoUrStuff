# Phased backlog

Use the [fresh-session prompts](prompts/README.md) to continue each phase in a
new session. Always check current verification evidence before its next gate.

## Phase 1: foundation

Source delivered: Flutter guest shell, capture/complete/reopen, schema v1,
atomic journal/history/dirty writes, profile guard, migration/downgrade boundary,
protocol/occurrence fixtures, docs/skills and quality/native/release CI.

Remaining gates: installed Android/Windows package evidence,
secure-storage and notification feasibility on installed targets. Hosted quality
and Android/Windows native jobs passed for the Phase 1 baseline.
See the phase report for actual compilation results. Phase 1 is not fully
platform-verified and does not implement cloud sync or reminders.

## Phase 2: offline application

Source delivered: full task capture/view/edit/status/delete, guarded deletion and
status undo; civil and timed due values with IANA gap/fold resolution; estimates,
labelled priority, reusable tags and independent ordered milestones; token
search and combined filters, deterministic sorts/groups; built-in and saved
views with a persistent default; responsive dark navigation/editor, keyboard
shortcuts, failed-save draft retention and bulk-delete confirmation.
The 5 October capture refinement places title and optional due date together,
with Today/Tomorrow/custom-date shortcuts. Editors initially collapse the other
fields under More details; existing values remain intact when saving.

All mutations use SQLite transactions with local journal/history/sequence/dirty
intent. Schema remains v1; tags, milestones and views now have commands and validators.
No Riverpod dependency was needed for this screen-owned state.

See [Phase 2 verification](verification/phase-2.md) for exact host checks and
native build evidence. Remaining acceptance: installed offline launch/edit,
process-kill/restart, travel/clock-change behavior, native accessibility and
packaged Windows behavior. Windows prerequisites, local release compilation and
an unpackaged responding window were verified on 5 October; interactive task
testing remains with the user. Host/widget tests do not close these gates. Large
workspace performance and real disk-full/power-loss behavior remain unmeasured.

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
