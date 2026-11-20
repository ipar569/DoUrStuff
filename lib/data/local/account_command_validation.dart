import '../../domain/account_sync.dart';
import '../../domain/account_task_validation.dart';
import '../../domain/account_view_validation.dart';
import '../../domain/tag_normalization.dart';
import '../time_policy.dart';

/// Bounded local command surface. Wire decoding intentionally remains broader:
/// invalid/unsupported retained originals must still be available for recovery.
const localAccountCommands = {
  'task.create',
  'task.edit',
  'task.status',
  'task.delete',
  'task.restore',
  'task.milestone_order',
  'milestone.create',
  'milestone.edit',
  'milestone.delete',
  'tag.create',
  'tag.edit',
  'tag.delete',
  'task.tag',
  'view.create',
  'view.edit',
  'view.delete',
  'preference.set',
};

bool validLocalAccountCommand(AccountOperation operation) {
  final patches = operation.patches;
  final command = operation.command;
  final task = operation.entity.kind == SyncEntityKind.task;
  final tag = operation.entity.kind == SyncEntityKind.tag;
  final view = operation.entity.kind == SyncEntityKind.view;
  final membership = operation.entity.kind == SyncEntityKind.membership;
  final create = command.endsWith('.create');
  final delete = command.endsWith('.delete');
  final ordering = command == 'task.milestone_order';
  if (!localAccountCommands.contains(command)) {
    return false;
  }
  if (task && !ordering && operation.dependencies.isNotEmpty) return false;
  if ((tag || view) && operation.dependencies.isNotEmpty) return false;
  if (command == 'preference.set') {
    final value = patches['value']!.value;
    return (value == null || isAccountUuid(value)) &&
        operation.dependencies.length <= 1 &&
        operation.dependencies.every(
          (dep) =>
              dep.entity.kind == SyncEntityKind.view &&
              dep.entity.key.single == value,
        ) &&
        _postgresStrings(operation.toJson());
  }
  if (membership) {
    if (patches.length != 1 ||
        patches['membership']?.value is! bool ||
        operation.dependencies.length > 2) {
      return false;
    }
    final base = patches['membership']!.base;
    if (base is ObservedBase && base.value is! bool ||
        base is PredecessorBase && base.value is! bool) {
      return false;
    }
  }
  if (!task &&
      !tag &&
      !membership &&
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
      : tag
      ? {'name'}
      : view
      ? {'name', 'query'}
      : membership
      ? {'membership'}
      : {'title', 'completion'};
  if (create) {
    allowed.addAll(
      task || tag || view ? {'existence'} : {'existence', 'parent'},
    );
  }
  if (ordering) {
    if (patches.length != 1 ||
        !validAccountMilestoneOrder(patches['milestone_order']?.value)) {
      return false;
    }
  } else if (operation.restore != null) {
    if (!operation.hasExactRestorePatch) return false;
  } else if (delete) {
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
                    : tag
                    ? {'existence', 'name'}
                    : view
                    ? {'existence', 'name', 'query'}
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
      'milestone_order' => validAccountMilestoneOrder(value),
      'name' => view ? validAccountViewName(value) : validAccountTagName(value),
      'query' => validAccountViewQuery(value),
      'membership' => value is bool,
      _ => false,
    };
    if (!valid) return false;
  }
  // PostgreSQL JSONB cannot represent NUL, including in original bases. Reject
  // locally without truncating or altering the caller's immutable proposal.
  if (!_postgresStrings(operation.toJson())) return false;
  final seen = <String>{};
  for (final dep in operation.dependencies) {
    if (membership) {
      if (!seen.add(dep.entity.identity) ||
          !(dep.entity.kind == SyncEntityKind.task &&
                  dep.entity.key.single == operation.entity.key[0] ||
              dep.entity.kind == SyncEntityKind.tag &&
                  dep.entity.key.single == operation.entity.key[1])) {
        return false;
      }
    } else if (ordering) {
      final ids =
          (patches['milestone_order']!.value as Map)['ordered_ids'] as List;
      if (!seen.add(dep.entity.identity) ||
          !(dep.entity.identity == operation.entity.identity ||
              dep.entity.kind == SyncEntityKind.milestone &&
                  ids.contains(dep.entity.key.single))) {
        return false;
      }
    } else if (dep.entity.kind != SyncEntityKind.task ||
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
