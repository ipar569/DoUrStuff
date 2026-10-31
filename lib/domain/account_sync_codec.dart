import 'dart:convert';

import 'account_sync.dart';
import 'account_sync_rpc.dart';
import 'account_task_validation.dart';

typedef _Json = Map<String, Object?>;

Never _bad() =>
    throw const FormatException('Invalid account protocol message.');

_Json _map(Object? value, [String? keys]) {
  if (value is! Map || value.keys.any((k) => k is! String)) _bad();
  final result = value.cast<String, Object?>();
  if (keys != null) {
    final expected = keys.split(' ').toSet();
    if (result.length != expected.length ||
        result.keys.any((key) => !expected.contains(key))) {
      _bad();
    }
  }
  return result;
}

String _string(Object? value) => value is String ? value : _bad();
bool _bool(Object? value) => value is bool ? value : _bad();
int _int(Object? value, {int min = 0, int max = maxSyncInteger}) =>
    value is int && value >= min && value <= max ? value : _bad();
String _id(Object? value) {
  final id = _string(value);
  if (!RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
      .hasMatch(id)) {
    _bad();
  }
  return id;
}

T _enum<T extends Enum>(List<T> values, Object? value) {
  for (final item in values) {
    if (item.name == value) return item;
  }
  return _bad();
}

List<T> _list<T>(Object? value, T Function(Object?) read, {int max = 200}) {
  if (value is! List || value.length > max) _bad();
  return value.map(read).toList();
}

void _unique(Iterable<Object> values) {
  final list = values.toList();
  if (list.toSet().length != list.length) _bad();
}

void _version(_Json json) {
  if (json['protocol_version'] is! int ||
      json['protocol_version'] != accountSyncProtocolVersion) {
    _bad();
  }
}

void _bounded(Object? value, int bytes, {int maxDepth = maxSyncValueDepth}) {
  // Transport adapters must also bound the raw body BEFORE JSON decoding.
  if (utf8.encode(canonicalSyncJson(value, maxDepth: maxDepth)).length >
      bytes) {
    _bad();
  }
}

AccountCursor _cursor(Object? value) {
  final json = _map(value, 'server_epoch revision');
  return (
    serverEpoch: _id(json['server_epoch']),
    revision: _int(json['revision']),
  );
}

_Json _cursorJson(AccountCursor cursor) => {
  'server_epoch': cursor.serverEpoch,
  'revision': cursor.revision,
};

SyncEntity _entity(Object? value) {
  final json = _map(value, 'kind key');
  return SyncEntity(
    _enum(SyncEntityKind.values, json['kind']),
    _list(json['key'], _string, max: 2),
  );
}

FieldBase _base(Object? value) {
  final json = _map(value);
  switch (json['kind']) {
    case 'absent':
      _map(json, 'kind');
      return const AbsentBase();
    case 'observed':
      _map(json, 'kind revision value');
      return ObservedBase(_int(json['revision'], min: 1), json['value']);
    case 'predecessor':
      _map(json, 'kind operation_id sequence value');
      return PredecessorBase(
        _id(json['operation_id']),
        _int(json['sequence'], min: 1),
        json['value'],
      );
    default:
      return _bad();
  }
}

/// Parses structural v2 envelopes. Command/relationship policies are separate.
AccountOperation decodeAccountOperation(Object? value) {
  _bounded(value, maxAccountOperationBytes);
  final json = _map(
    value,
    'protocol_version operation_id device_epoch sequence entity command patches dependencies provenance${_map(value).containsKey('restore') ? ' restore' : ''}',
  );
  _version(json);
  final patches = _map(json['patches']);
  return AccountOperation(
    operationId: _id(json['operation_id']),
    deviceEpoch: _id(json['device_epoch']),
    sequence: _int(json['sequence'], min: 1),
    entity: _entity(json['entity']),
    command: _string(json['command']),
    patches: {for (final e in patches.entries) e.key: _patch(e.value)},
    dependencies: _list(json['dependencies'], (value) {
      final dependency = _map(value, 'entity operation_id sequence group');
      if (dependency['group'] != 'existence') _bad();
      final entity = _entity(dependency['entity']);
      if (!isSyncFieldGroup(entity.kind, 'existence')) _bad();
      return OperationDependency(
        entity: entity,
        operationId: _id(dependency['operation_id']),
        sequence: _int(dependency['sequence'], min: 1),
      );
    }, max: 32),
    provenance: _map(json['provenance']),
    restore: json.containsKey('restore') ? _restore(json['restore']) : null,
  );
}

RestorePrecondition _restore(Object? value) {
  final json = _map(value, 'delete_operation_id revision');
  return RestorePrecondition(
    _id(json['delete_operation_id']),
    _int(json['revision'], min: 1),
  );
}

FieldPatch _patch(Object? value) {
  final json = _map(value, 'base value');
  return FieldPatch(_base(json['base']), json['value']);
}

AcceptedField _accepted(Object? value) {
  final json = _map(value, 'revision value');
  return AcceptedField(_int(json['revision'], min: 1), json['value']);
}

_Json _acceptedJson(AcceptedField value) => {
  'revision': value.revision,
  'value': value.value,
};

