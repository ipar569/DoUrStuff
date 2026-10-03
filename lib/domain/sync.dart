import 'dart:convert';

const syncProtocolVersion = 1;

/// Encoding shared with the future RPC adapter; values are JSON-compatible.
final class ChangeOperation {
  const ChangeOperation({
    required this.operationId,
    required this.deviceEpoch,
    required this.sequence,
    required this.entityId,
    required this.command,
    required this.changes,
    this.baseVersions = const {},
    this.dependencies = const [],
  });

  final String operationId;
  final String deviceEpoch;
  final int sequence;
  final String entityId;
  final String command;
  final Map<String, Object?> changes;
  final Map<String, int> baseVersions;
  final List<String> dependencies;

  Map<String, Object?> toJson() => {
    'protocol_version': syncProtocolVersion,
    'operation_id': operationId,
    'device_epoch': deviceEpoch,
    'sequence': sequence,
    'entity_id': entityId,
    'command': command,
    'changes': changes,
    'base_versions': baseVersions,
    'dependencies': dependencies,
  };

  String encode() => jsonEncode(toJson());
}

final class ChangePage {
  const ChangePage({
    required this.serverEpoch,
    required this.cursor,
    required this.groups,
    required this.hasMore,
  });
  final String serverEpoch;
  final int cursor;

  /// Each group is one whole server transaction; never split a revision.
  final List<Map<String, Object?>> groups;
  final bool hasMore;
}

abstract interface class SyncTransport {
  Future<Map<String, Object?>> applyOperations(
    List<ChangeOperation> operations,
  );
  Future<ChangePage> pullChanges({required String epoch, required int after});
}
