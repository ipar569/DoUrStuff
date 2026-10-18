import 'dart:convert';

import 'account_sync.dart';

/// Versioned provider-free RPC contracts. No transport ships with this milestone.
typedef AccountCursor = ({String serverEpoch, int revision});

enum SyncFailureCode {
  authenticationRequired,
  accountDeleted,
  unsupportedProtocol,
  serverEpochChanged,
  cursorExpired,
  snapshotExpired,
  sequenceGap,
  payloadMismatch,
  rateLimited,
  unavailable,
}

sealed class SyncReply<T> {
  const SyncReply();
}

final class SyncSuccess<T> extends SyncReply<T> {
  const SyncSuccess(this.value);
  final T value;
}

/// Server preflight failures consume no sequences. A transport failure leaves
/// consumption UNKNOWN (the response may have been lost after commit): retry
/// the same payload, never reuse its sequence. Details contain categories/counts
/// only, never task payloads, SQL text, credentials or tokens.
final class SyncFailure<T> extends SyncReply<T> {
  const SyncFailure(this.code, {this.expectedSequence, this.retryAfterSeconds});
  final SyncFailureCode code;
  final int? expectedSequence, retryAfterSeconds;
}

final class ApplyRequest {
  ApplyRequest({
    required this.cursor,
    required List<AccountOperation> operations,
  }) : operations = List.unmodifiable(operations) {
    if (operations.isEmpty || operations.length > maxApplyOperations) {
      throw const FormatException('Apply batch requires 1..32 operations.');
    }
    for (var i = 1; i < operations.length; i++) {
      if (operations[i].deviceEpoch != operations.first.deviceEpoch ||
          operations[i].sequence != operations[i - 1].sequence + 1) {
        throw const FormatException(
          'Apply batch must be contiguous in one epoch.',
        );
      }
    }
    if (utf8.encode(canonicalSyncJson(toJson())).length > 1048576) {
      throw const FormatException('Apply batch exceeds 1 MiB.');
    }
  }
  final AccountCursor cursor;
  final List<AccountOperation> operations;
  Map<String, Object?> toJson() => {
    'protocol_version': accountSyncProtocolVersion,
    'server_epoch': cursor.serverEpoch,
    'after_revision': cursor.revision,
    'operations': operations.map((o) => o.toJson()).toList(),
  };
}

enum ReceiptDisposition { applied, partial, conflict, held, rejected }

final class FieldOutcome {
  const FieldOutcome({
    required this.group,
    required this.disposition,
    this.accepted,
    this.recoveryId,
  });
  final String group;
  final FieldDisposition disposition;
  final AcceptedField? accepted;
  final String? recoveryId;
}

sealed class OperationResult {
  const OperationResult(this.operationId, this.sequence);
  final String operationId;
  final int sequence;
}

/// A receipt means durable sequence consumption, not necessarily canonical apply.
final class OperationReceipt extends OperationResult {
  OperationReceipt({
    required String operationId,
    required int sequence,
    required this.revision,
    required this.disposition,
    required List<FieldOutcome> fields,
    this.rejectionCode,
  }) : fields = List.unmodifiable(fields),
       super(operationId, sequence);
  final int revision;
  final ReceiptDisposition disposition;
  final List<FieldOutcome> fields;
  final String? rejectionCode;
}

/// Detailed receipt expired: never replay; snapshot reconciles pending work.
final class AlreadyProcessed extends OperationResult {
  const AlreadyProcessed(super.operationId, super.sequence);
}

final class ApplyResult {
  ApplyResult({
    required this.cursor,
    required this.deviceHighWater,
    required List<OperationResult> results,
  }) : results = List.unmodifiable(results);
  final AccountCursor cursor;
  final int deviceHighWater;
  final List<OperationResult> results;
}

/// Complete canonical entity/group state, including minimal deletion identity.
final class ShadowRecord {
  ShadowRecord({
    required this.entity,
    required Map<String, AcceptedField> fields,
    this.deleteOperationId,
  }) : fields = Map.unmodifiable(fields);
  final SyncEntity entity;
  final Map<String, AcceptedField> fields;
  final String? deleteOperationId;
}

