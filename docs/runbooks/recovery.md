# Preservation and recovery

Saved means committed locally. Phase 1 is guest-only; it has no cloud backup or
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
