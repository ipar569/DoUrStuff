import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ports.dart';
import '../../domain/sync.dart';
import '../../domain/query.dart';
import '../../domain/task.dart' as domain;
import '../time_policy.dart';
import 'database.dart';

class LocalTaskRepository implements domain.TaskRepository {
  LocalTaskRepository(this.database, {this.clock = const SystemClock()});
  final AppDatabase database;
  final Clock clock;
  static const _uuid = Uuid();
  int get _now => clock.nowUtc().millisecondsSinceEpoch;
  static DateTime _instant(int value) =>
      DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  static DateTime? _nullableInstant(int? value) =>
      value == null ? null : _instant(value);

  @override
  Stream<List<domain.Task>> watchTasks() =>
      watchWorkspace().map((w) => w.tasks);
  @override
  Stream<domain.Workspace> watchWorkspace() => database
      .customSelect(
        'SELECT COUNT(*) FROM tasks',
        readsFrom: {
          database.tasks,
          database.tags,
          database.taskTags,
          database.milestones,
          database.savedViews,
          database.sharedPreferences,
        },
      )
      .watch()
      .asyncMap((_) => database.transaction(_readWorkspace));

  Future<domain.Workspace> _readWorkspace() async {
    final tags = {
      for (final r
          in await database
              .customSelect(
                'SELECT * FROM tags WHERE deleted_at IS NULL ORDER BY normalized_name, id',
              )
              .get())
        r.read<String>('id'): domain.Tag(
          r.read<String>('id'),
          r.read<String>('name'),
        ),
    };
    final memberships = await database
        .customSelect(
          'SELECT * FROM task_tags WHERE removed = 0 ORDER BY tag_id',
        )
        .get();
    final steps = await database
        .customSelect(
          'SELECT * FROM milestones WHERE deleted_at IS NULL ORDER BY position, id',
        )
        .get();
    final taskTags = <String, List<domain.Tag>>{};
    for (final m in memberships) {
      final tag = tags[m.read<String>('tag_id')];
      if (tag != null) {
        taskTags.putIfAbsent(m.read<String>('task_id'), () => []).add(tag);
      }
    }
    final taskSteps = <String, List<domain.Milestone>>{};
    for (final step in steps) {
      taskSteps
          .putIfAbsent(step.read<String>('task_id'), () => [])
          .add(
            domain.Milestone(
              id: step.read<String>('id'),
              title: step.read<String>('title'),
              completedAt: _nullableInstant(
                step.readNullable<int>('completed_at'),
              ),
            ),
          );
    }
    final tasks =
        (await database
                .customSelect(
                  'SELECT * FROM tasks WHERE deleted_at IS NULL ORDER BY created_at DESC, id',
                )
                .get())
            .map((r) {
              final id = r.read<String>('id');
              final due = switch (r.read<String>('due_kind')) {
                'date' => domain.Due.date(
                  domain.CivilDate.parse(r.read<String>('due_date')),
                ),
                'timed' => domain.Due.timed(
                  instant: _instant(r.read<int>('due_instant')),
                  zone: r.read<String>('due_zone'),
                  wallTime: r.read<String>('due_wall_time'),
                ),
                _ => const domain.Due.none(),
              };
              return domain.Task(
                id: id,
                title: r.read<String>('title'),
                description: r.read<String>('description'),
                status: domain.TaskStatus.values.firstWhere(
                  (s) => s.wire == r.read<String>('status'),
                ),
                priority: domain.TaskPriority.values[r.read<int>('priority')],
                due: due,
                estimateMinutes: r.readNullable<int>('estimate_minutes'),
                createdAt: _instant(r.read<int>('created_at')),
                updatedAt: _instant(r.read<int>('updated_at')),
                completedAt: _nullableInstant(
                  r.readNullable<int>('completed_at'),
                ),
                tags: List.unmodifiable(taskTags[id] ?? <domain.Tag>[]),
                milestones: List.unmodifiable(
                  taskSteps[id] ?? <domain.Milestone>[],
                ),
              );
            })
            .toList();
    final views = <domain.SavedView>[];
    final invalidViews = <String, String>{};
    for (final r
        in await database
            .customSelect(
              'SELECT * FROM saved_views WHERE deleted_at IS NULL ORDER BY name, id',
            )
            .get()) {
      try {
        if (r.read<int>('spec_version') != 1) {
          throw const FormatException('Unsupported view version');
        }
        views.add(
          domain.SavedView(
            r.read<String>('id'),
            r.read<String>('name'),
            TaskQuery.fromJson(jsonDecode(r.read<String>('spec_json'))),
          ),
        );
      } catch (_) {
        invalidViews[r.read<String>('id')] = r.read<String>('name');
      }
    }
    final preference = await database
        .customSelect(
          'SELECT value_json FROM shared_preferences WHERE "key" = ?',
          variables: [const Variable('default_view')],
        )
        .getSingleOrNull();
    final defaultId = preference == null
        ? null
        : jsonDecode(preference.read<String>('value_json')) as String?;
    return domain.Workspace(
      tasks,
      tags.values.toList(),
      views,
      views.any((v) => v.id == defaultId) ? defaultId : null,
      invalidViews: invalidViews,
    );
  }