/// Strict versioned boundary shared by local fixtures and future adapters.
/// Rejects unknown/missing keys and contradictory outcomes on encode AND decode.
/// Domain constructors are useful for building drafts; use codecs at wire edges.
final class AccountRpcCodec<Q, R> {
  const AccountRpcCodec._(
    this._writeRequest,
    this._readRequest,
    this._writeResult,
    this._readResult,
  );
  final _Json Function(Q) _writeRequest;
  final Q Function(_Json) _readRequest;
  final _Json Function(R) _writeResult;
  final R Function(_Json) _readResult;

  Map<String, Object?> encodeRequest(Q request) {
    final json = {
      'protocol_version': accountSyncProtocolVersion,
      ..._writeRequest(request),
    };
    decodeRequest(json);
    return json;
  }

  Q decodeRequest(Object? value) {
    _bounded(value, 1048576);
    final json = _map(value);
    _version(json);
    return _readRequest(json);
  }

  Map<String, Object?> encodeReply(SyncReply<R> reply) {
    final _Json json = {'protocol_version': accountSyncProtocolVersion};
    switch (reply) {
      case SyncSuccess<R>():
        json.addAll({'status': 'success', 'result': _writeResult(reply.value)});
      case SyncFailure<R>():
        json.addAll({
          'status': 'failure',
          'code': reply.code.name,
          'expected_sequence': reply.expectedSequence,
          'retry_after_seconds': reply.retryAfterSeconds,
        });
    }
    decodeReply(json);
    return json;
  }

  SyncReply<R> decodeReply(Object? value) {
    // Embedded operations and accepted values retain their own depth-16 checks.
    // This allowance is only for the surrounding RPC/revision/recovery wrappers.
    _bounded(value, 4194304, maxDepth: maxSyncReplyDepth);
    final json = _map(value);
    _version(json);
    if (json['status'] == 'success') {
      _map(json, 'protocol_version status result');
      return SyncSuccess(_readResult(_map(json['result'])));
    }
    _map(
      json,
      'protocol_version status code expected_sequence retry_after_seconds',
    );
    if (json['status'] != 'failure') _bad();
    final code = _enum(SyncFailureCode.values, json['code']);
    final expected = json['expected_sequence'];
    final retry = json['retry_after_seconds'];
    if ((code == SyncFailureCode.sequenceGap) != (expected != null)) _bad();
    if (retry != null &&
        code != SyncFailureCode.rateLimited &&
        code != SyncFailureCode.unavailable) {
      _bad();
    }
    return SyncFailure(
      code,
      expectedSequence: expected == null ? null : _int(expected, min: 1),
      retryAfterSeconds: retry == null ? null : _int(retry, max: 86400),
    );
  }
}

final registerDeviceCodec =
    AccountRpcCodec<RegisterDeviceRequest, RegisteredDevice>._(
      (q) => {'device_epoch': q.deviceEpoch, 'server_epoch': q.serverEpoch},
      (j) {
        _map(j, 'protocol_version device_epoch server_epoch');
        return RegisterDeviceRequest(
          deviceEpoch: _id(j['device_epoch']),
          serverEpoch: _id(j['server_epoch']),
        );
      },
      (r) => {'cursor': _cursorJson(r.cursor), 'high_water': r.highWater},
      (j) {
        _map(j, 'cursor high_water');
        return RegisteredDevice(
          cursor: _cursor(j['cursor']),
          highWater: _int(j['high_water']),
        );
      },
    );

final applyCodec = AccountRpcCodec<ApplyRequest, ApplyResult>._(
  (q) => q.toJson(),
  (j) {
    _map(j, 'protocol_version server_epoch after_revision operations');
    final operations = _list(
      j['operations'],
      decodeAccountOperation,
      max: maxApplyOperations,
    );
    _unique(operations.map((o) => o.operationId));
    return ApplyRequest(
      cursor: (
        serverEpoch: _id(j['server_epoch']),
        revision: _int(j['after_revision']),
      ),
      operations: operations,
    );
  },
  _applyJson,
  _applyResult,
);

_Json _applyJson(ApplyResult r) => {
  'cursor': _cursorJson(r.cursor),
  'device_high_water': r.deviceHighWater,
  'results': r.results.map(_operationResultJson).toList(),
};

_Json _operationResultJson(OperationResult result) => switch (result) {
  AlreadyProcessed() => {
    'kind': 'already_processed',
    'operation_id': result.operationId,
    'sequence': result.sequence,
  },
  OperationReceipt() => {
    'kind': 'receipt',
    'operation_id': result.operationId,
    'sequence': result.sequence,
    'revision': result.revision,
    'disposition': result.disposition.name,
    'rejection_code': result.rejectionCode,
    'fields': result.fields
        .map(
          (f) => {
            'group': f.group,
            'disposition': f.disposition.name,
            'accepted': f.accepted == null ? null : _acceptedJson(f.accepted!),
            'recovery_id': f.recoveryId,
          },
        )
        .toList(),
  },
};

