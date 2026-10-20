# Preservation and recovery

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