  Map<String, Object?> _fields(domain.Task task) => {
    'title': task.title,
    'description': task.description,
    'priority': task.priority.index,
    'due': task.due.toJson(),
    'estimate_minutes': task.estimateMinutes,
    'status_group': {
      'status': task.status.wire,
      'completed_at': task.completedAt?.millisecondsSinceEpoch,
    },
  };
  String _fingerprint(domain.Task task) => jsonEncode({
    ..._fields(task),
    'tags': task.tags.map((t) => t.id).toList()..sort(),
    'milestones': task.milestones
        .map((s) => [s.id, s.title, s.completedAt?.millisecondsSinceEpoch])
        .toList(),
  });

  @override
  Future<void> createTask(String title) async {
    await saveTask(domain.TaskDraft(title: title));
  }

  @override
  Future<domain.Task> saveTask(
    domain.TaskDraft draft, {
    domain.Task? base,
  }) async {
    // Capture the submitted draft before entering the asynchronous transaction.
    draft = domain.TaskDraft(
      title: draft.title,
      description: draft.description,
      status: draft.status,
      priority: draft.priority,
      due: draft.due,
      estimateMinutes: draft.estimateMinutes,
      tagIds: draft.tagIds,
      milestones: draft.milestones,
    );
    draft.validate();
    TimePolicy.validate(draft.due);
    return database.transaction(() async {
      final before = await _readWorkspace();
      final id = base?.id ?? _uuid.v4();
      final matches = before.tasks.where((t) => t.id == id);
      final current = matches.isEmpty ? null : matches.single;
      if (base != null &&
          (current == null || _fingerprint(base) != _fingerprint(current))) {
        throw StateError(
          'This task changed or was deleted. Reopen it before saving; your draft is kept.',
        );
      }
      if (!draft.tagIds.every((id) => before.tags.any((t) => t.id == id))) {
        throw ArgumentError('A selected tag is no longer available.');
      }
      final now = _now;
      final completed = draft.status == domain.TaskStatus.completed
          ? current?.completedAt ?? _instant(now)
          : null;
      final milestones = <domain.Milestone>[];
      for (final step in draft.milestones) {
        final old = current?.milestones
            .where((s) => s.id == step.id)
            .firstOrNull;
        if (step.id != null && old == null) {
          throw ArgumentError('Unknown milestone.');
        }
        milestones.add(
          domain.Milestone(
            id: step.id ?? _uuid.v4(),
            title: step.title.trim(),
            completedAt: step.completedAt == null
                ? null
                : old?.completedAt ?? _instant(now),
          ),
        );
      }
      final next = domain.Task(
        id: id,
        title: draft.title.trim(),
        description: draft.description,
        status: draft.status,
        priority: draft.priority,
        due: draft.due,
        estimateMinutes: draft.estimateMinutes,
        createdAt: current?.createdAt ?? _instant(now),
        updatedAt: _instant(now),
        completedAt: completed,
        tags: before.tags.where((t) => draft.tagIds.contains(t.id)).toList(),
        milestones: milestones,
      );
      if (current != null && _fingerprint(current) == _fingerprint(next)) {
        return current;
      }
      final fields = _fields(next);
      final oldFields = current == null
          ? <String, Object?>{}
          : _fields(current);
      final patch = {
        for (final e in fields.entries)
          if (jsonEncode(e.value) != jsonEncode(oldFields[e.key]))
            e.key: e.value,
      };
      await database.customStatement(
        'INSERT INTO tasks (id,title,description,status,priority,due_kind,due_date,due_instant,due_zone,due_wall_time,estimate_minutes,created_at,updated_at,completed_at) '
        'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET title=excluded.title, description=excluded.description,status=excluded.status,priority=excluded.priority,'
        'due_kind=excluded.due_kind,due_date=excluded.due_date,due_instant=excluded.due_instant,due_zone=excluded.due_zone,due_wall_time=excluded.due_wall_time,'
        'estimate_minutes=excluded.estimate_minutes,updated_at=excluded.updated_at,completed_at=excluded.completed_at',
        [
          id,
          next.title,
          next.description,
          next.status.wire,
          next.priority.index,
          next.due.kind,
          next.due.date?.toString(),
          next.due.instant?.millisecondsSinceEpoch,
          next.due.zone,
          next.due.wallTime,
          next.estimateMinutes,
          next.createdAt.millisecondsSinceEpoch,
          now,
          completed?.millisecondsSinceEpoch,
        ],
      );
      // Task dependency is recorded before dependent membership/milestone commands.
      await _record(id, current == null ? 'task.create' : 'task.edit', {
        ...patch,
        if (current == null) 'created_at': now,
        'updated_at': now,
      }, now);
      final oldTagIds = current?.tags.map((t) => t.id).toSet() ?? <String>{};
      for (final tagId in {...oldTagIds, ...draft.tagIds}) {
        final removed = !draft.tagIds.contains(tagId);
        if (oldTagIds.contains(tagId) == !removed) continue;
        await database.customStatement(
          'INSERT INTO task_tags(task_id,tag_id,removed) VALUES (?,?,?) ON CONFLICT(task_id,tag_id) DO UPDATE SET removed=excluded.removed',
          [id, tagId, removed ? 1 : 0],
        );
        await _record('membership:$id:$tagId', 'task.tag', {
          'task_id': id,
          'tag_id': tagId,
          'removed': removed,
        }, now);
      }
      for (final old in current?.milestones ?? <domain.Milestone>[]) {
        if (!milestones.any((s) => s.id == old.id)) {
          await database.customStatement(
            'UPDATE milestones SET deleted_at=? WHERE id=?',
            [now, old.id],
          );
          await _record(old.id!, 'milestone.delete', {
            'task_id': id,
            'deleted_at': now,
          }, now);
        }
      }
      for (var i = 0; i < milestones.length; i++) {
        final step = milestones[i];
        final old = current?.milestones
            .where((s) => s.id == step.id)
            .firstOrNull;
        await database.customStatement(
          'INSERT INTO milestones(id,task_id,title,position,completed_at) VALUES (?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET title=excluded.title,position=excluded.position,completed_at=excluded.completed_at',
          [
            step.id,
            id,
            step.title,
            i,
            step.completedAt?.millisecondsSinceEpoch,
          ],
        );
        final changes = <String, Object?>{
          if (old == null) 'task_id': id,
          if (old?.title != step.title) 'title': step.title,
          if (old == null || old.completedAt != step.completedAt)
            'completed_at': step.completedAt?.millisecondsSinceEpoch,
        };
        if (changes.isNotEmpty) {
          await _record(
            step.id!,
            old == null ? 'milestone.create' : 'milestone.edit',
            changes,
            now,
          );
        }
      }
      final order = milestones.map((s) => s.id).toList();
      if (jsonEncode(order) !=
          jsonEncode(current?.milestones.map((s) => s.id).toList() ?? [])) {
        await _record(id, 'task.milestone_order', {'ordered_ids': order}, now);
      }
      database.markTablesUpdated({
        database.tasks,
        database.taskTags,
        database.milestones,
      });
      return next;
    });
  }

