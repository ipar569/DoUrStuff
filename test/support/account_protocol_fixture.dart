import 'dart:convert';

import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';

/// Executable contract model ONLY: no transport, PostgreSQL, RLS or durability.
/// It deliberately supports task.edit field patches only; do not ship it.
AccountOperation readFixtureOperation(Map<String, dynamic> json) {
  final operation = decodeAccountOperation(json);
  if (operation.command != 'task.edit' || operation.dependencies.isNotEmpty) {
    throw UnsupportedError('Outside field-chain fixture scope');
  }
  return operation;
}

class FixtureAccount {
  FixtureAccount(this.epoch);
  final String epoch;
  int highWater = 0, revision = 2;
  final Map<String, AcceptedField> fields = {};
  final Map<String, AccountOperation> operations = {};
  final Map<int, OperationReceipt> receipts = {};
  final Map<String, Map<String, FieldDisposition>> dispositions = {};
  final Map<String, Map<String, AcceptedField>> accepted = {};
  final Map<String, Map<String, Object?>> recovery = {};

  String fieldKey(SyncEntity entity, String group) =>
      '${entity.identity}/$group';

  OperationResult apply(AccountOperation operation) {
    if (operation.deviceEpoch != epoch) throw StateError('Wrong device epoch');
    final old = operations[operation.operationId];
    if (old != null && old.payloadIdentity != operation.payloadIdentity) {
      throw StateError('Payload mismatch');
    }
    if (operation.sequence <= highWater) {
      final receipt = receipts[operation.sequence];
      if (receipt != null && receipt.operationId != operation.operationId) {
        throw StateError('Sequence identity mismatch');
      }
      return receipt ??
          AlreadyProcessed(operation.operationId, operation.sequence);
    }
    if (operation.sequence != highWater + 1) throw StateError('Sequence gap');
    if (operation.command != 'task.edit' || operation.dependencies.isNotEmpty) {
      throw UnsupportedError('Outside field-chain fixture scope');
    }
    final title = operation.patches['title'];
    if (title != null &&
        (title.value is! String ||
            (title.value as String).trim().isEmpty ||
            (title.value as String).trim().length > 500)) {
      // Fixture semantic rejection is still a durable consumed command.
      // Preserve every candidate, including otherwise valid independent groups.
      highWater = operation.sequence;
      revision++;
      operations[operation.operationId] = operation;
      dispositions[operation.operationId] = {
        for (final group in operation.patches.keys)
          group: FieldDisposition.recovery,
      };
      for (final entry in operation.patches.entries) {
        final current = fields[fieldKey(operation.entity, entry.key)];
        recovery['${operation.operationId}/${entry.key}'] = {
          'operation_id': operation.operationId,
          'entity': operation.entity.toJson(),
          'group': entry.key,
          'base': entry.value.base.toJson(),
          'local': entry.value.value,
          'server': current == null
              ? null
              : {'revision': current.revision, 'value': current.value},
          'disposition': 'recovery',
          'rejection_code': 'invalid_title',
        };
      }
      return receipts[operation.sequence] = OperationReceipt(
        operationId: operation.operationId,
        sequence: operation.sequence,
        revision: revision,
        disposition: ReceiptDisposition.rejected,
        fields: [],
        rejectionCode: 'invalid_title',
      );
    }
    final outcomes = <FieldOutcome>[];
    final decisions = <String, FieldDisposition>{};
    final applied = <String, AcceptedField>{};
    final nextRevision = revision + 1;
    for (final e in operation.patches.entries) {
      final current = fields[fieldKey(operation.entity, e.key)];
      AcceptedField? predecessor;
      var needsRecovery = false;
      if (e.value.base case PredecessorBase base) {
        final parent = operations[base.operationId];
        needsRecovery =
            parent == null ||
            parent.deviceEpoch != epoch ||
            parent.sequence != base.sequence ||
            parent.entity.identity != operation.entity.identity ||
            !parent.patches.containsKey(e.key);
        predecessor = accepted[base.operationId]?[e.key];
        needsRecovery =
            needsRecovery ||
            dispositions[base.operationId]?[e.key] == FieldDisposition.recovery;
      }
      final decision = compareField(
        e.value,
        current,
        acceptedPredecessor: predecessor,
        predecessorNeedsRecovery: needsRecovery,
      );
      decisions[e.key] = decision;
      AcceptedField? result;
      if (decision == FieldDisposition.applied) {
        result = AcceptedField(nextRevision, e.value.value);
        fields[fieldKey(operation.entity, e.key)] = result;
      } else if (decision == FieldDisposition.equivalent) {
        result = current;
      }
      if (result != null) applied[e.key] = result;
      if (result == null) {
        recovery['${operation.operationId}/${e.key}'] = {
          'operation_id': operation.operationId,
          'entity': operation.entity.toJson(),
          'group': e.key,
          'base': e.value.base.toJson(),
          'local': e.value.value,
          'server': current == null
              ? null
              : {'revision': current.revision, 'value': current.value},
          'disposition': decision.name,
        };
      }
      outcomes.add(
        FieldOutcome(
          group: e.key,
          disposition: decision,
          accepted: result,
          recoveryId: result == null
              ? '${operation.operationId}/${e.key}'
              : null,
        ),
      );
    }
    // Model one atomic server transition. Real account-row locking is 3.1 work.
    highWater = operation.sequence;
    revision = nextRevision;
    operations[operation.operationId] = operation;
    dispositions[operation.operationId] = decisions;
    accepted[operation.operationId] = applied;
    final ReceiptDisposition disposition;
    if (applied.length == decisions.length) {
      disposition = ReceiptDisposition.applied;
    } else if (applied.isNotEmpty) {
      disposition = ReceiptDisposition.partial;
    } else if (decisions.values.every((d) => d == FieldDisposition.held)) {
      disposition = ReceiptDisposition.held;
    } else {
      disposition = ReceiptDisposition.conflict;
    }
    return receipts[operation.sequence] = OperationReceipt(
      operationId: operation.operationId,
      sequence: operation.sequence,
      revision: revision,
      disposition: disposition,
      fields: outcomes,
    );
  }

