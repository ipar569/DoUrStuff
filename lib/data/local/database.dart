import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:uuid/uuid.dart';

part 'database.g.dart';

const localSchemaVersion = 1;

/// Called before Drift starts its migration transaction. VACUUM INTO includes
/// committed WAL contents, unlike copying just the main database file.
void prepareSqlite(sqlite.Database database, String? backupPath) {
  final version = database.userVersion;
  if (version > localSchemaVersion) {
    throw StateError('This database needs a newer DoUrStuff version.');
  }
  if (version > 0 && version < localSchemaVersion) {
    if (backupPath == null) throw StateError('A migration backup is required.');
    database.execute('VACUUM INTO ?', [backupPath]);
  }
  database.execute('PRAGMA foreign_keys = ON');
  database.execute('PRAGMA journal_mode = WAL');
  database.execute('PRAGMA synchronous = FULL');
  database.execute('PRAGMA busy_timeout = 5000');
}

@DriftDatabase(include: {'schema.drift'})
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  factory AppDatabase.file(File file) {
    final backup =
        '${file.path}.backup-${DateTime.now().microsecondsSinceEpoch}';
    return AppDatabase(
      NativeDatabase.createInBackground(
        file,
        setup: (database) => prepareSqlite(database, backup),
      ),
    );
  }

  @override
  int get schemaVersion => localSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      // The initial release has no older DoUrStuff schema. Add explicit,
      // tested version steps here before incrementing localSchemaVersion.
      throw StateError('Unsupported migration $from -> $to; data preserved.');
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> initializeProfile(String profileId) => transaction(() async {
    final existing = await customSelect('SELECT * FROM profile_metadata').get();
    if (existing.isEmpty) {
      const uuid = Uuid();
      await customStatement(
        'INSERT INTO profile_metadata '
        '(singleton, profile_id, lineage_id, device_epoch) VALUES (1, ?, ?, ?)',
        [profileId, uuid.v4(), uuid.v4()],
      );
      await customStatement(
        'INSERT INTO sync_checkpoint (singleton) VALUES (1)',
      );
    } else if (existing.single.read<String>('profile_id') != profileId) {
      throw StateError('Database belongs to a different profile.');
    }
  });
}
