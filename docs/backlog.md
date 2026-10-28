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

20 October: PR #4 independently reviewed at `8dc5a5b` with no actionable
findings, then merged at `5e5478f` after passing Quality/Android/Windows CI.
The next increment adds forward migration 007 for atomic none/date/timed due
creation and edits, strict tuple validation, gap/fold handling, conflict/held
recovery, clearing and account isolation. Local verification passes 108 Flutter
tests, 42 backend integration groups and 294 real Dart-validated replies,
including 763 due cases across all 342 client zone names. Full historical/future
timezone-data parity remains an activation gate alongside the existing text/
JSONB representation gaps. Next: relationships/parent dependencies,
delete/restore and remaining entities/commands, followed by account storage/auth
and the real two-client slice. Phase 3.1 remains partial; the app is guest-only.

21 October PR #5 review found a gap-validation bug for ordinary times after a
DST transition. Forward migration 008 fixes it while preserving 007; the
regression matrix now has 785 due cases and the Flutter suite passes 109 tests.
Windows reserved the backend's host ports on 21 October; guarded restart on
22 October restored normal loopback access without changing containers or
reservations. All 7 affected due and 8 foundation groups passed on that path,
including the eight-migration retained-data upgrade; 85 real replies passed
client validation. Installed-device reachability remains unverified.
See the latest verification entry and PR review/check timeline before resuming.

22 October continues with task deletion as the visibility prerequisite for
relationship work. Migration 009 preserves content, original late edits and a
private deletion ledger with immutable operation identity and trusted server
time. Restore, 30-day expiry and child visibility remain unsupported. Next:
exact-deletion restore preconditions and parent/child semantics, then remaining
commands. Representation gaps still block account activation; app guest-only.

The next 22 October increment adds exact-deletion restore with an observed
false-to-true base and trusted-server 720-hour cutoff after the account lock.
Stale undo cannot revive later deletions; late-edit recovery remains explicit.
Migration 010 adds immutable restoration identity and keeps old deletion IDs.
Physical content purging and child visibility remain open. Next: parent/child
relationship commands and remaining entities, with retention/snapshot/recovery
integration before account activation. The app is still guest-only.

23 October adds milestone creation and parent dependencies (migration 011).
All four mandatory groups commit together; missing/expired parent evidence goes
to recovery, parent conflicts hold children while unrelated work advances.
Kind-qualified identities, immutable parent/creation payload and private inherited
visibility have real server coverage. Parent restore does not change independent
child tombstones or replay held children. Next: milestone title/completion edits,
deletion and task milestone ordering; then tags/memberships and remaining commands.
Client visibility projection, snapshots, recovery and account activation remain
unfinished. The representation gaps and installed-device gates stay open.

The next 23 October increment (012) adds milestone title/completion edits and
durable child deletion. Different fields merge; conflicts, held create successors
and hidden edits retain original candidates. A child's independent deletion
survives parent restore in either arrival order. Narrow column grants protect
owner/parent/creation identity and the deletion ledger remains append-only.
Next: task milestone ordering, then tags/memberships and remaining commands.
Native account activation, representation parity and installed acceptance stay gated.

24 October: PR #9 independently reviewed at `1821b3d` with no actionable findings
and merged at `2596b66` after passing Quality/Android/Windows CI. The next increment
(013) adds atomic task milestone ordering, original-base reorder conflicts,
exact child-create dependencies, deterministic additions and deletion filtering.
Accepted lists remain immutable through membership changes and parent restore.
Next: tags/memberships and remaining commands, then snapshot/retention/resolution
and client integration. See the latest verification handoff for exact review,
test and merge state. Native accounts and Phase 4 remain gated.

24 October: PR #10 merged at `eb128f0` after exact-head independent review and
passing Quality/Android/Windows CI. Migration 014 freezes tag normalization to
native Dart 3.13.5, with exhaustive scalar parity and exact atomic name validation.
Existing guest keys and membership identities remain stable. Server tag commands
remain disabled. Next: tag creation/edit/deletion with retained normalized-name
collision candidates, then membership dependencies/add/remove without UUID
aliasing; saved views/preferences and remaining command semantics follow.
Representation and installed-device gates remain open.

