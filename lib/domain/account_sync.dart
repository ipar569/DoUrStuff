import 'dart:convert';

/// Account protocol is separate from the retained guest v1 journal.
const accountSyncProtocolVersion = 2;
const maxAccountOperationBytes = 65536;
const maxApplyOperations = 32;
const maxSyncInteger = 9007199254740991;
const maxSyncValueDepth = 16;
// Replies wrap validated operations/values in revision, recovery and result
// objects. Their envelope budget must not make accepted work unreadable.
const maxSyncReplyDepth = 24;

Object? _freeze(
  Object? value, [
  int depth = 0,
  int maxDepth = maxSyncValueDepth,
]) {
  if (depth > maxDepth) throw const FormatException('Protocol value too deep.');
  if (value == null || value is String || value is bool) return value;
  if (value is int && value >= -maxSyncInteger && value <= maxSyncInteger) {
    return value;
  }
  if (value is List) {
    return List<Object?>.unmodifiable(
      value.map((v) => _freeze(v, depth + 1, maxDepth)),
    );
  }
  if (value is Map && value.keys.every((k) => k is String)) {
    final keys = value.keys.cast<String>().toList()..sort();
    return Map<String, Object?>.unmodifiable({
      for (final key in keys) key: _freeze(value[key], depth + 1, maxDepth),
    });
  }
  throw const FormatException('Expected an exact JSON protocol value.');
}

/// Canonical identity uses sorted keys and exact JSON integers, never a timestamp.
String canonicalSyncJson(Object? value, {int maxDepth = maxSyncValueDepth}) =>
    jsonEncode(_freeze(value, 0, maxDepth));

void _uuid(String value) {
  if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
      .hasMatch(value)) {
    throw const FormatException('Expected a lowercase UUID.');
  }
}

enum SyncEntityKind { task, tag, milestone, membership, view, preference }

/// The authenticated account supplies the owner; it is never trusted wire data.
final class SyncEntity {
  SyncEntity(this.kind, List<String> key) : key = List.unmodifiable(key) {
    if (key.length != (kind == SyncEntityKind.membership ? 2 : 1)) {
      throw const FormatException('Invalid entity key arity.');
    }
    if (kind == SyncEntityKind.preference) {
      if (key.single != 'default_view') {
        throw const FormatException('Unsupported shared preference.');
      }
    } else {
      for (final part in key) {
        _uuid(part);
      }
    }
  }

  final SyncEntityKind kind;
  final List<String> key;
  Map<String, Object?> toJson() => {'kind': kind.name, 'key': key};
  String get identity => canonicalSyncJson(toJson());
}

sealed class FieldBase {
  const FieldBase();
  Map<String, Object?> toJson();
}

/// Missing is distinct from an existing nullable field whose value is null.
final class AbsentBase extends FieldBase {
  const AbsentBase();
  @override
  Map<String, Object?> toJson() => {'kind': 'absent'};
}

final class ObservedBase extends FieldBase {
  ObservedBase(this.revision, Object? value) : value = _freeze(value) {
    if (revision < 1 || revision > 9007199254740991) {
      throw const FormatException('Invalid field revision.');
    }
  }
  final int revision;
  final Object? value;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'observed',
    'revision': revision,
    'value': value,
  };
}

/// References the SAME entity/group's earlier operation on this device epoch.
/// The server binds the accepted result; the client never rewrites the payload.
final class PredecessorBase extends FieldBase {
  PredecessorBase(this.operationId, this.sequence, Object? value)
    : value = _freeze(value) {
    _uuid(operationId);
    if (sequence < 1) {
      throw const FormatException('Invalid predecessor sequence.');
    }
  }
  final String operationId;
  final int sequence;
  final Object? value;
  @override
  Map<String, Object?> toJson() => {
    'kind': 'predecessor',
    'operation_id': operationId,
    'sequence': sequence,
    'value': value,
  };
}

final class FieldPatch {
  FieldPatch(this.base, Object? value) : value = _freeze(value);
  final FieldBase base;
  final Object? value;
  Map<String, Object?> toJson() => {'base': base.toJson(), 'value': value};
}

/// Parent-existence dependencies are distinct from same-field causal bases.
final class OperationDependency {
  OperationDependency({
    required this.entity,
    required this.operationId,
    required this.sequence,
  }) {
    _uuid(operationId);
    if (sequence < 1) {
      throw const FormatException('Invalid dependency sequence.');
    }
  }
  final SyncEntity entity;
  final String operationId;
  final int sequence;
  Map<String, Object?> toJson() => {
    'entity': entity.toJson(),
    'operation_id': operationId,
    'sequence': sequence,
    'group': 'existence',
  };
}

const _commandKinds = {
  'task.create': SyncEntityKind.task,
  'task.edit': SyncEntityKind.task,
  'task.status': SyncEntityKind.task,
  'task.delete': SyncEntityKind.task,
  'task.restore': SyncEntityKind.task,
  'task.milestone_order': SyncEntityKind.task,
  'task.tag': SyncEntityKind.membership,
  'tag.create': SyncEntityKind.tag,
  'tag.edit': SyncEntityKind.tag,
  'tag.delete': SyncEntityKind.tag,
  'milestone.create': SyncEntityKind.milestone,
  'milestone.edit': SyncEntityKind.milestone,
  'milestone.delete': SyncEntityKind.milestone,
  'view.create': SyncEntityKind.view,
  'view.edit': SyncEntityKind.view,
  'view.delete': SyncEntityKind.view,
  'preference.set': SyncEntityKind.preference,
};

