# Preservation and recovery

27 October local snapshot increment: pre-019 schema/data dumps are retained at
`.tools/backend-before-snapshots-{schema,data}.sql` (ignored). The retained-data
forward rehearsal and real-owner snapshot candidate both rolled back safely;
this is not a backup-restoration rehearsal. All eighteen earlier migrations,
existing containers, volumes and stopped backups were preserved. Snapshot
tokens/pages are server recovery building blocks only: historical event
transport, pending-safe client staging/install, retention scheduling and explicit
resolution remain open. See the [audit](../architecture/account-recovery-audit.md).

Saved means committed locally. The current Phase 2 app is guest-only; it has no cloud backup or
in-app export. Back up the device and retain the entire profile directory before
repairs. Never clear app data merely to fix an open/migration failure.

A failed open preserves existing files. A newer schema requires a compatible
app, not a downgrade. While SQLite is open, use a consistent backup or VACUUM
INTO a new file: copying only tasks.sqlite can omit committed WAL records. With
the app fully closed, retain all profile files. Backups contain private plaintext.

Future upgrades create a uniquely named consistent backup before entering the
migration transaction. Backup failure stops migration. Each upgrade must preserve
tasks, journals, tombstones and history and have fixture tests. Phase 1 has no
older released native schema; fresh v1 creation and retained-data reopening are
the current baseline, not evidence of a multi-version upgrade.

Do not resume old transport epochs/sequences from a restored account database.
Phase 3 must put restored work into recovery/export mode, create a new device
epoch, fetch an authoritative snapshot and preserve original conflict bases.
Server restoration increments server epoch. Account restore does not exist yet.
Never clear pending operations/tombstones to make synchronization appear healthy.

26 October saved-view/default-reference increment: ignored local pre-apply dumps
are `.tools/backend-before-saved-views-schema.sql` and
`.tools/backend-before-saved-views-data.sql`. The empty-application-schema and
retained-data forward rehearsal, plus real-owner candidate create/select/rename/
delete rollback, passed before applying 017. Migration 018 corrects empty-name
validation while preserving applied 017 and all sixteen earlier migrations.
These dumps and rollback tests do not constitute a restoration rehearsal.

View deletion retains content and its immutable operation. If the current default
still references that view, the same transaction clears it and logs both records
under one revision. A stale selection cannot revive it; original rejected or
conflicting candidates stay recoverable. The preference ledger retains explicit
changes and implicit clears with their source operations. Never infer a field
predecessor from that ledger when its receipt expired. View restore/purge,
snapshot installation, explicit resolution and native account recovery remain
unfinished. Preserve the existing local stack, volumes and stopped backups.