OperationResult _operationResult(Object? value) {
  final j = _map(value);
  final id = _id(j['operation_id']);
  final sequence = _int(j['sequence'], min: 1);
  if (j['kind'] == 'already_processed') {
    _map(j, 'kind operation_id sequence');
    return AlreadyProcessed(id, sequence);
  }
  _map(
    j,
    'kind operation_id sequence revision disposition rejection_code fields',
  );
  if (j['kind'] != 'receipt') _bad();
  final revision = _int(j['revision'], min: 1);
  final disposition = _enum(ReceiptDisposition.values, j['disposition']);
  final fields = _list(j['fields'], (value) {
    final f = _map(value, 'group disposition accepted recovery_id');
    final group = _string(f['group']);
    if (!SyncEntityKind.values.any((kind) => isSyncFieldGroup(kind, group))) {
      _bad();
    }
    final disposition = _enum(FieldDisposition.values, f['disposition']);
    final accepted = f['accepted'] == null ? null : _accepted(f['accepted']);
    final recoveryId = f['recovery_id'] == null ? null : _id(f['recovery_id']);
    final applied =
        disposition == FieldDisposition.applied ||
        disposition == FieldDisposition.equivalent;
    if (applied != (accepted != null) ||
        applied == (recoveryId != null) ||
        (accepted != null && accepted.revision > revision)) {
      _bad();
    }
    return FieldOutcome(
      group: group,
      disposition: disposition,
      accepted: accepted,
      recoveryId: recoveryId,
    );
  }, max: 8);
  _unique(fields.map((f) => f.group));
  final applied = fields.where((f) => f.accepted != null).length;
  final rejection = j['rejection_code'];
  if (disposition == ReceiptDisposition.rejected) {
    if (fields.isNotEmpty ||
        rejection is! String ||
        !RegExp(r'^[a-z_]{1,64}$').hasMatch(rejection)) {
      _bad();
    }
  } else {
    if (rejection != null || fields.isEmpty) _bad();
    final expected = applied == fields.length
        ? ReceiptDisposition.applied
        : applied > 0
        ? ReceiptDisposition.partial
        : fields.every((f) => f.disposition == FieldDisposition.held)
        ? ReceiptDisposition.held
        : ReceiptDisposition.conflict;
    if (disposition != expected) _bad();
  }
  return OperationReceipt(
    operationId: id,
    sequence: sequence,
    revision: revision,
    disposition: disposition,
    fields: fields,
    rejectionCode: rejection as String?,
  );
}

ApplyResult _applyResult(_Json j) {
  _map(j, 'cursor device_high_water results');
  final cursor = _cursor(j['cursor']);
  final high = _int(j['device_high_water']);
  final results = _list(
    j['results'],
    _operationResult,
    max: maxApplyOperations,
  );
  if (results.isEmpty) _bad();
  _unique(results.map((r) => r.operationId));
  for (var i = 0; i < results.length; i++) {
    final r = results[i];
    if (r.sequence > high ||
        (i > 0 && r.sequence != results[i - 1].sequence + 1) ||
        (r is OperationReceipt && r.revision > cursor.revision)) {
      _bad();
    }
  }
  return ApplyResult(cursor: cursor, deviceHighWater: high, results: results);
}

_Json _shadowJson(ShadowRecord r) => {
  'entity': r.entity.toJson(),
  'fields': {for (final f in r.fields.entries) f.key: _acceptedJson(f.value)},
  'delete_operation_id': r.deleteOperationId,
};

ShadowRecord _shadow(Object? value) {
  final j = _map(value, 'entity fields delete_operation_id');
  final entity = _entity(j['entity']);
  final fields = {
    for (final f in _map(j['fields']).entries) f.key: _accepted(f.value),
  };
  if (fields.isEmpty ||
      fields.keys.any((g) => !isSyncFieldGroup(entity.kind, g))) {
    _bad();
  }
  return ShadowRecord(
    entity: entity,
    fields: fields,
    deleteOperationId: j['delete_operation_id'] == null
        ? null
        : _id(j['delete_operation_id']),
  );
}

_Json _recoveryJson(RecoveryRecord r) => {
  'id': r.id,
  'revision': r.revision,
  'operation': r.operation.toJson(),
  'group': r.group,
  'disposition': r.disposition.name,
  'canonical': r.canonical == null ? null : _acceptedJson(r.canonical!),
};

RecoveryRecord _recovery(Object? value) {
  final j = _map(value, 'id revision operation group disposition canonical');
  final operation = decodeAccountOperation(j['operation']);
  final group = _string(j['group']);
  final disposition = _enum(FieldDisposition.values, j['disposition']);
  final revision = _int(j['revision'], min: 1);
  final canonical = j['canonical'] == null ? null : _accepted(j['canonical']);
  if (!operation.patches.containsKey(group) ||
      disposition == FieldDisposition.applied ||
      disposition == FieldDisposition.equivalent ||
      (canonical != null && canonical.revision > revision)) {
    _bad();
  }
  return RecoveryRecord(
    id: _id(j['id']),
    revision: revision,
    operation: operation,
    group: group,
    disposition: disposition,
    canonical: canonical,
  );
}

void _recordsAt(
  int revision,
  List<ShadowRecord> records,
  List<RecoveryRecord> recovery,
) {
  _unique(records.map((r) => r.entity.identity));
  _unique(recovery.map((r) => r.id));
  if (records.any((r) => r.fields.values.any((f) => f.revision > revision)) ||
      recovery.any((r) => r.revision > revision)) {
    _bad();
  }
}