const _groups = {
  SyncEntityKind.task: {
    'title',
    'description',
    'priority',
    'estimate_minutes',
    'due',
    'status_group',
    'existence',
    'milestone_order',
  },
  SyncEntityKind.tag: {'name', 'existence'},
  SyncEntityKind.milestone: {'title', 'completion', 'existence', 'parent'},
  SyncEntityKind.membership: {'membership'},
  SyncEntityKind.view: {'name', 'query', 'existence'},
  SyncEntityKind.preference: {'value'},
};

bool isSyncFieldGroup(SyncEntityKind kind, String group) =>
    _groups[kind]!.contains(group);

final class RestorePrecondition {
  RestorePrecondition(this.deleteOperationId, this.revision) {
    _uuid(deleteOperationId);
    if (revision < 1 || revision > maxSyncInteger) {
      throw const FormatException('Invalid deletion revision.');
    }
  }
  final String deleteOperationId;
  final int revision;
  Map<String, Object?> toJson() => {
    'delete_operation_id': deleteOperationId,
    'revision': revision,
  };
}

/// Immutable wire envelope. Semantic command validation belongs to server apply;
/// a representable but invalid command must receive a consumed rejection receipt.
final class AccountOperation {
  AccountOperation({
    required this.operationId,
    required this.deviceEpoch,
    required this.sequence,
    required this.entity,
    required this.command,
    required Map<String, FieldPatch> patches,
    List<OperationDependency> dependencies = const [],
    Map<String, Object?> provenance = const {},
    this.restore,
  }) : patches = Map.unmodifiable(patches),
       dependencies = List.unmodifiable(dependencies),
       provenance = _freeze(provenance) as Map<String, Object?> {
    _uuid(operationId);
    _uuid(deviceEpoch);
    if ((command == 'task.restore') != (restore != null)) {
      throw const FormatException(
        'Restore requires an exact deletion identity.',
      );
    }
    if (sequence < 1 || sequence > 9007199254740991) {
      throw const FormatException('Invalid operation sequence.');
    }
    if (_commandKinds[command] != entity.kind ||
        patches.isEmpty ||
        patches.keys.any((g) => !_groups[entity.kind]!.contains(g))) {
      throw const FormatException('Invalid command/group identity.');
    }
    for (final patch in patches.values) {
      if (patch.base case PredecessorBase base) {
        if (base.sequence >= sequence || base.operationId == operationId) {
          throw const FormatException(
            'Predecessor must precede this operation.',
          );
        }
      }
    }
    for (final dependency in dependencies) {
      if (dependency.sequence >= sequence ||
          dependency.operationId == operationId) {
        throw const FormatException('Dependency must precede this operation.');
      }
    }
    if (utf8.encode(payloadIdentity).length > maxAccountOperationBytes) {
      throw const FormatException('Operation exceeds 64 KiB.');
    }
  }

  final String operationId, deviceEpoch, command;
  final int sequence;
  final SyncEntity entity;
  final Map<String, FieldPatch> patches;
  final List<OperationDependency> dependencies;
  final Map<String, Object?> provenance;
  final RestorePrecondition? restore;

  Map<String, Object?> toJson() => {
    'protocol_version': accountSyncProtocolVersion,
    'operation_id': operationId,
    'device_epoch': deviceEpoch,
    'sequence': sequence,
    'entity': entity.toJson(),
    'command': command,
    'patches': {for (final e in patches.entries) e.key: e.value.toJson()},
    'dependencies': dependencies.map((d) => d.toJson()).toList(),
    'provenance': provenance,
    if (restore != null) 'restore': restore!.toJson(),
  };

  /// Exact canonical payload comparison. No hash-collision assumption is needed.
  String get payloadIdentity => canonicalSyncJson(toJson());
}

enum FieldDisposition { applied, equivalent, conflict, held, recovery }

final class AcceptedField {
  AcceptedField(this.revision, Object? value) : value = _freeze(value) {
    if (revision < 1 || revision > maxSyncInteger) {
      throw const FormatException('Invalid accepted revision.');
    }
  }
  final int revision;
  final Object? value;
}

/// A missing receipt is NOT an accepted predecessor. The caller must validate
/// operation/entity/group/epoch identity before supplying this accepted result.
FieldDisposition compareField(
  FieldPatch patch,
  AcceptedField? current, {
  AcceptedField? acceptedPredecessor,
  bool predecessorNeedsRecovery = false,
}) {
  var base = patch.base;
  if (base is PredecessorBase) {
    if (predecessorNeedsRecovery) return FieldDisposition.recovery;
    if (acceptedPredecessor == null) return FieldDisposition.held;
    if (canonicalSyncJson(base.value) !=
        canonicalSyncJson(acceptedPredecessor.value)) {
      return FieldDisposition.recovery;
    }
    base = ObservedBase(acceptedPredecessor.revision, base.value);
  }
  if (base is AbsentBase && current == null) return FieldDisposition.applied;
  if (base is ObservedBase &&
      current != null &&
      base.revision == current.revision) {
    // Equal revisions with different original values indicate corrupt bases.
    if (canonicalSyncJson(base.value) != canonicalSyncJson(current.value)) {
      return FieldDisposition.recovery;
    }
    return FieldDisposition.applied;
  }
  if (current != null &&
      canonicalSyncJson(patch.value) == canonicalSyncJson(current.value)) {
    return FieldDisposition.equivalent;
  }
  return FieldDisposition.conflict;
}
