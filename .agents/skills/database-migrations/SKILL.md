---
name: database-migrations
description: Change DoUrStuff SQLite schemas and migration fixtures while preserving local work; use for Drift schema or migration changes.
---

Read lib/data/local/database.dart, schema.drift, retained drift_schemas and
docs/runbooks/recovery.md before editing. The current native baseline is v1;
there is no legacy web database to migrate.

Increment localSchemaVersion for a shipped schema change. Add explicit upgrade
steps and retain every supported old snapshot. Keep the VACUUM INTO backup
outside Drift's migration transaction; never recreate a failed database or
silently accept a newer schema. Preserve journals, metadata, tombstones and
history as well as visible tasks.

Run dart run build_runner build, then dump to an explicit versioned filename:
dart run drift_dev schema dump lib/data/local/database.dart drift_schemas/drift_schema_vN.json.
Generate helpers with dart run drift_dev schema generate drift_schemas test/generated.
Do not overwrite old schema snapshots to make tests pass.

Extend test/schema_test.dart with retained-data fixtures for each supported
starting version. Exercise backup failure/rollback and downgrade rejection;
run flutter test test/schema_test.dart test/local_database_test.dart, analysis
and relevant quality checks. Report evidence separately from physical crash/
upgrade tests. Server schema changes additionally need the sync-protocol skill
and real backend tests once phase 3 exists.