final pullCodec = AccountRpcCodec<PullRequest, PullResult>._(
  (q) => {'after': _cursorJson(q.after), 'limit': q.limit},
  (j) {
    _map(j, 'protocol_version after limit');
    return PullRequest(
      _cursor(j['after']),
      limit: _int(j['limit'], min: 1, max: 200),
    );
  },
  (r) => {
    'through': _cursorJson(r.through),
    'committed_high_water': r.committedHighWater,
    'has_more': r.hasMore,
    'groups': r.groups
        .map(
          (g) => {
            'revision': g.revision,
            'records': g.records.map(_shadowJson).toList(),
            'recovery': g.recovery.map(_recoveryJson).toList(),
          },
        )
        .toList(),
  },
  (j) {
    _map(j, 'through committed_high_water has_more groups');
    final through = _cursor(j['through']);
    final high = _int(j['committed_high_water']);
    final more = _bool(j['has_more']);
    final groups = _list(j['groups'], (value) {
      final g = _map(value, 'revision records recovery');
      final revision = _int(g['revision'], min: 1);
      final records = _list(g['records'], _shadow, max: 1000);
      final recovery = _list(g['recovery'], _recovery, max: 1000);
      _recordsAt(revision, records, recovery);
      return RevisionGroup(
        revision: revision,
        records: records,
        recovery: recovery,
      );
    });
    if (through.revision > high ||
        more != (through.revision < high) ||
        (more && groups.isEmpty) ||
        (groups.isNotEmpty && groups.last.revision != through.revision)) {
      _bad();
    }
    for (var i = 1; i < groups.length; i++) {
      if (groups[i].revision <= groups[i - 1].revision) _bad();
    }
    return PullResult(
      through: through,
      committedHighWater: high,
      hasMore: more,
      groups: groups,
    );
  },
);

final beginSnapshotCodec =
    AccountRpcCodec<BeginSnapshotRequest, SnapshotManifest>._(
      (q) => {'server_epoch': q.serverEpoch},
      (j) {
        _map(j, 'protocol_version server_epoch');
        return BeginSnapshotRequest(_id(j['server_epoch']));
      },
      (r) => {
        'token': r.token,
        'at': _cursorJson(r.at),
        'expires_at_utc': r.expiresAtUtc.toIso8601String(),
        'page_count': r.pageCount,
        'record_count': r.recordCount,
        'device_high_waters': r.deviceHighWaters,
      },
      (j) {
        _map(
          j,
          'token at expires_at_utc page_count record_count device_high_waters',
        );
        final time = _string(j['expires_at_utc']);
        final expiry = DateTime.tryParse(time);
        if (expiry == null ||
            !expiry.isUtc ||
            expiry.toIso8601String() != time) {
          _bad();
        }
        final waters = _map(j['device_high_waters']);
        if (waters.length > 1000) _bad();
        return SnapshotManifest(
          token: _id(j['token']),
          at: _cursor(j['at']),
          expiresAtUtc: expiry,
          pageCount: _int(j['page_count'], min: 1, max: 1000000),
          recordCount: _int(j['record_count']),
          deviceHighWaters: {
            for (final e in waters.entries) _id(e.key): _int(e.value),
          },
        );
      },
    );

final snapshotPageCodec = AccountRpcCodec<SnapshotPageRequest, SnapshotPage>._(
  (q) => {'server_epoch': q.serverEpoch, 'token': q.token, 'page': q.page},
  (j) {
    _map(j, 'protocol_version server_epoch token page');
    return SnapshotPageRequest(
      serverEpoch: _id(j['server_epoch']),
      token: _id(j['token']),
      page: _int(j['page'], max: 999999),
    );
  },
  (r) => {
    'token': r.token,
    'at': _cursorJson(r.at),
    'page': r.page,
    'is_last': r.isLast,
    'records': r.records.map(_shadowJson).toList(),
    'recovery': r.recovery.map(_recoveryJson).toList(),
  },
  (j) {
    _map(j, 'token at page is_last records recovery');
    final at = _cursor(j['at']);
    final records = _list(j['records'], _shadow);
    final recovery = _list(j['recovery'], _recovery);
    _recordsAt(at.revision, records, recovery);
    return SnapshotPage(
      token: _id(j['token']),
      at: at,
      page: _int(j['page'], max: 999999),
      isLast: _bool(j['is_last']),
      records: records,
      recovery: recovery,
    );
  },
);

final resolveConflictCodec =
    AccountRpcCodec<ResolveConflictRequest, ApplyResult>._(
      (q) => {
        'cursor': _cursorJson(q.cursor),
        'conflict_id': q.conflictId,
        'expected_conflict_revision': q.expectedConflictRevision,
        'replacement': q.replacement.toJson(),
      },
      (j) {
        _map(
          j,
          'protocol_version cursor conflict_id expected_conflict_revision replacement',
        );
        final cursor = _cursor(j['cursor']);
        final revision = _int(j['expected_conflict_revision'], min: 1);
        if (revision > cursor.revision) _bad();
        return ResolveConflictRequest(
          cursor: cursor,
          conflictId: _id(j['conflict_id']),
          expectedConflictRevision: revision,
          replacement: decodeAccountOperation(j['replacement']),
        );
      },
      _applyJson,
      _applyResult,
    );

