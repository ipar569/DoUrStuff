import '../../domain/account_sync.dart';
import '../../domain/account_task_validation.dart';
import '../time_policy.dart';

/// Bounded local command surface. Wire decoding intentionally remains broader:
/// invalid/unsupported retained originals must still be available for recovery.
bool validLocalAccountCommand(AccountOperation operation) {
  final patches = operation.patches;
  final command = operation.command;
  final task = operation.entity.kind == SyncEntityKind.task;
  final create = command.endsWith('.create');
  final delete = command.endsWith('.delete');
  if (!const {
    'task.create',
    'task.edit',
    'task.status',
    'task.delete',
    'milestone.create',
    'milestone.edit',
    'milestone.delete',
  }.contains(command)) {
    return false;
  }
  if (task && operation.dependencies.isNotEmpty) return false;
  if (!task &&
      (!create && operation.dependencies.isNotEmpty ||
          operation.dependencies.length > 1)) {
    return false;
  }
  final allowed = task
      ? {
          'title',
          'description',
          'priority',
          'estimate_minutes',
          'due',
          'status_group',
        }
      : {'title', 'completion'};
  if (create) allowed.addAll(task ? {'existence'} : {'existence', 'parent'});
  if (delete) {
    if (patches.length != 1 || patches['existence']?.value != false) {
      return false;
    }
    final base = patches['existence']!.base;
    if (base is ObservedBase
        ? base.value != true
        : base is PredecessorBase
        ? base.value != true
        : true) {
      return false;
    }
  } else {
    if (patches.keys.any((key) => !allowed.contains(key))) return false;
    if (command == 'task.status' &&
        (patches.length != 1 || !patches.containsKey('status_group'))) {
      return false;
    }
    if (create &&
        (!(task
                    ? {'existence', 'title', 'priority', 'status_group'}
                    : {'existence', 'title', 'completion', 'parent'})
                .every(patches.containsKey) ||
            patches['existence']!.value != true ||
            patches.values.any((patch) => patch.base is! AbsentBase))) {
      return false;
    }
  }
  for (final entry in patches.entries) {
    final value = entry.value.value;
    final valid = switch (entry.key) {
      'title' =>
        value is String &&
            value.trim().isNotEmpty &&
            value.trim().length <= 500,
      'description' => validAccountDescription(value),
      'priority' => const {'none', 'low', 'medium', 'high'}.contains(value),
      'estimate_minutes' => validAccountEstimate(value),
      'due' => TimePolicy.validAccountDue(value),
      'status_group' => validAccountStatusGroup(value),
      'completion' => validAccountStatusGroup({
        'status': value == null ? 'todo' : 'completed',
        'completed_at': value,
      }),
      'parent' =>
        value is String &&
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            ).hasMatch(value),
      'existence' => value is bool,
      _ => false,
    };
    if (!valid) return false;
  }
  // PostgreSQL JSONB cannot represent NUL, including in original bases. Reject
  // locally without truncating or altering the caller's immutable proposal.
  if (!_postgresStrings(operation.toJson())) return false;
  for (final dep in operation.dependencies) {
    if (dep.entity.kind != SyncEntityKind.task ||
        dep.entity.key.single != patches['parent']?.value) {
      return false;
    }
  }
  return true;
}

bool _postgresStrings(Object? value) {
  if (value is Map) {
    return value.entries.every(
      (e) => _postgresStrings(e.key) && _postgresStrings(e.value),
    );
  }
  if (value is List) return value.every(_postgresStrings);
  if (value is! String) return true;
  final units = value.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final c = units[i];
    if (c == 0 || (c >= 0xdc00 && c <= 0xdfff)) return false;
    if (c >= 0xd800 && c <= 0xdbff) {
      if (++i == units.length || units[i] < 0xdc00 || units[i] > 0xdfff) {
        return false;
      }
    }
  }
  return true;
}