25 October: PR #11 merged at `69e9572` after exact-head independent review and
passing Quality/Android/Windows CI. Migration 015 adds tag create/rename/delete,
whole-name collision candidates without UUID aliasing, held causal successors,
active-name uniqueness, and retained deletion/creation identities. Next:
versioned task/tag memberships with exact parent dependencies and suppression
by either parent tombstone, then saved views/preferences and remaining command
semantics. Native account activation and installed acceptance remain gated.

25 October: PR #12 merged at `259bd6b` with 118 Flutter tests, 97 backend groups
and 868 Dart-validated real replies; PR #13's continuation instructions merged
at `c50b106`. Migration 016 adds exact task/tag membership identities, independent
boolean revisions and original add/remove bases, held parent dependencies and
visibility suppression by either tombstone. Explicit removal survives task
restore; same-name tags never redirect relationships. Next: saved views/preferences
and remaining command semantics, then snapshot/retention/resolution and native
integration. See the latest verification handoff/PR timeline for final evidence.
All account-write representation and external/native gates remain open.

26 October membership verification: 121 Flutter tests, 110 real backend groups
and 1,006 Dart-validated replies passed, plus normalization/HTTP checks. The old
tag capability test now gates saved views because membership is implemented.
See the current handoff and PR timeline for exact-head review, CI and merge.

Real Supabase migrations/RPC/RLS tests; secure tokens and GitHub PKCE; explicit
adoption; resumable bootstrap; field conflicts and recovery UI; cursor/receipts/
tombstones/high-water; catch-up/realtime/retries; sign-out/switch/deletion.
Prove p95 <=5 seconds over 100 changes under the documented test conditions.
Add protected migration deployment only with real tested migrations and recovery.
This gate precedes recurrence and reminders.

26 October saved-view increment: PR #15 merged at `4ac3a9e` after independent
review and passing Quality/Android/Windows CI. Forward migrations 017–018 add
atomic canonical view queries, independent names, retained deletion identities
and versioned default-view references/clearing. Deletion clears only the matching
selection in the same revision; stale references are recoverable rejections and
exact conflicted create dependencies remain held. The second migration corrects
empty-name validation without rewriting applied history. SQLite stays v1 and
account writes remain disabled. Next audit remaining Phase 2 command and
representation gaps, then implement snapshot/retention/explicit-resolution
recovery before native account integration. See the latest verification handoff
and PR timeline for exact checks, reviewed head and merge evidence.

27 October server recovery increment: migration 019 provides immutable,
owner-bound snapshot manifests/pages for six shadow kinds and unresolved
recovery, fixed revision/device watermarks, 24-hour tokens and bounded capture
storage. All eighteen prior migrations are preserved. Windows NAT's excluded
port range was diagnosed and the user-approved brief WinNAT restart restored
the existing local stack. No container/volume recreation was needed.
The [command/recovery audit](architecture/account-recovery-audit.md) identifies
status-history transport as the earliest remaining representation increment;
retention cleanup and explicit conflict resolution follow. Current v2 has all
17 command handlers but no complete history bootstrap. Native staging/account
writes, representation parity, external/installed acceptance and Phase 4 stay
gated. See the latest verification handoff and PR timeline for final evidence.

28 October history transport increment: forward migration 020 extends pull and
snapshots with explicitly negotiated history v1 while preserving legacy v2
shapes/tokens. Retained event IDs, known original operations and null unknown
originals survive receipt/log expiry; concurrent status changes and fixed-revision
pages preserve history independently of current shadows. SQLite stays v1 and
account writes stay disabled. Next: bounded 180-day log/receipt retention with
durable watermark/deletion/history/recovery preservation, then remaining content
retention and explicit resolution. See the latest verification handoff/PR timeline;
all representation, external, native and Phase 4 gates remain open.

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
