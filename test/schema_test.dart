import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/data/local/database.dart';
import 'package:dourstuff/data/local/task_repository.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'generated/schema.dart';

void main() {
  test('fresh schema matches the generated v2 contract', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.initializeProfile('guest');
    await db.validateDatabaseSchema();
  });

  test(
    'opening the committed v1 snapshot preserves existing task data',
    () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final fixture = await verifier.schemaAt(1);
      fixture.rawDatabase.execute(
        "INSERT INTO tasks (id,title,created_at,updated_at) VALUES ('fixture','Retained task',1,1)",
      );
      final db = AppDatabase(fixture.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);
      await db.initializeProfile('guest');
      expect(
        (await LocalTaskRepository(db).watchTasks().first).single.title,
        'Retained task',
      );
    },
  );

  test(
    'v1 file upgrade backs up WAL and preserves every legacy table byte',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'account-upgrade-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final fixture = await SchemaVerifier(GeneratedHelper()).schemaAt(1);
      final file = File('${directory.path}/retained.sqlite');
      fixture.rawDatabase.execute('VACUUM INTO ?', [file.path]);
      fixture.rawDatabase.close();
      final raw = sqlite.sqlite3.open(file.path);
      seedLegacy(raw);
      final before = legacyRows(raw);
      raw.execute('PRAGMA journal_mode=WAL');
      raw.execute("INSERT INTO device_preferences VALUES ('wal-only','true')");
      before['device_preferences'] = jsonEncode(
        raw
            .select('SELECT * FROM device_preferences')
            .map((r) => Map.of(r))
            .toList(),
      );
      // Keep this connection open so committed WAL data cannot be omitted.
      final db = AppDatabase.file(file);
      await db.initializeProfile('guest');
      await db.validateDatabaseSchema();
      await db.close();
      raw.close();
      final upgraded = sqlite.sqlite3.open(file.path);
      expect(upgraded.userVersion, 2);
      expect(legacyRows(upgraded), before);
      expect(upgraded.select('SELECT * FROM account_operations'), isEmpty);
      upgraded.close();
      final backup = directory.listSync().whereType<File>().singleWhere(
        (f) => f.path.contains('.backup-'),
      );
      final retained = sqlite.sqlite3.open(backup.path);
      expect(retained.userVersion, 1);
      expect(legacyRows(retained), before);
      retained.close();
    },
  );

  test(
    'late migration failure rolls back DDL and preserves v1 plus backup',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'account-rollback-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final fixture = await SchemaVerifier(GeneratedHelper()).schemaAt(1);
      final file = File('${directory.path}/failed.sqlite');
      fixture.rawDatabase.execute('VACUUM INTO ?', [file.path]);
      fixture.rawDatabase.close();
      final raw = sqlite.sqlite3.open(file.path);
      seedLegacy(raw);
      final before = legacyRows(raw);
      raw.execute('CREATE TABLE account_snapshot_pages (unexpected TEXT)');
      raw.close();
      final db = AppDatabase.file(file);
      await expectLater(db.initializeProfile('guest'), throwsA(anything));
      await db.close();
      final retained = sqlite.sqlite3.open(file.path);
      expect(retained.userVersion, 1);
      expect(legacyRows(retained), before);
      expect(
        retained.select(
          "SELECT name FROM sqlite_master WHERE name='account_state'",
        ),
        isEmpty,
      );
      retained.close();
      expect(
        directory.listSync().where((f) => f.path.contains('.backup-')),
        hasLength(1),
      );
    },
  );

  test('backup failure prevents any upgrade or source alteration', () async {
    final directory = await Directory.systemTemp.createTemp('account-backup-');
    addTearDown(() => directory.delete(recursive: true));
    final fixture = await SchemaVerifier(GeneratedHelper()).schemaAt(1);
    final raw = fixture.rawDatabase;
    seedLegacy(raw);
    final before = legacyRows(raw);
    final occupied = File('${directory.path}/backup.sqlite')
      ..writeAsStringSync('existing backup');
    expect(() => prepareSqlite(raw, occupied.path), throwsA(anything));
    expect(raw.userVersion, 1);
    expect(legacyRows(raw), before);
    expect(occupied.readAsStringSync(), 'existing backup');
    raw.close();
  });
}

Map<String, String> legacyRows(sqlite.Database db) => {
  for (final table in db.select(
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'account_%' ORDER BY name",
  ))
    table['name'] as String: jsonEncode(
      db
          .select('SELECT * FROM ${table['name']} ORDER BY rowid')
          .map((r) => Map.of(r))
          .toList(),
    ),
};

void seedLegacy(sqlite.Database db) {
  for (final sql in [
    "INSERT INTO profile_metadata VALUES(1,'guest','lineage','epoch',42)",
    "INSERT INTO sync_checkpoint VALUES(1,'legacy-epoch',7,'token',2,123)",
    "INSERT INTO tasks(id,title,created_at,updated_at,deleted_at) VALUES('t','Original',1,2,3)",
    "INSERT INTO tags VALUES('tag','Tag','tag',NULL)",
    "INSERT INTO task_tags VALUES('t','tag',1)",
    "INSERT INTO milestones VALUES('m','t','Step',0,NULL,NULL)",
    "INSERT INTO recurrence_series VALUES('s','{}',NULL)",
    "INSERT INTO recurrence_segments VALUES('seg','s','{}',1,'retained',NULL)",
    "INSERT INTO occurrence_state VALUES('occ','seg',1,'slot','{}',NULL)",
    "INSERT INTO reminder_rules VALUES('rem','t',NULL,'{}',NULL)",
    "INSERT INTO snoozes VALUES('t',123,1,100)",
    "INSERT INTO saved_views VALUES('v','View',1,'{}',NULL)",
    "INSERT INTO shared_preferences VALUES('default','null')",
    "INSERT INTO sync_shadow VALUES('opaque',' { \"old\": true } ','{}',9)",
    "INSERT INTO outbox VALUES('op',41,'t',' { \"protocol_version\": 1 } ','conflict',2,99,1)",
    "INSERT INTO conflicts VALUES('c','t','null','\"local\"','\"server\"',NULL)",
    "INSERT INTO history VALUES('h','t','op','edit',1,' { \"keep\": true } ')",
    "INSERT INTO tombstones VALUES('t','task',NULL,3)",
    "INSERT INTO notification_dirty VALUES('t',5)",
    "INSERT INTO device_notifications VALUES('n',1,1,2,'f','scheduled')",
    "INSERT INTO import_journal VALUES('old-lineage','old-id','t','batch','pending')",
  ]) {
    db.execute(sql);
  }
}