Phase 3 readiness review, 10 October 2026: reserved v1 sync tables are not an
account recovery implementation. The planned upgrade must retain original bases,
held dependent candidates and adoption mappings through snapshot/receipt expiry;
see the [upgrade inventory](../proposals/2026-10-10-phase-3-readiness.md).
No upgrade or restore was executed during that review. Supabase's current
[pausing policy](https://supabase.com/docs/guides/platform/free-project-pausing)
allows platform restoration for up to one year after pausing. Preserve independent
backups; recheck that window during an incident. No cloud backup was created.

12–13 October: the [v2 contract foundation](../architecture/account-protocol-v2.md)
defines durable held candidates separately from transport acknowledgements and
plans the minimal retained-data SQLite upgrade. Its in-memory snapshot/reload
fixture preserves original conflict bases and high-water marks after receipt
expiry; it is not database crash or backend restore evidence. Schema remains v1.
Android emulator acceptance used a stopped-app archive of the complete synthetic
guest profile, including WAL/SHM, and checked a read-only copy. No personal data,
account restore, migration or cloud recovery was involved.

Later 13 October wire checks reject snapshot pages with the wrong token/epoch/
revision/page, expired manifests, impossible acknowledgements or missing
original bases. Exact restore deletion identity and the server-time 30-day
content boundary now have pure policy tests. These checks still do not implement
durable staging, complete snapshot validation or real backup/restore. An
expired receipt never authorizes reapplying a consumed operation; the fixture
also preserves terminally rejected candidates through representation reload.

16 October local backend work preserved the named PostgreSQL volume when fixing
port bindings. Four original containers remain stopped as `*-before-loopback`;
do not restart them because they publish on all interfaces. The schema/data dump
before the identity-boundary forward migration is ignored local evidence at
`.tools/backend-before-auth-boundary.sql`, not a verified disaster-recovery backup.
Migration tests rebuild the application schema inside a rollback-only transaction
and verify an existing device watermark survives the forward fix. No production
restore, failed-migration reset or account content recovery was performed.

17 October adds a second local pre-migration dump at
`.tools/backend-before-causal-edits.sql`; it is not a rehearsed restore artifact.
Real apply tests now prove atomic rollback on an injected log-write failure,
idempotent retries after a simulated lost reply, and no replay after detailed
receipt removal. Device watermarks and unresolved original envelopes survive
that simulated retention boundary. Held successors remain held; missing accepted
predecessor evidence requires recovery. Deleted tasks cannot be resurrected by
the implemented edit path. Snapshot download, resolution, physical crash recovery
and automated retention are still unimplemented; these checks do not close them.

18 October: `.tools/backend-before-create-status.sql` preserves the local
application schema/data before migration 004. Real HTTP tests now verify that
creation, status history, receipt, cursor and watermark roll back together on
an injected log-write failure. Reopening clears only the current completion
time; earlier status snapshots survive retries and receipt expiry. Creation
collisions retain all original absent bases; a tombstone blocks recreation.
History is currently private server storage: download, snapshot inclusion and
retention/deletion handling remain required before client account activation.

The subsequent review fix (migration 005) preserves exact original envelopes
alongside history and checks them after detailed receipts expire. For preexisting
events, it copies only available receipts; an unavailable original remains null
and never authorizes reassignment of its operation ID. Original consumed-sequence
retries still reconcile without replay. `.tools/backend-before-history-fix.sql`
is the preserved pre-fix dump. The upgrade test retains both kinds of history
inside a rollback-only application-schema rehearsal, not a disaster restore.

19 October: migration 006 adds independent description and nullable estimate
patches while preserving four-group creation compatibility and original bases.
The local pre-migration dump is `.tools/backend-before-task-fields.sql`; it has
not been restore-tested. Long valid descriptions can exceed the 64-KiB operation
envelope; preflight consumes no sequence. Future adoption/account commands must
retain that content and provide a supported representation before activation.

20 October: migration 007 adds complete due tuples while preserving old
absent groups and all original envelopes. The local pre-apply dump is
`.tools/backend-before-task-due.sql`, not a tested restore. Due conflicts and
held successors retain their original dates/instants/zones/wall times; receipt
expiry never authorizes replay. Real fault injection checks due creation,
history, receipt, cursor and watermark rollback together. The app still has no
account recovery path. Do not modify guest deadlines to work around future or
historical timezone-data disagreements between the client and server.

21 October review found overly permissive gap shifting just after a transition.
Forward migration 008 requires the absence of any exact wall occurrence before
allowing the gap path; 007 remains unchanged. The preserved pre-fix dump is
`.tools/backend-before-due-gap-fix.sql`. No account client is enabled and the
test suites use synthetic data. Windows host port exclusions prevented loopback
access on 21 October; guarded restart restored it on 22 October. The normal
foundation harness then verified retained-data upgrade through all eight
migrations inside a rollback-only transaction. Five synthetic harness accounts
left by the interrupted run were identified by their exact fixture naming
pattern and removed through the local Auth cleanup path; account/auth-fixture
and injected-trigger counts returned to zero. Do not discard volumes or restart
the stopped pre-loopback backups to repair host networking.

22 October task deletion: migration 009 retains canonical task content and
records the original deletion envelope, deletion revision and server timestamp
in private `task_deletions`. Late edits retain their original bases in recovery;
they do not restore visibility. Receipt/log expiry cannot authorize replay or
operation-ID reassignment. The RPC role has no update/delete permission on the
deletion ledger. Do not purge this ledger or task content to simulate retention.
Restore and the 30-day expiry policy are still unsupported, as are child
visibility rules; no in-app account deletion/undo capability is enabled.

The subsequent 22 October migration 010 enables server `task.restore` only for
the exact current deletion ID/revision, an observed false base, retained core
content and a server age below 720 hours. The boundary is exclusive and uses
fresh time after the account lock. Missing history/content or future timestamps
fail closed; expiry never reconstructs a task. Original deletion IDs remain on
visible shadows and immutable restore envelopes remain in `task_restorations`.
Retrying an old successful undo cannot revive a newer deletion. Late-edit
recovery candidates stay unresolved; restoration does not silently apply them.
Physical purging, copy/recovery UI and child visibility are still pending.

23 October milestone creation (011) retains exact original creation payloads
in private `milestone_shadow`, including absent bases and parent dependencies.
Expired parent receipts require recovery rather than a guessed dependency;
held child candidates remain unchanged and do not block unrelated sequences.
Parent delete/restore changes inherited visibility without altering child content
or an independent child tombstone. Pull carries canonical records, so a future
account projection must combine parent and child existence. No account recovery
UI or milestone delete command is enabled by this increment.

Pre-apply application schema/data dumps are
`.tools/backend-before-milestone-create-schema.sql` and
`.tools/backend-before-milestone-create-data.sql`. Candidate rollback and injected
parent/child transaction failure tests are migration/atomicity evidence, not a
disaster recovery rehearsal. Preserve all eleven applied migrations unchanged.

The next 23 October migration (012) supports milestone title/completion edits
and independent deletion. Late edits to a hidden child/parent retain original
base/local/canonical candidates. A held child create can have no row yet; causal
edit/delete successors remain held, while missing evidence requires recovery.
Neither path fabricates a child. Parent restoration never replays candidates.

Child deletion is allowed while its parent is hidden, using the child's own
existence base. Parent restoration therefore cannot undo that independent delete.
Private append-only `milestone_deletions` retains exact winning operations and
server deletion identity beyond receipt/log expiry; retries cannot replace it.
No child restore, content purge or recovery UI is provided. Keep all twelve
applied migrations unchanged. Pre-apply schema/data dumps are
`.tools/backend-before-milestone-commands-schema.sql` and
`.tools/backend-before-milestone-commands-data.sql`; restore rehearsal is unverified.

24 October ordering (013) retains canonical ordered IDs through child additions,
deletions and parent restore. Projection filters hidden children and appends
unlisted live children by UUID; it never rewrites original order candidates.
Conflicted predecessors hold dependent reorders before equivalence. Missing or
expired child-create receipt evidence requires recovery without guessing a base.
There is no native account recovery/projection UI yet.

Pre-apply dumps are `.tools/backend-before-milestone-order-schema.sql` and
`.tools/backend-before-milestone-order-data.sql`. Candidate rollback and injected
order transaction failure checks are not disaster-recovery rehearsal evidence.
Preserve all thirteen applied migration files unchanged; use forward fixes.

24 October normalization (014) adds private pure helpers and changes no stored
row or immutable payload. Native guest tag creation uses the frozen version of
its existing policy. A retained v1 tag fixture verifies duplicate lookup preserves
the original UUID/membership and colliding rename rolls back every table. No
SQLite migration or backfill is required. Future account tag collisions must
retain distinct UUID candidates without redirecting membership references.

Pre-apply dumps are `.tools/backend-before-tag-normalization-schema.sql` and
`.tools/backend-before-tag-normalization-data.sql`; they are not restore evidence.
Preserve all fourteen applied migrations. NUL/raw-number, description-cap and
timezone representation gaps still prevent account activation/adoption.

25 October tag commands (015) retain original normalized-name collision
candidates under their own UUIDs, even if no canonical tag exists. Held successors
survive detailed-receipt expiry through unresolved recovery records; missing
accepted predecessor evidence requires recovery rather than guessing a revision.
Deleting the winning tag or freeing its name never auto-applies those candidates.

Tag deletion retains content, creation payload and an immutable deletion ledger.
Name reuse by a new UUID never restores the old UUID or redirects its future
membership records. There is no tag restore/purge or native account recovery UI.
Pre-apply dumps are `.tools/backend-before-tag-commands-schema.sql` and
`.tools/backend-before-tag-commands-data.sql`, not restore evidence. Preserve
all fifteen applied migrations; use forward fixes.

25 October membership increment: retain accepted false membership records,
original pair keys, add/remove envelopes, receipts and unresolved candidates.
Either parent tombstone hides a membership without changing its accepted base;
a task restore preserves an independent removal. Never redirect an old tag UUID
to a same-name replacement. Missing accepted predecessor/dependency receipts
require recovery, not reconstruction from current rows or the mutation ledger.
Held same-field chains retain their original candidates through receipt expiry.

The local pre-apply schema/data dumps are
`.tools/backend-before-memberships-schema.sql` and
`.tools/backend-before-memberships-data.sql`. Candidate rollback preserves exact
retained parent/history/receipt/watermark state; an injected second-log-write
failure checks whole membership batch rollback. These are not physical crash,
backup restore or installed-client evidence. All sixteen migrations are retained;
ledger retention/storage measurement and snapshot recovery remain unfinished.