/// Bind registration to the requested server incarnation before saving state.
/// Adapters must separately enforce the active profile/generation boundary.
void validateRegisterDeviceReply(
  RegisterDeviceRequest request,
  RegisteredDevice result,
) {
  registerDeviceCodec.encodeRequest(request);
  registerDeviceCodec.encodeReply(SyncSuccess(result));
  if (result.cursor.serverEpoch != request.serverEpoch) _bad();
}

/// Validate the snapshot's server incarnation and lifetime before staging pages.
void validateBeginSnapshotReply(
  BeginSnapshotRequest request,
  SnapshotManifest manifest,
  DateTime nowUtc,
) {
  beginSnapshotCodec.encodeRequest(request);
  beginSnapshotCodec.encodeReply(SyncSuccess(manifest));
  if (manifest.at.serverEpoch != request.serverEpoch ||
      !nowUtc.isUtc ||
      !nowUtc.isBefore(manifest.expiresAtUtc)) {
    _bad();
  }
}

/// Correlate a structurally valid response before committing any local ack.
void validateApplyReply(ApplyRequest request, ApplyResult result) {
  applyCodec.encodeRequest(request);
  applyCodec.encodeReply(SyncSuccess(result));
  if (result.cursor.serverEpoch != request.cursor.serverEpoch ||
      result.cursor.revision < request.cursor.revision ||
      result.results.length != request.operations.length) {
    _bad();
  }
  for (var i = 0; i < request.operations.length; i++) {
    final operation = request.operations[i];
    final reply = result.results[i];
    if (reply.operationId != operation.operationId ||
        reply.sequence != operation.sequence) {
      _bad();
    }
    if (reply is OperationReceipt &&
        reply.disposition != ReceiptDisposition.rejected) {
      if (reply.fields.length != operation.patches.length ||
          reply.fields.any(
            (f) =>
                !operation.patches.containsKey(f.group) ||
                (f.accepted != null &&
                    canonicalSyncJson(f.accepted!.value) !=
                        canonicalSyncJson(operation.patches[f.group]!.value)),
          )) {
        _bad();
      }
    }
  }
}

void validatePullReply(PullRequest request, PullResult result) {
  pullCodec.encodeRequest(request);
  pullCodec.encodeReply(SyncSuccess(result));
  if (result.through.serverEpoch != request.after.serverEpoch ||
      result.through.revision < request.after.revision ||
      result.groups.length > request.limit ||
      (result.groups.isNotEmpty &&
          result.groups.first.revision <= request.after.revision) ||
      (result.groups.isEmpty &&
          result.through.revision != request.after.revision)) {
    _bad();
  }
}

void validateResolutionReply(
  ResolveConflictRequest request,
  ApplyResult result,
) {
  resolveConflictCodec.encodeRequest(request);
  validateApplyReply(
    ApplyRequest(cursor: request.cursor, operations: [request.replacement]),
    result,
  );
}

void validateSnapshotPage(
  SnapshotManifest manifest,
  SnapshotPageRequest request,
  SnapshotPage page,
  DateTime nowUtc,
) {
  beginSnapshotCodec.encodeReply(SyncSuccess(manifest));
  snapshotPageCodec.encodeRequest(request);
  snapshotPageCodec.encodeReply(SyncSuccess(page));
  if (!nowUtc.isUtc ||
      !nowUtc.isBefore(manifest.expiresAtUtc) ||
      request.serverEpoch != manifest.at.serverEpoch ||
      request.token != manifest.token ||
      request.page >= manifest.pageCount ||
      page.token != manifest.token ||
      page.at != manifest.at ||
      page.page != request.page ||
      page.isLast != (page.page == manifest.pageCount - 1)) {
    _bad();
  }
  // Global duplicate/count checks remain the durable staging installer's job.
}

// Explicit negotiation keeps legacy v2 codecs strict: they cannot silently
// discard history. Embedded command envelopes retain their original v2 bytes.
_Json _withoutHistoryVersion(_Json json) {
  if (json['history_version'] is! int || json['history_version'] != 1) _bad();
  return {...json}..remove('history_version');
}

_Json _historyJson(StatusHistoryEvent e) => {
  'version': 1,
  'operation_id': e.operationId,
  'task_id': e.taskId,
  'revision': e.revision,
  'previous_status': e.previousStatus == null
      ? null
      : _acceptedJson(e.previousStatus!),
  'status': _acceptedJson(e.status),
  'fields': {for (final f in e.fields.entries) f.key: _acceptedJson(f.value)},
  'provenance': e.provenance,
  'recorded_at_utc': e.recordedAtUtc.toIso8601String(),
  'operation': e.operation?.toJson(),
};

