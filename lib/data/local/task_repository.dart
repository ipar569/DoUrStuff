import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/ports.dart';
import '../../domain/sync.dart';
import '../../domain/task.dart' as domain;
import 'database.dart';

class LocalTaskRepository implements domain.TaskRepository {
  LocalTaskRepository(this.database, {this.clock = const SystemClock()});
  final AppDatabase database;
  final Clock clock;
  static const _uuid = Uuid();

  @override
  Stream<List<domain.Task>> watchTasks() => database
      .customSelect(
        'SELECT * FROM tasks WHERE deleted_at IS NULL '
        'ORDER BY created_at DESC, id ASC',
        readsFrom: {database.tasks},
      )
      .watch()
      .map(
        (rows) => rows
            .map(
              (row) => domain.Task(
                id: row.read<String>('id'),
                title: row.read<String>('title'),
                description: row.read<String>('description'),
                status: switch (row.read<String>('status')) {
                  'todo' => domain.TaskStatus.todo,
                  'in_progress' => domain.TaskStatus.inProgress,
                  'completed' => domain.TaskStatus.completed,
                  'cancelled' => domain.TaskStatus.cancelled,
                  _ => throw StateError('Unknown task status'),
                },
                priority: domain.TaskPriority.values[row.read<int>('priority')],
                createdAt: _instant(row.read<int>('created_at')),
                updatedAt: _instant(row.read<int>('updated_at')),
                completedAt: _nullableInstant(
                  row.readNullable<int>('completed_at'),
                ),
              ),
            )
            .toList(),
      );

  static DateTime _instant(int value) =>
      DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

  static DateTime? _nullableInstant(int? value) =>
      value == null ? null : _instant(value);

  @override
  Future<void> createTask(String title) async {
    final cleaned = title.trim();
    if (cleaned.isEmpty || cleaned.length > 500) {
      throw ArgumentError('Use a title between 1 and 500 characters.');
    }
    final id = _uuid.v4();
    final now = clock.nowUtc().millisecondsSinceEpoch;
    await database.transaction(() async {
      await database.customInsert(
        'INSERT INTO tasks (id, title, created_at, updated_at) VALUES (?, ?, ?, ?)',
        variables: [
          Variable(id),
          Variable(cleaned),
          Variable(now),
          Variable(now),
        ],
        updates: {database.tasks},
      );
      await _record(id, 'task.create', {
        'title': cleaned,
        'description': '',
        'status': 'todo',
        'priority': 0,
        'due': {'kind': 'none'},
        'created_at': now,
        'updated_at': now,
      }, now);
    });
  }

  @override
  Future<void> setCompleted(String id, {required bool completed}) async {
    final now = clock.nowUtc().millisecondsSinceEpoch;
    await database.transaction(() async {
      final task = await database
          .customSelect(
            'SELECT status FROM tasks WHERE id = ? AND deleted_at IS NULL',
            variables: [Variable(id)],
          )
          .getSingleOrNull();
      if (task == null) throw StateError('Task is no longer available.');
      final status = completed ? 'completed' : 'todo';
      if (task.read<String>('status') == status) return;
      await database.customUpdate(
        'UPDATE tasks SET status = ?, completed_at = ?, updated_at = ? WHERE id = ?',
        variables: [
          Variable(status),
          Variable<int>(completed ? now : null),
          Variable(now),
          Variable(id),
        ],
        updates: {database.tasks},
      );
      await _record(id, 'task.status', {
        'status_group': {
          'status': status,
          'completed_at': completed ? now : null,
        },
        'updated_at': now,
      }, now);
    });
  }

  Future<void> _record(
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
  }
}
