import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dourstuff/data/local/database.dart';
import 'package:dourstuff/data/local/task_repository.dart';
import 'package:dourstuff/domain/task.dart';

void main() {
  late Directory directory;
  late AppDatabase db;
  late LocalTaskRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dourstuff-test-');
    db = AppDatabase.file(File('${directory.path}/tasks.sqlite'));
    await db.initializeProfile('guest');
    repository = LocalTaskRepository(db);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
          .read<int>('n');

  test('fresh offline commands persist entities, history, queue and settings across reopen', () async {
    await repository.createTask('  Buy groceries  ');
    final original = (await repository.watchTasks().first).single;
    await repository.setCompleted(original.id, completed: true);
    await db.customStatement('INSERT INTO device_preferences VALUES (?, ?)', [
      'layout',
      '"compact"',
    ]);
    await db.close();
    db = AppDatabase.file(File('${directory.path}/tasks.sqlite'));
    await db.initializeProfile('guest');
    repository = LocalTaskRepository(db);
    final restored = (await repository.watchTasks().first).single;
    expect(restored.id, original.id);
    expect(restored.title, 'Buy groceries');
    expect(restored.status, TaskStatus.completed);
    expect(restored.completedAt, isNotNull);
    expect(await count('outbox'), 2);
    expect(await count('history'), 2);
    expect(await count('device_preferences'), 1);
    expect(
      (await db.customSelect('PRAGMA integrity_check').getSingle())
          .data
          .values
          .single,
      'ok',
    );
    expect(
      (await db.customSelect('PRAGMA journal_mode').getSingle())
          .data
          .values
          .single,
      'wal',
    );
    expect(
      (await db.customSelect('PRAGMA synchronous').getSingle())
          .data
          .values
          .single,
      2,
    );
  });

  test(
    'outbox failure rolls back task, history, sequence and notification marker',
    () async {
      await db.customStatement(
        "CREATE TRIGGER fail_outbox BEFORE INSERT ON outbox "
        "BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      await expectLater(
        repository.createTask('Must not partially save'),
        throwsA(anything),
      );
      for (final table in [
        'tasks',
        'history',
        'outbox',
        'notification_dirty',
      ]) {
        expect(await count(table), 0, reason: table);
      }
      expect(
        (await db
                .customSelect('SELECT next_sequence FROM profile_metadata')
                .getSingle())
            .read<int>('next_sequence'),
        1,
      );
      await db.customStatement('DROP TRIGGER fail_outbox');
      await repository.createTask('Retry works');
      expect(await count('tasks'), 1);
    },
  );

  test('completion is idempotent, reopening preserves history and causal dependency', () async {
    await repository.createTask('One task');
    final id = (await repository.watchTasks().first).single.id;
    await repository.setCompleted(id, completed: true);
    await repository.setCompleted(id, completed: true);
    await repository.setCompleted(id, completed: false);
    final task = (await repository.watchTasks().first).single;
    expect(task.status, TaskStatus.todo);
    expect(task.completedAt, isNull);
    expect(await count('history'), 3);
    final operations = await db
        .customSelect('SELECT * FROM outbox ORDER BY sequence')
        .get();
    expect(operations.map((e) => e.read<int>('sequence')), [1, 2, 3]);
    expect(operations.every((e) => e.read<String>('state') == 'local'), isTrue);
    final last =
        jsonDecode(operations.last.read<String>('envelope_json')) as Map;
    expect(last['dependencies'], [operations[1].read<String>('operation_id')]);
  });

  test('concurrent captures have unique contiguous sequence numbers', () async {
    await Future.wait(
      List.generate(12, (i) => repository.createTask('Task $i')),
    );
    final rows = await db
        .customSelect('SELECT sequence FROM outbox ORDER BY sequence')
        .get();
    expect(
      rows.map((e) => e.read<int>('sequence')),
      List.generate(12, (i) => i + 1),
    );
  });

  test('profile mismatch fails without overwriting local tasks', () async {
    await repository.createTask('Private guest task');
    await expectLater(
      db.initializeProfile('account-another'),
      throwsStateError,
    );
    expect(await count('tasks'), 1);
    expect(
      (await db
              .customSelect('SELECT profile_id FROM profile_metadata')
              .getSingle())
          .read<String>('profile_id'),
      'guest',
    );
  });

  test(
    'account commands fail atomically until shadow-aware sync is implemented',
    () async {
      await db.customStatement(
        "UPDATE profile_metadata SET profile_id = 'account-test'",
      );
      await expectLater(
        repository.createTask('Do not enqueue guessed revisions'),
        throwsStateError,
      );
      expect(await count('tasks'), 0);
      expect(await count('outbox'), 0);
    },
  );

  test(
    'invalid titles and dangling milestone references fail safely',
    () async {
      await expectLater(repository.createTask('  '), throwsArgumentError);
      await expectLater(repository.createTask('x' * 501), throwsArgumentError);
      await expectLater(
        db.customStatement(
          "INSERT INTO milestones (id, task_id, title, position) VALUES ('m','missing','Step',0)",
        ),
        throwsA(anything),
      );
      expect(await count('tasks'), 0);
    },
  );

  test('a newer database is rejected without destructive downgrade', () async {
    await db.close();
    final file = File('${directory.path}/future.sqlite');
    final raw = sqlite3.open(file.path);
    raw.execute('CREATE TABLE important (value TEXT)');
    raw.execute("INSERT INTO important VALUES ('preserve')");
    raw.userVersion = localSchemaVersion + 1;
    raw.close();
    db = AppDatabase.file(file);
    await expectLater(db.initializeProfile('guest'), throwsA(anything));
    await db.close();
    final check = sqlite3.open(file.path);
    expect(check.userVersion, localSchemaVersion + 1);
    expect(
      check.select('SELECT value FROM important').single['value'],
      'preserve',
    );
    check.close();
  });

  test('consistent SQLite backup includes committed WAL content', () async {
    await repository.createTask('Included in backup');
    final backup = '${directory.path}/consistent.sqlite';
    await db.customStatement('VACUUM INTO ?', [backup]);
    final copy = sqlite3.open(backup);
    expect(
      copy.select('SELECT title FROM tasks').single['title'],
      'Included in backup',
    );
    expect(copy.select('PRAGMA integrity_check').single.values.single, 'ok');
    copy.close();
  });
}