StatusHistoryEvent _history(Object? value) {
  final j = _map(
    value,
    'version operation_id task_id revision previous_status status fields provenance recorded_at_utc operation',
  );
  if (j['version'] is! int || j['version'] != 1) _bad();
  final operationId = _id(j['operation_id']);
  final taskId = _id(j['task_id']);
  final revision = _int(j['revision'], min: 1);
  final previous = j['previous_status'] == null
      ? null
      : _accepted(j['previous_status']);
  final status = _accepted(j['status']);
  final fields = {
    for (final f in _map(j['fields']).entries) f.key: _accepted(f.value),
  };
  final provenance = _map(j['provenance']);
  _bounded(provenance, maxAccountOperationBytes);
  final time = _string(j['recorded_at_utc']);
  final recorded = DateTime.tryParse(time);
  final op = j['operation'] == null
      ? null
      : decodeAccountOperation(j['operation']);
  if (recorded == null ||
      !recorded.isUtc ||
      recorded.toIso8601String() != time ||
      status.revision != revision ||
      !validAccountStatusGroup(status.value) ||
      (previous != null &&
          (previous.revision >= revision ||
              !validAccountStatusGroup(previous.value))) ||
      fields.keys.any((g) => !isSyncFieldGroup(SyncEntityKind.task, g)) ||
      fields.values.any((f) => f.revision > revision) ||
      fields['status_group'] == null ||
      canonicalSyncJson(_acceptedJson(fields['status_group']!)) !=
          canonicalSyncJson(_acceptedJson(status)) ||
      (op != null &&
          (op.operationId != operationId ||
              op.entity.kind != SyncEntityKind.task ||
              op.entity.key.single != taskId ||
              !const {
                'task.create',
                'task.status',
                'task.edit',
              }.contains(op.command) ||
              !op.patches.containsKey('status_group') ||
              canonicalSyncJson(op.patches['status_group']!.value) !=
                  canonicalSyncJson(status.value) ||
              canonicalSyncJson(op.provenance) !=
                  canonicalSyncJson(provenance)))) {
    _bad();
  }
  return StatusHistoryEvent(
    operationId: operationId,
    taskId: taskId,
    revision: revision,
    previousStatus: previous,
    status: status,
    fields: fields,
    provenance: provenance,
    recordedAtUtc: recorded,
    operation: op,
  );
}

List<StatusHistoryEvent> _historyList(
  Object? value,
  int revision, {
  bool exact = false,
  int max = 200,
}) {
  final events = _list(value, _history, max: max);
  _unique(events.map((e) => e.operationId));
  if (events.any(
    (e) => exact ? e.revision != revision : e.revision > revision,
  )) {
    _bad();
  }
  return events;
}

final historyPullCodec = AccountRpcCodec<PullRequest, HistoryPullResult>._(
  (q) => {...pullCodec.encodeRequest(q), 'history_version': 1},
  (j) => pullCodec.decodeRequest(_withoutHistoryVersion(j)),
  (r) => {
    ...pullCodec._writeResult(r.changes),
    'history_version': 1,
    'groups': r.groups
        .map(
          (g) => {
            'revision': g.changes.revision,
            'records': g.changes.records.map(_shadowJson).toList(),
            'recovery': g.changes.recovery.map(_recoveryJson).toList(),
            'history': g.history.map(_historyJson).toList(),
          },
        )
        .toList(),
  },
  (j) {
    final plain = _withoutHistoryVersion(j);
    final groups = _list(
      plain['groups'],
      (g) => _map(g, 'revision records recovery history'),
    );
    final histories = groups
        .map(
          (g) => _historyList(
            g['history'],
            _int(g['revision'], min: 1),
            exact: true,
            max: 1000,
          ),
        )
        .toList();
    plain['groups'] = groups.map((g) => {...g}..remove('history')).toList();
    final changes = pullCodec._readResult(plain);
    _unique(histories.expand((h) => h).map((e) => e.operationId));
    return HistoryPullResult(
      through: changes.through,
      committedHighWater: changes.committedHighWater,
      hasMore: changes.hasMore,
      groups: [
        for (var i = 0; i < groups.length; i++)
          HistoryRevisionGroup(changes.groups[i], histories[i]),
      ],
    );
  },
);

final historyBeginSnapshotCodec =
    AccountRpcCodec<BeginSnapshotRequest, SnapshotManifest>._(
      (q) => {...beginSnapshotCodec.encodeRequest(q), 'history_version': 1},
      (j) => beginSnapshotCodec.decodeRequest(_withoutHistoryVersion(j)),
      (r) => {...beginSnapshotCodec._writeResult(r), 'history_version': 1},
      (j) => beginSnapshotCodec._readResult(_withoutHistoryVersion(j)),
    );

final historySnapshotPageCodec =
    AccountRpcCodec<SnapshotPageRequest, HistorySnapshotPage>._(
      (q) => {...snapshotPageCodec.encodeRequest(q), 'history_version': 1},
      (j) => snapshotPageCodec.decodeRequest(_withoutHistoryVersion(j)),
      (r) => {
        ...snapshotPageCodec._writeResult(r.changes),
        'history_version': 1,
        'history': r.history.map(_historyJson).toList(),
      },
      (j) {
        final plain = _withoutHistoryVersion(j);
        final history = plain.remove('history');
        final changes = snapshotPageCodec._readResult(plain);
        return HistorySnapshotPage(
          changes,
          _historyList(history, changes.at.revision),
        );
      },
    );

