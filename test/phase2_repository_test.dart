import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/data/local/database.dart' show AppDatabase;
import 'package:dourstuff/data/local/task_repository.dart';
import 'package:dourstuff/data/time_policy.dart';
import 'package:dourstuff/domain/task.dart';
import 'package:dourstuff/domain/query.dart';
import 'package:dourstuff/domain/ports.dart';

class TestClock implements Clock {
  DateTime now = DateTime.utc(2026, 10, 3, 1);
  @override
  DateTime nowUtc() => now;
}

void main() {
  late AppDatabase db;
  late LocalTaskRepository repo;
  late TestClock clock;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.initializeProfile('guest');
    clock = TestClock();
    repo = LocalTaskRepository(db, clock: clock);
  });
  tearDown(() async {
    await db.close();
  });
  Future<Workspace> read() => repo.watchWorkspace().first;
  Future<List<Map<String, Object?>>> rows(String table) async =>
      (await db.customSelect('SELECT * FROM $table').get())
          .map((r) => r.data)
          .toList();
  Future<Map<String, Object>> snapshot() async => {
    for (final table in [
      'tasks',
      'tags',
      'task_tags',
      'milestones',
      'saved_views',
      'shared_preferences',
      'tombstones',
      'outbox',
      'history',
      'notification_dirty',
      'profile_metadata',
    ])
      table: await rows(table),
  };
  test(
    'full edit persists due/status/estimate; journal only changed fields',
    () async {
      final tag = await repo.saveTag(' Home ');
      final created = await repo.saveTask(
        TaskDraft(
          title: 'Task',
          description: 'Notes',
          tagIds: [tag],
          milestones: [
            const Milestone(title: 'First'),
            const Milestone(title: 'Second'),
          ],
          due: Due.date(CivilDate(2026, 10, 4)),
          priority: TaskPriority.high,
          estimateMinutes: 45,
        ),
      );
      clock.now = clock.now.add(const Duration(minutes: 2));
      final draft = TaskDraft.from(created)
        ..description = 'Updated'
        ..status = TaskStatus.inProgress;
      final saved = await repo.saveTask(draft, base: created);
      expect(saved.createdAt, created.createdAt);
      expect(saved.updatedAt, clock.now);
      expect(saved.completedAt, isNull);
      final current = (await read()).tasks.single;
      expect(current.due.date.toString(), '2026-10-04');
      expect(current.estimateMinutes, 45);
      expect(current.tags.single.name, 'Home');
      final operation = jsonDecode(
        (await rows('outbox')).last['envelope_json']! as String,
      ) as Map;
      expect(operation['command'], 'task.edit');
      expect(operation['changes'], {
        'description': 'Updated',
        'status_group': {'status': 'in_progress', 'completed_at': null},
        'updated_at': clock.now.millisecondsSinceEpoch,
      });
      final entries = await rows('outbox');
      expect(
        entries.map((r) => r['sequence']),
        List.generate(entries.length, (i) => i + 1),
      );
      expect((await rows('history')).length, entries.length);
      expect(
        (await rows('notification_dirty')).map((r) => r['entity_id']),
        containsAll(entries.map((r) => r['entity_id']).toSet()),
      );
    },
  );
  test('milestones reorder, edit, remove and complete independently', () async {
    var task = await repo.saveTask(
      TaskDraft(
        title: 'Parent',
        milestones: [
          const Milestone(title: 'A'),
          const Milestone(title: 'B'),
        ],
      ),
    );
    final a = task.milestones[0], b = task.milestones[1];
    final draft = TaskDraft.from(task)
      ..milestones = [
        Milestone(id: b.id, title: 'B renamed', completedAt: clock.now),
        a,
      ];
    task = await repo.saveTask(draft, base: task);
    expect(task.status, TaskStatus.todo);
    expect((await read()).tasks.single.milestones.map((m) => m.id), [
      b.id,
      a.id,
    ]);
    await repo.setCompleted(task.id, completed: true);
    task = (await read()).tasks.single;
    expect(task.milestones.last.completedAt, isNull);
    final remove = TaskDraft.from(task)..milestones = [task.milestones.first];
    await repo.saveTask(remove, base: task);
    expect(
      (await rows('milestones'))
          .where((m) => m['deleted_at'] != null)
          .single['id'],
      a.id,
    );
    expect((await read()).tasks.single.milestones.single.id, b.id);
  });
  test(
    'tag normalization/reuse, rename, membership removal, deletion',
    () async {
      final tag = await repo.saveTag('  Daily   Work ');
      expect(await repo.saveTag('daily work'), tag);
      var task = await repo.saveTask(TaskDraft(title: 'Task', tagIds: [tag]));
      await repo.saveTag('Work', id: tag);
      expect((await read()).tasks.single.tags.single.name, 'Work');
      task = (await read()).tasks.single;
      await repo.saveTask(TaskDraft.from(task)..tagIds = [], base: task);
      expect((await rows('task_tags')).single['removed'], 1);
      task = (await read()).tasks.single;
      await repo.saveTask(TaskDraft.from(task)..tagIds = [tag], base: task);
      await repo.deleteTag(tag);
      expect((await read()).tasks.single.tags, isEmpty);
      expect(
        (await rows('task_tags')).single['removed'],
        0,
        reason: 'Deletion suppresses retained membership',
      );
    },
  );
  test('delete bulk deduplicates, hides children and undo has deletion precondition', () async {
    final a = await repo.saveTask(
      TaskDraft(
        title: 'A',
        milestones: [const Milestone(title: 'Step')],
      ),
    );
    final b = await repo.saveTask(TaskDraft(title: 'B'));
    final receipt = await repo.deleteTasks([a.id, a.id, b.id]);
    expect(receipt.operations.length, 2);
    expect((await read()).tasks, isEmpty);
    expect((await rows('milestones')).length, 1);
    await repo.restoreTasks(receipt);
    expect((await read()).tasks.length, 2);
    expect(await rows('tombstones'), isEmpty);
    await expectLater(repo.restoreTasks(receipt), throwsStateError);
    await repo.deleteTasks([a.id]);
    await expectLater(repo.restoreTasks(receipt), throwsStateError);
    await expectLater(
      repo.saveTask(TaskDraft.from(a)..title = 'Stale edit', base: a),
      throwsStateError,
    );
  });
  test(
    'bulk delete rolls back entirely if any selected ID is unavailable',
    () async {
      final task = await repo.saveTask(TaskDraft(title: 'Keep'));
      final before = await snapshot();
      await expectLater(
        repo.deleteTasks([task.id, 'missing']),
        throwsStateError,
      );
      expect(await snapshot(), before);
    },
  );
  test(
    'stale editor and foreign milestone IDs cannot overwrite committed state',
    () async {
      final a = await repo.saveTask(TaskDraft(title: 'A'));
      final b = await repo.saveTask(
        TaskDraft(
          title: 'B',
          milestones: [const Milestone(title: 'Owned by B')],
        ),
      );
      await expectLater(
        repo.saveTask(TaskDraft.from(a)..milestones = b.milestones, base: a),
        throwsArgumentError,
      );
      await repo.setCompleted(a.id, completed: true);
      await expectLater(
        repo.saveTask(TaskDraft.from(a)..title = 'Stale', base: a),
        throwsStateError,
      );
      expect(
        (await read()).tasks.firstWhere((t) => t.id == a.id).status,
        TaskStatus.completed,
      );
    },
  );
  test('late child journal failure rolls back parent, child, history, dirty and sequence', () async {
    final task = await repo.saveTask(
      TaskDraft(
        title: 'Before',
        milestones: [const Milestone(title: 'A')],
      ),
    );
    final before = await snapshot();
    await db.customStatement(
      "CREATE TRIGGER fail BEFORE INSERT ON outbox WHEN json_extract(NEW.envelope_json,'\$.command')='milestone.edit' BEGIN SELECT RAISE(ABORT,'injected'); END",
    );
    await expectLater(
      repo.saveTask(
        TaskDraft.from(task)
          ..title = 'After'
          ..milestones = [
            Milestone(id: task.milestones.single.id, title: 'Changed'),
          ],
        base: task,
      ),
      throwsA(anything),
    );
    expect(await snapshot(), before);
  });
  for (final command in [
    'tag.create',
    'view.create',
    'preference.set',
    'task.delete',
    'task.restore',
  ]) {
    test('$command journal failure is atomic', () async {
      final task = await repo.saveTask(TaskDraft(title: 'Keep'));
      final view = await repo.saveView('View', TaskQuery());
      final receipt = command == 'task.restore'
          ? await repo.deleteTasks([task.id])
          : null;
      final before = await snapshot();
      await db.customStatement(
        "CREATE TRIGGER fail BEFORE INSERT ON outbox WHEN json_extract(NEW.envelope_json,'\$.command')='$command' BEGIN SELECT RAISE(ABORT,'injected'); END",
      );
      Future<void> action() async {
        switch (command) {
          case 'tag.create':
            await repo.saveTag('Fail');
          case 'view.create':
            await repo.saveView('Fail', TaskQuery());
          case 'preference.set':
            await repo.setDefaultView(view);
          case 'task.delete':
            await repo.deleteTasks([task.id]);
          case 'task.restore':
            await repo.restoreTasks(receipt!);
        }
      }

      await expectLater(action(), throwsA(anything));
      expect(await snapshot(), before);
    });
  }
  test(
    'saved views validate, update, default, and fall back after deletion',
    () async {
      final q = TaskQuery(
        search: 'hello',
        statuses: {TaskStatus.todo},
        priorities: {TaskPriority.high},
        group: TaskGrouping.tag,
        sort: TaskSort.duration,
        descending: true,
      );
      final id = await repo.saveView('My view', q);
      await repo.setDefaultView(id);
      expect((await read()).views.single.query.toJson(), q.toJson());
      expect((await read()).defaultViewId, id);
      await repo.saveView('Renamed', q..search = 'new', id: id);
      expect((await read()).views.single.name, 'Renamed');
      await expectLater(
        repo.saveView(
          'Invalid',
          TaskQuery(undated: true, from: CivilDate(2026, 1, 1)),
        ),
        throwsFormatException,
      );
      await repo.deleteView(id);
      expect((await read()).defaultViewId, isNull);
      expect(
        jsonDecode(
          (await rows('shared_preferences')).single['value_json']! as String,
        ),
        isNull,
      );
      await expectLater(repo.setDefaultView(id), throwsStateError);
    },
  );
  test('malformed saved view is quarantined without blocking tasks or destroying content', () async {
    await db.customStatement(
      "INSERT INTO saved_views VALUES ('bad','Broken',1,'{bad',NULL)",
    );
    await repo.createTask('Still works');
    final state = await read();
    expect(state.tasks.single.title, 'Still works');
    expect(state.invalidViews, {'bad': 'Broken'});
    expect((await rows('saved_views')).single['spec_json'], '{bad');
    await repo.deleteView('bad');
    expect((await read()).invalidViews, isEmpty);
  });
  test('account guard applies to all new mutation families', () async {
    await db.customStatement(
      "UPDATE profile_metadata SET profile_id='account-fixture'",
    );
    final before = await snapshot();
    await expectLater(repo.saveTag('Tag'), throwsStateError);
    await expectLater(repo.saveView('View', TaskQuery()), throwsStateError);
    await expectLater(repo.setDefaultView(null), throwsStateError);
    expect(await snapshot(), before);
  });
  test('invalid reserved fields reject before any write', () async {
    for (final draft in [
      TaskDraft(title: 'x', estimateMinutes: 0),
      TaskDraft(title: 'x', estimateMinutes: -1),
      TaskDraft(
        title: 'x',
        milestones: [const Milestone(title: ' ')],
      ),
      TaskDraft(title: 'x', tagIds: ['missing']),
    ]) {
      await expectLater(repo.saveTask(draft), throwsArgumentError);
    }
    await expectLater(
      repo.saveTask(
        TaskDraft(
          title: 'x',
          due: Due.timed(
            instant: DateTime.utc(2026),
            zone: 'UTC',
            wallTime: '2026-10-03T09:00',
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(await rows('tasks'), isEmpty);
  });
  test(
    'full workspace survives closing and reopening a file with v1 schema',
    () async {
      final dir = await Directory.systemTemp.createTemp('phase2-restart-');
      final file = File('${dir.path}/tasks.sqlite');
      await db.close();
      db = AppDatabase.file(file);
      await db.initializeProfile('guest');
      repo = LocalTaskRepository(db, clock: clock);
      final tag = await repo.saveTag('Travel');
      final task = await repo.saveTask(
        TaskDraft(
          title: 'Pack',
          due: TimePolicy.resolve(
            '2026-11-01',
            '01:30',
            'America/New_York',
            later: true,
          ),
          estimateMinutes: 30,
          tagIds: [tag],
          milestones: [Milestone(title: 'Passport', completedAt: clock.now)],
        ),
      );
      final view = await repo.saveView(
        'Travel',
        TaskQuery(tags: {tag}, group: TaskGrouping.dueDay),
      );
      await repo.setDefaultView(view);
      final before = await snapshot();
      await db.close();
      db = AppDatabase.file(file);
      await db.initializeProfile('guest');
      repo = LocalTaskRepository(db, clock: clock);
      final state = await read();
      expect(state.tasks.single.id, task.id);
      expect(state.tasks.single.due.instant, task.due.instant);
      expect(state.defaultViewId, view);
      expect(state.tasks.single.milestones.single.completedAt, clock.now);
      expect(await snapshot(), before);
      await db.close();
      await dir.delete(recursive: true);
      db = AppDatabase(NativeDatabase.memory());
    },
  );
  test(
    'query projections react to committed SQLite tag and task edits',
    () async {
      final tag = await repo.saveTag('Work');
      final task = await repo.saveTask(
        TaskDraft(
          title: 'Report',
          description: 'Draft',
          tagIds: [tag],
          priority: TaskPriority.high,
        ),
      );
      final q = TaskQuery(
        search: 'draft work',
        statuses: {TaskStatus.todo},
        tags: {tag},
        priorities: {TaskPriority.high},
      );
      expect(q.apply((await read()).tasks, now: clock.now).single.id, task.id);
      final changed = repo.watchWorkspace().firstWhere(
        (w) => w.tasks.single.description == 'Final',
      );
      await repo.saveTask(
        TaskDraft.from(task)..description = 'Final',
        base: task,
      );
      expect(q.apply((await changed).tasks, now: clock.now), isEmpty);
      final operations = (await rows('outbox'))
          .map((r) => jsonDecode(r['envelope_json']! as String) as Map)
          .toList();
      final membership = operations.firstWhere(
        (op) => op['command'] == 'task.tag',
      );
      expect(
        membership['dependencies'],
        containsAll(
          operations
              .where(
                (op) => ['task.create', 'tag.create'].contains(op['command']),
              )
              .map((op) => op['operation_id']),
        ),
      );
    },
  );
}