  @override
  Future<void> setCompleted(String id, {required bool completed}) =>
      database.transaction(() async {
        final task = (await _readWorkspace()).tasks
            .where((t) => t.id == id)
            .firstOrNull;
        if (task == null) throw StateError('Task is no longer available.');
        final status = completed
            ? domain.TaskStatus.completed
            : domain.TaskStatus.todo;
        if (task.status == status) return;
        final now = _now;
        await database.customUpdate(
          'UPDATE tasks SET status=?, completed_at=?, updated_at=? WHERE id=?',
          variables: [
            Variable(status.wire),
            Variable<int>(completed ? now : null),
            Variable(now),
            Variable(id),
          ],
          updates: {database.tasks},
        );
        await _record(id, 'task.status', {
          'status_group': {
            'status': status.wire,
            'completed_at': completed ? now : null,
          },
          'updated_at': now,
        }, now);
      });

  @override
  Future<domain.DeleteReceipt> deleteTasks(Iterable<String> ids) =>
      database.transaction(() async {
        final receipt = <String, String>{};
        for (final id in ids.toSet()) {
          final now = _now;
          final changed = await database.customUpdate(
            'UPDATE tasks SET deleted_at=?, updated_at=? WHERE id=? AND deleted_at IS NULL',
            variables: [Variable(now), Variable(now), Variable(id)],
            updates: {database.tasks},
          );
          if (changed != 1) {
            throw StateError('A selected task is no longer available.');
          }
          await database.customStatement(
            'INSERT INTO tombstones(entity_id,entity_kind,deleted_at) VALUES (?,\'task\',?) ON CONFLICT(entity_id) DO UPDATE SET deleted_at=excluded.deleted_at',
            [id, now],
          );
          receipt[id] = await _record(id, 'task.delete', {
            'deleted_at': now,
          }, now);
        }
        return domain.DeleteReceipt(Map.unmodifiable(receipt));
      });
  @override
  Future<void> restoreTasks(domain.DeleteReceipt receipt) =>
      database.transaction(() async {
        for (final e in receipt.operations.entries) {
          final last = await database
              .customSelect(
                'SELECT operation_id FROM outbox WHERE entity_id=? ORDER BY sequence DESC LIMIT 1',
                variables: [Variable(e.key)],
              )
              .getSingle();
          if (last.read<String>('operation_id') != e.value) {
            throw StateError('Deletion changed; undo is no longer available.');
          }
          final changed = await database.customUpdate(
            'UPDATE tasks SET deleted_at=NULL,updated_at=? WHERE id=? AND deleted_at IS NOT NULL',
            variables: [Variable(_now), Variable(e.key)],
            updates: {database.tasks},
          );
          if (changed != 1) throw StateError('Task is not deleted.');
          await database.customStatement(
            'DELETE FROM tombstones WHERE entity_id=?',
            [e.key],
          );
          await _record(e.key, 'task.restore', {
            'expected_delete_operation': e.value,
            'deleted_at': null,
            'updated_at': _now,
          }, _now);
        }
      });
  String _name(String name) {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty || clean.length > 80) {
      throw ArgumentError('Use a name between 1 and 80 characters.');
    }
    return clean;
  }

  @override
  Future<String> saveTag(
    String name, {
    String? id,
  }) => database.transaction(() async {
    final clean = _name(name);
    final duplicate = await database
        .customSelect(
          'SELECT id FROM tags WHERE normalized_name=? AND deleted_at IS NULL',
          variables: [Variable(normalized(clean))],
        )
        .getSingleOrNull();
    if (duplicate != null && duplicate.read<String>('id') != id) {
      if (id == null) return duplicate.read<String>('id');
      throw ArgumentError('A tag with that name already exists.');
    }
    if (id != null) await _requireActive('tags', id);
    final key = id ?? _uuid.v4();
    await database.customStatement(
      'INSERT INTO tags(id,name,normalized_name) VALUES (?,?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,normalized_name=excluded.normalized_name',
      [key, clean, normalized(clean)],
    );
    await _record(key, id == null ? 'tag.create' : 'tag.edit', {
      'name': clean,
      'normalized_name': normalized(clean),
    }, _now);
    database.markTablesUpdated({database.tags});
    return key;
  });
  Future<void> _requireActive(String table, String id) async {
    // Table names are internal constants, never user input.
    final row = await database
        .customSelect(
          'SELECT id FROM $table WHERE id=? AND deleted_at IS NULL',
          variables: [Variable(id)],
        )
        .getSingleOrNull();
    if (row == null) throw StateError('Item is no longer available.');
  }

  @override
  Future<void> deleteTag(String id) => database.transaction(() async {
    await _requireActive('tags', id);
    await database.customUpdate(
      'UPDATE tags SET deleted_at=? WHERE id=?',
      variables: [Variable(_now), Variable(id)],
      updates: {database.tags},
    );
    await _record(id, 'tag.delete', {'deleted_at': _now}, _now);
  });
  @override
  Future<String> saveView(String name, TaskQuery query, {String? id}) =>
      database.transaction(() async {
        final clean = _name(name);
        final json = query.encode();
        if (id != null) await _requireActive('saved_views', id);
        final key = id ?? _uuid.v4();
        await database.customStatement(
          'INSERT INTO saved_views(id,name,spec_version,spec_json) VALUES (?,?,1,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name,spec_version=1,spec_json=excluded.spec_json',
          [key, clean, json],
        );
        await _record(key, id == null ? 'view.create' : 'view.edit', {
          'name': clean,
          'spec_version': 1,
          'spec': query.toJson(),
        }, _now);
        database.markTablesUpdated({database.savedViews});
        return key;
      });
  @override
  Future<void> deleteView(String id) => database.transaction(() async {
    await _requireActive('saved_views', id);
    await database.customUpdate(
      'UPDATE saved_views SET deleted_at=? WHERE id=?',
      variables: [Variable(_now), Variable(id)],
      updates: {database.savedViews},
    );
    await _record(id, 'view.delete', {'deleted_at': _now}, _now);
    final pref = await database
        .customSelect(
          'SELECT value_json FROM shared_preferences WHERE "key"=\'default_view\'',
        )
        .getSingleOrNull();
    if (pref != null && jsonDecode(pref.read<String>('value_json')) == id) {
      await setDefaultView(null);
    }
  });
  @override
  Future<void> setDefaultView(String? id) => database.transaction(() async {
    if (id != null) await _requireActive('saved_views', id);
    await database.customStatement(
      'INSERT INTO shared_preferences("key",value_json) VALUES (\'default_view\',?) ON CONFLICT("key") DO UPDATE SET value_json=excluded.value_json',
      [jsonEncode(id)],
    );
    await _record('preference:default_view', 'preference.set', {
      'key': 'default_view',
      'value': id,
    }, _now);
    database.markTablesUpdated({database.sharedPreferences});
  });
  Future<String> _record(
    String entityId,
    String command,
    Map<String, Object?> changes,
    int now,
  ) async {
    final profile = await database
        .customSelect('SELECT * FROM profile_metadata WHERE singleton = 1')
        .getSingle();
    // Account transport and shadow rebasing arrive in phase 3. Never enqueue
    // an account command with invented base revisions in this foundation.
    if (profile.read<String>('profile_id') != 'guest') {
      throw StateError('Account commands are not available in this phase.');
    }
    final sequence = profile.read<int>('next_sequence');
    final operationId = _uuid.v4();
    final previous = await database
        .customSelect(
          'SELECT operation_id FROM outbox WHERE entity_id = ? '
          'ORDER BY sequence DESC LIMIT 1',
          variables: [Variable(entityId)],
        )
        .getSingleOrNull();
    final operation = ChangeOperation(
      operationId: operationId,
      deviceEpoch: profile.read<String>('device_epoch'),
      sequence: sequence,
      entityId: entityId,
      command: command,
      changes: changes,
      dependencies: [
        if (previous != null) previous.read<String>('operation_id'),
        for (final parent in ['task_id', 'tag_id'])
          if (changes[parent] is String)
            ...await _latestOperation(changes[parent]! as String),
      ],
    );
    await database.customStatement(
      'INSERT INTO outbox (operation_id, sequence, entity_id, envelope_json, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [operationId, sequence, entityId, operation.encode(), now],
    );
    await database.customStatement(
      'UPDATE profile_metadata SET next_sequence = next_sequence + 1 WHERE singleton = 1',
    );
    await database.customStatement(
      'INSERT INTO history (id, entity_id, operation_id, kind, occurred_at, detail_json) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [_uuid.v4(), entityId, operationId, command, now, jsonEncode(changes)],
    );
    await database.customStatement(
      'INSERT INTO notification_dirty (entity_id) VALUES (?) '
      'ON CONFLICT (entity_id) DO UPDATE SET generation = generation + 1',
      [entityId],
    );
    return operationId;
  }

  Future<List<String>> _latestOperation(String id) async {
    final row = await database
        .customSelect(
          'SELECT operation_id FROM outbox WHERE entity_id=? ORDER BY sequence DESC LIMIT 1',
          variables: [Variable(id)],
        )
        .getSingleOrNull();
    return row == null ? [] : [row.read<String>('operation_id')];
  }
}