void validateHistoryPullReply(PullRequest request, HistoryPullResult result) {
  historyPullCodec.encodeReply(SyncSuccess(result));
  validatePullReply(request, result.changes);
}

void validateHistorySnapshotPage(
  SnapshotManifest manifest,
  SnapshotPageRequest request,
  HistorySnapshotPage page,
  DateTime nowUtc,
) {
  historySnapshotPageCodec.encodeReply(SyncSuccess(page));
  validateSnapshotPage(manifest, request, page.changes, nowUtc);
}

_Json _withoutResolutionVersion(_Json j) {
  if (j['resolution_version'] is! int || j['resolution_version'] != 1) _bad();
  return {...j}..remove('resolution_version');
}

_Json _resolutionJson(RecoveryResolution r) => {
  'version': 1,
  'conflict_id': r.conflictId,
  'expected_conflict_revision': r.expectedConflictRevision,
  'revision': r.revision,
  'operation_id': r.operationId,
  'device_epoch': r.deviceEpoch,
  'sequence': r.sequence,
  'choice': r.choice.name,
};

RecoveryResolution _resolution(Object? value) {
  final j = _map(
    value,
    'version conflict_id expected_conflict_revision revision operation_id device_epoch sequence choice',
  );
  if (j['version'] is! int || j['version'] != 1) _bad();
  final expected = _int(j['expected_conflict_revision'], min: 1);
  final revision = _int(j['revision'], min: 1);
  if (expected >= revision) _bad();
  return RecoveryResolution(
    conflictId: _id(j['conflict_id']),
    expectedConflictRevision: expected,
    revision: revision,
    operationId: _id(j['operation_id']),
    deviceEpoch: _id(j['device_epoch']),
    sequence: _int(j['sequence'], min: 1),
    choice: _enum(RecoveryChoice.values, j['choice']),
  );
}

List<RecoveryResolution> _resolutions(
  Object? value,
  int revision, {
  bool exact = false,
}) {
  final result = _list(value, _resolution);
  _unique(result.map((r) => r.conflictId));
  if (result.any(
    (r) => exact ? r.revision != revision : r.revision > revision,
  )) {
    _bad();
  }
  return result;
}

final resolveRecoveryCodec =
    AccountRpcCodec<ResolveRecoveryRequest, ResolveRecoveryResult>._(
      (q) => {
        'resolution_version': 1,
        'cursor': _cursorJson(q.cursor),
        'operation_id': q.operationId,
        'device_epoch': q.deviceEpoch,
        'sequence': q.sequence,
        'conflict_id': q.conflictId,
        'expected_conflict_revision': q.expectedConflictRevision,
        'observed_fields': q.observedFields == null
            ? null
            : {
                for (final f in q.observedFields!.entries)
                  f.key: _acceptedJson(f.value),
              },
        'choice': q.choice.name,
        'replacement': q.replacement?.toJson(),
        'held_choices': q.heldChoices
            .map(
              (c) => {
                'id': c.id,
                'revision': c.revision,
                'choice': c.choice.name,
              },
            )
            .toList(),
      },
      (j) {
        _map(
          j,
          'protocol_version resolution_version cursor operation_id device_epoch sequence conflict_id expected_conflict_revision observed_fields choice replacement held_choices',
        );
        _withoutResolutionVersion(j);
        final cursor = _cursor(j['cursor']);
        final id = _id(j['operation_id']), device = _id(j['device_epoch']);
        final conflict = _id(j['conflict_id']);
        final sequence = _int(j['sequence'], min: 1);
        final expected = _int(j['expected_conflict_revision'], min: 1);
        final fields = j['observed_fields'] == null
            ? null
            : {
                for (final f in _map(j['observed_fields']).entries)
                  f.key: _accepted(f.value),
              };
        final choice = _enum(RecoveryChoice.values, j['choice']);
        final op = j['replacement'] == null
            ? null
            : decodeAccountOperation(j['replacement']);
        final held = _list(j['held_choices'], (v) {
          final c = _map(v, 'id revision choice');
          return HeldRecoveryChoice(
            _id(c['id']),
            _int(c['revision'], min: 1),
            _enum(HeldChoice.values, c['choice']),
          );
        }, max: 199);
        _unique(held.map((h) => h.id));
        if (expected > cursor.revision ||
            held.any((h) => h.id == conflict || h.revision > cursor.revision) ||
            (fields?.values.any((f) => f.revision > cursor.revision) ??
                false) ||
            (choice == RecoveryChoice.replace) != (op != null) ||
            (op != null &&
                (op.operationId != id ||
                    op.deviceEpoch != device ||
                    op.sequence != sequence ||
                    op.patches.length != 1 ||
                    op.dependencies.isNotEmpty ||
                    op.patches.values.single.base is PredecessorBase))) {
          _bad();
        }
        return ResolveRecoveryRequest(
          cursor: cursor,
          operationId: id,
          deviceEpoch: device,
          sequence: sequence,
          conflictId: conflict,
          expectedConflictRevision: expected,
          observedFields: fields,
          choice: choice,
          replacement: op,
          heldChoices: held,
        );
      },
      (r) => {
        'resolution_version': 1,
        'cursor': _cursorJson(r.cursor),
        'device_high_water': r.deviceHighWater,
        'resolutions': r.resolutions.map(_resolutionJson).toList(),
      },
      (j) {
        final plain = _withoutResolutionVersion(j);
        _map(plain, 'cursor device_high_water resolutions');
        final cursor = _cursor(plain['cursor']);
        final water = _int(plain['device_high_water'], min: 1);
        final resolutions = _resolutions(
          plain['resolutions'],
          cursor.revision,
          exact: true,
        );
        if (resolutions.isEmpty ||
            resolutions.any(
              (r) =>
                  r.sequence != water ||
                  r.operationId != resolutions.first.operationId ||
                  r.deviceEpoch != resolutions.first.deviceEpoch,
            )) {
          _bad();
        }
        return ResolveRecoveryResult(cursor, water, resolutions);
      },
    );

