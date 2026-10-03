import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/data/local/database.dart';
import 'package:dourstuff/data/local/task_repository.dart';

import 'generated/schema.dart';

void main() {
  test('fresh schema matches the generated v1 contract', () async {
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
      await verifier.migrateAndValidate(db, 1);
      await db.initializeProfile('guest');
      expect(
        (await LocalTaskRepository(db).watchTasks().first).single.title,
        'Retained task',
      );
    },
  );
}