  void expireReceipts() {
    receipts.clear();
    final unresolved = recovery.values.map((r) => r['operation_id']).toSet();
    operations.removeWhere((id, _) => !unresolved.contains(id));
    accepted.removeWhere((id, _) => !unresolved.contains(id));
    dispositions.removeWhere((id, _) => !unresolved.contains(id));
  }

  /// Simulated snapshot/reload of unresolved payloads, bases and accepted state.
  /// Proves representation retention, not physical crash recovery.
  String snapshot() => jsonEncode({
    'epoch': epoch,
    'high_water': highWater,
    'revision': revision,
    'fields': {
      for (final e in fields.entries)
        e.key: {'revision': e.value.revision, 'value': e.value.value},
    },
    'operations': operations.values.map((o) => o.toJson()).toList(),
    'dispositions': {
      for (final e in dispositions.entries)
        e.key: {for (final d in e.value.entries) d.key: d.value.name},
    },
    'accepted': {
      for (final e in accepted.entries)
        e.key: {
          for (final f in e.value.entries)
            f.key: {'revision': f.value.revision, 'value': f.value.value},
        },
    },
    'recovery': recovery,
  });

  factory FixtureAccount.restore(String snapshot) {
    final data = jsonDecode(snapshot) as Map<String, dynamic>;
    final model = FixtureAccount(data['epoch'] as String)
      ..highWater = data['high_water'] as int
      ..revision = data['revision'] as int;
    for (final e in (data['fields'] as Map<String, dynamic>).entries) {
      model.fields[e.key] = AcceptedField(
        e.value['revision'] as int,
        e.value['value'],
      );
    }
    for (final json in data['operations'] as List) {
      final operation = readFixtureOperation(json as Map<String, dynamic>);
      model.operations[operation.operationId] = operation;
    }
    for (final e in (data['dispositions'] as Map<String, dynamic>).entries) {
      model.dispositions[e.key] = {
        for (final f in (e.value as Map<String, dynamic>).entries)
          f.key: FieldDisposition.values.byName(f.value as String),
      };
    }
    for (final e in (data['accepted'] as Map<String, dynamic>).entries) {
      model.accepted[e.key] = {
        for (final f in (e.value as Map<String, dynamic>).entries)
          f.key: AcceptedField(f.value['revision'] as int, f.value['value']),
      };
    }
    for (final e in (data['recovery'] as Map<String, dynamic>).entries) {
      model.recovery[e.key] = (e.value as Map).cast<String, Object?>();
    }
    return model;
  }
}