void validateRecoveryResolutionReply(
  ResolveRecoveryRequest request,
  ResolveRecoveryResult result,
) {
  resolveRecoveryCodec.encodeRequest(request);
  resolveRecoveryCodec.encodeReply(SyncSuccess(result));
  final expected = {
    request.conflictId: (request.expectedConflictRevision, request.choice),
    for (final h in request.heldChoices.where(
      (h) => h.choice == HeldChoice.discard,
    ))
      h.id: (h.revision, RecoveryChoice.discard),
  };
  if (result.cursor.serverEpoch != request.cursor.serverEpoch ||
      result.deviceHighWater != request.sequence ||
      result.resolutions.length != expected.length ||
      result.resolutions.any(
        (r) =>
            r.operationId != request.operationId ||
            r.deviceEpoch != request.deviceEpoch ||
            expected[r.conflictId] != (r.expectedConflictRevision, r.choice),
      )) {
    _bad();
  }
  // A retry after a new snapshot may return the original earlier receipt.
}

final recoveryPullCodec = AccountRpcCodec<PullRequest, RecoveryPullResult>._(
  (q) => {...historyPullCodec.encodeRequest(q), 'resolution_version': 1},
  (j) => historyPullCodec.decodeRequest(_withoutResolutionVersion(j)),
  (r) {
    if (r.changes.groups.length != r.resolutions.length) _bad();
    final j = historyPullCodec._writeResult(r.changes);
    j['groups'] = [
      for (var i = 0; i < r.resolutions.length; i++)
        {
          ..._map((j['groups'] as List)[i]),
          'resolutions': r.resolutions[i].map(_resolutionJson).toList(),
        },
    ];
    return {...j, 'resolution_version': 1};
  },
  (j) {
    final plain = _withoutResolutionVersion(j);
    final groups = _list(
      plain['groups'],
      (g) => _map(g, 'revision records recovery history resolutions'),
    );
    final resolutions = groups
        .map(
          (g) => _resolutions(
            g['resolutions'],
            _int(g['revision'], min: 1),
            exact: true,
          ),
        )
        .toList();
    _unique(resolutions.expand((r) => r).map((r) => r.conflictId));
    plain['groups'] = groups.map((g) => {...g}..remove('resolutions')).toList();
    return RecoveryPullResult(historyPullCodec._readResult(plain), resolutions);
  },
);

final recoveryBeginSnapshotCodec =
    AccountRpcCodec<BeginSnapshotRequest, SnapshotManifest>._(
      (q) => {
        ...historyBeginSnapshotCodec.encodeRequest(q),
        'resolution_version': 1,
      },
      (j) =>
          historyBeginSnapshotCodec.decodeRequest(_withoutResolutionVersion(j)),
      (r) => {
        ...historyBeginSnapshotCodec._writeResult(r),
        'resolution_version': 1,
      },
      (j) =>
          historyBeginSnapshotCodec._readResult(_withoutResolutionVersion(j)),
    );

final recoverySnapshotPageCodec =
    AccountRpcCodec<SnapshotPageRequest, RecoverySnapshotPage>._(
      (q) => {
        ...historySnapshotPageCodec.encodeRequest(q),
        'resolution_version': 1,
      },
      (j) =>
          historySnapshotPageCodec.decodeRequest(_withoutResolutionVersion(j)),
      (r) => {
        ...historySnapshotPageCodec._writeResult(r.changes),
        'resolution_version': 1,
        'resolutions': r.resolutions.map(_resolutionJson).toList(),
      },
      (j) {
        final plain = _withoutResolutionVersion(j);
        final resolutions = plain.remove('resolutions');
        final changes = historySnapshotPageCodec._readResult(plain);
        return RecoverySnapshotPage(
          changes,
          _resolutions(resolutions, changes.changes.at.revision),
        );
      },
    );

void validateRecoveryPullReply(PullRequest request, RecoveryPullResult result) {
  recoveryPullCodec.encodeReply(SyncSuccess(result));
  validateHistoryPullReply(request, result.changes);
}

void validateRecoverySnapshotPage(
  SnapshotManifest manifest,
  SnapshotPageRequest request,
  RecoverySnapshotPage page,
  DateTime nowUtc,
) {
  recoverySnapshotPageCodec.encodeReply(SyncSuccess(page));
  validateHistorySnapshotPage(manifest, request, page.changes, nowUtc);
}
