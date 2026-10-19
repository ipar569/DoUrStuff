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
Search now starts as a compact button beside Filters & sort. Clicking opens and
focuses the field; collapsing preserves the query and shows Search (active).

All mutations use SQLite transactions with local journal/history/sequence/dirty
intent. Schema remains v1; tags, milestones and views now have commands and validators.
No Riverpod dependency was needed for this screen-owned state.

See [Phase 2 verification](verification/phase-2.md) for exact host checks and
native build evidence. Remaining acceptance: physical Android offline launch/edit,
process-kill/restart, travel/clock-change behavior, native accessibility and
packaged Windows behavior. Windows prerequisites, local release compilation and
an unpackaged responding window were verified on 5 October; interactive task
testing was confirmed by the user on 9 October, including offline editing,
closing/reopening, and persistence of tasks and the default saved view. Exact
Windows build/device details were not supplied. Android 11 x86_64 emulator
fresh-install/offline and process-restart acceptance passed on 12 October;
the user accepted this for entry into local Phase 3 work. Physical Android
acceptance remains open. Host/widget tests do not close these gates. Large
workspace performance and real disk-full/power-loss behavior remain unmeasured.

## Phase 3: accounts and tested two-device sync

Milestone 3.0 local readiness passed; 3.1 in progress: [9 October delivery plan](proposals/2026-10-09-phase-3-plan.md)
and [Phase 3 verification status](verification/phase-3.md). The user accepted the
emulator entry evidence on 12 October. Milestones: protocol/readiness, server
foundation, account storage/auth, first sync slice, full replication/recovery,
account lifecycle, then installed two-device acceptance/deployment readiness.

10 October review: user reconfirmed Android acceptance is incomplete; keep the
entry gate open. [Readiness notes](proposals/2026-10-10-phase-3-readiness.md)
inventory command/schema gaps and a candidate dependency-sequencing fixture.
No Phase 3 implementation or executable protocol fixture was added during that
review. Superseding 12–13 October work adds immutable account v2 operations,
typed RPC contracts and 16 causal/identity tests. Docker's Linux daemon now
responds. CLI download/execution was initially blocked, then succeeded through
interactive approval on 13 October; version 2.120.0 is pinned. At that point,
complete RPC wire fixtures, relationship/delete/restore and resolution-race
fixtures, and real stack/dependency verification remained unfinished.
The later 13 October increment adds all six RPC codecs/goldens, response
correlation, pure relationship/delete/restore/default/tag/resolution checks and
a terminal-rejection fixture. Local Supabase configuration is initialized.
Remaining readiness: upgrade the old Docker engine for loopback port isolation,
then prove real stack health and image pins. Full server command validation,
PostgreSQL normalization parity and transactional policy/RLS evidence remain
3.1 work. No backend or account adapter is implemented; account writes stay
guarded. See the backend runbook and verification report.
16 October resume adds registration/snapshot-creation epoch checks and rejects
expired snapshot manifests before staging; the full suite passes 100 tests.
The installed Docker Desktop still reports 4.19.0 with its daemon stopped, so
the runtime update and stack health remain the next prerequisites.
Later on 16 October the user completed the update: Engine 29.8.2 and the local
stack now pass health/image checks. The network-default binding failed on this
host and was repaired with explicit loopback bindings while preserving volumes.
Use the guarded restart procedure in `supabase/README.md`. Two real migrations
now provide restricted registration/pull RPCs and private ownership-enforced
storage. Eight backend integration groups pass, with Dart validation of real
responses. Next: atomic apply, field/entity validation, receipts/watermarks and
the conflict/dependent/unrelated fixture against PostgreSQL. These remain 3.1;
there is no client account integration or two-device sync yet.
17 October implements the first atomic apply increment: existing-task title and
priority edits, immutable receipts, contiguous device watermarks and retained
conflict/held/rejected repair data. Real HTTP tests reproduce the causal fixture,
lost-reply retries, receipt expiry, rollback, late commits and ownership denial.
Next in 3.1: task creation/status and remaining command semantics, then snapshots
and explicit resolution, full wire/normalization parity and retention policy.
Account UI/transport stays gated throughout this partial backend work.
PR #2 delivery review adds safe native integer bounds, a separate recovery-reply
depth budget and local HTTP proxy/redirect isolation with regression checks.
The full Flutter suite now passes 102 tests; see the latest verification handoff
and PR timeline for backend reruns, independent review and CI/merge status.
The [prompt index](prompts/README.md) includes copy-and-paste launch messages for
new sessions; each phase prompt requires a durable verification handoff to resume.

18 October continues 3.1 with forward migration 004: all-or-nothing core task
creation, immutable retries/collisions and atomic status/completion. Durable
status history retains completion snapshots across reopening and receipt expiry.
Real HTTP fixtures cover both completion/edit orders, partial content merges,
invalid command boundaries, rollback and same-UUID account isolation. The
supported create shape has four required groups; full Phase 2 draft fields,
history download/snapshot/retention integration, remaining commands, resolution
and transport representability still gate account activation. Milestones 3.2–3.6
and the installed two-device/latency gates remain open; Phase 4 stays gated.
Independent review adds migration 005 to avoid no-op status history and retain
authoritative operation payloads/identity protection after receipt expiry. The
wire checker also accepts correctly rejected commands with several invalid groups.

PR #3 merged at `47e9e7aebaa52969260359e1539950d3772f6bf0` on 19 October after
independent re-review and passing Quality/Android/Windows CI. The next 3.1
increment implements optional description/estimate creation and independent edits,
preserving completion, conflict bases, held successors and nullable clearing.
Full due/relationship/delete/restore semantics, history/snapshot/resolution and
retention remain open. The 100,000-unit description domain versus 64-KiB wire
limit is now an explicit representation gate before enabling accounts/adoption.
Local verification passes 106 Flutter tests, 35 backend integration groups,
220 real Dart-validated replies and three HTTP/encoding helper tests. See the
latest verification handoff and PR timeline for review and CI/merge evidence.

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