/// Unresolved conflicts and held operations outlive detailed receipt retention.
final class RecoveryRecord {
  const RecoveryRecord({
    required this.id,
    required this.revision,
    required this.operation,
    required this.group,
    required this.disposition,
    this.canonical,
  });
  final String id, group;
  // Required for optimistic resolution; the record can change after creation.
  final int revision;
  final AccountOperation operation;
  final FieldDisposition disposition;
  final AcceptedField? canonical;
}

final class RevisionGroup {
  RevisionGroup({
    required this.revision,
    required List<ShadowRecord> records,
    required List<RecoveryRecord> recovery,
  }) : records = List.unmodifiable(records),
       recovery = List.unmodifiable(recovery);
  final int revision;
  final List<ShadowRecord> records;
  final List<RecoveryRecord> recovery;
}

final class PullRequest {
  const PullRequest(this.after, {this.limit = 200});
  final AccountCursor after;
  final int limit;
}

final class PullResult {
  PullResult({
    required this.through,
    required this.committedHighWater,
    required this.hasMore,
    required List<RevisionGroup> groups,
  }) : groups = List.unmodifiable(groups);
  final AccountCursor through;
  final int committedHighWater;
  final bool hasMore;
  final List<RevisionGroup> groups;
}

final class RegisterDeviceRequest {
  const RegisterDeviceRequest({
    required this.deviceEpoch,
    required this.serverEpoch,
  });
  final String deviceEpoch, serverEpoch;
}

final class RegisteredDevice {
  const RegisteredDevice({required this.cursor, required this.highWater});
  final AccountCursor cursor;
  final int highWater;
}

final class BeginSnapshotRequest {
  const BeginSnapshotRequest(this.serverEpoch);
  final String serverEpoch;
}

final class SnapshotManifest {
  SnapshotManifest({
    required this.token,
    required this.at,
    required this.expiresAtUtc,
    required this.pageCount,
    required this.recordCount,
    required Map<String, int> deviceHighWaters,
  }) : deviceHighWaters = Map.unmodifiable(deviceHighWaters);
  final String token;
  final AccountCursor at;
  final DateTime expiresAtUtc;
  final int pageCount, recordCount;
  final Map<String, int> deviceHighWaters;
}

final class SnapshotPageRequest {
  const SnapshotPageRequest({
    required this.serverEpoch,
    required this.token,
    required this.page,
  });
  final String serverEpoch, token;
  final int page;
}

final class SnapshotPage {
  SnapshotPage({
    required this.token,
    required this.at,
    required this.page,
    required this.isLast,
    required List<ShadowRecord> records,
    required List<RecoveryRecord> recovery,
  }) : records = List.unmodifiable(records),
       recovery = List.unmodifiable(recovery);
  final String token;
  final AccountCursor at;
  final int page;
  final bool isLast;
  final List<ShadowRecord> records;
  final List<RecoveryRecord> recovery;
}

/// Resolution is an ordinary sequenced immutable replacement operation plus a
/// version check on the unresolved recovery record. Original payload stays kept.
final class ResolveConflictRequest {
  const ResolveConflictRequest({
    required this.cursor,
    required this.conflictId,
    required this.expectedConflictRevision,
    required this.replacement,
  });
  final AccountCursor cursor;
  final String conflictId;
  final int expectedConflictRevision;
  final AccountOperation replacement;
}

abstract interface class AccountSyncTransport {
  Future<SyncReply<RegisteredDevice>> registerDevice(
    RegisterDeviceRequest request,
  );
  Future<SyncReply<ApplyResult>> apply(ApplyRequest request);
  Future<SyncReply<PullResult>> pull(PullRequest request);
  Future<SyncReply<SnapshotManifest>> beginSnapshot(
    BeginSnapshotRequest request,
  );
  Future<SyncReply<SnapshotPage>> readSnapshotPage(SnapshotPageRequest request);
  Future<SyncReply<ApplyResult>> resolveConflict(
    ResolveConflictRequest request,
  );
}
