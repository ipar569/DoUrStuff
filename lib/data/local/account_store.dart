import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/account_sync.dart';
import '../../domain/account_sync_codec.dart';
import '../../domain/account_sync_rpc.dart';
import 'database.dart' hide AccountOperation;
import 'account_command_validation.dart';

/// A read model for recovery/projection work, not a native task or an upload.
/// Original operations remain separate from accepted state; no implicit rebase.
final class AccountProjection {
  AccountProjection(
    this.accepted,
    this.proposals,
    this.unresolvedRecovery,
    this.values,
    this.pendingSources,
    this.visible,
  );
  final ShadowRecord? accepted;
  final List<AccountProposal> proposals;
  final List<RecoveryRecord> unresolvedRecovery;

  /// Effective values have no fabricated server revision. A pending source is
  /// explicit; accepted revisions remain available only through [accepted].
  final Map<String, Object?> values;
  final Map<String, String> pendingSources;
  final bool visible;
}

final class AccountProposal {
  AccountProposal(
    this.operation,
    this.transportState,
    this.needsReconciliation,
    this.outcomes,
    this.closedGroups,
    this.acceptedFields,
    Map<String, FieldDisposition> projectedOutcomes,
  ) : _projectedOutcomes = projectedOutcomes;
  final AccountOperation operation;
  final String transportState;
  final bool needsReconciliation;
  final Map<String, String> outcomes;
  final Set<String> closedGroups;
  final Map<String, AcceptedField> acceptedFields;

  /// Local preview decisions, never server outcomes or rewritten bases.
  final Map<String, FieldDisposition> _projectedOutcomes;
  Map<String, FieldDisposition> get projectedOutcomes =>
      Map.unmodifiable(_projectedOutcomes);
}

/// Local-only foundation. No transport, auth or guest command path calls this.
/// Every operation checks a persisted profile generation inside its transaction.
final class AccountStore {
  AccountStore._(this.db, this.ownerId, this.generation);
  final AppDatabase db;
  final String ownerId;
  final int generation;
  static const maxSnapshotBytes = 64 * 1024 * 1024;

  /// A new lease invalidates callbacks from previous instances, including after
  /// reopen. This is not account authentication or restored-backup detection.
  static Future<AccountStore> open(
    AppDatabase db,
    String ownerId,
  ) => db.transaction(() async {
    SyncEntity(SyncEntityKind.task, [ownerId]); // Strict UUID validation.
    final profile = await db
        .customSelect('SELECT * FROM profile_metadata')
        .getSingle();
    if (profile.read<String>('profile_id') != 'account-$ownerId') {
      throw StateError('Account profile mismatch.');
    }
    final states = await db.customSelect('SELECT * FROM account_state').get();
    if (states.isEmpty) {
      // Reserved v1 tables have no account protocol semantics. Preserve and
      // fail closed rather than infer kind, owner, bases or adoption intent.
      for (final table in db.allTables.where(
        (t) =>
            !t.actualTableName.startsWith('account_') &&
            t.actualTableName != 'profile_metadata' &&
            t.actualTableName != 'sync_checkpoint',
      )) {
        if ((await db
                .customSelect('SELECT 1 FROM ${table.actualTableName} LIMIT 1')
                .get())
            .isNotEmpty) {
          throw StateError('Legacy profile needs explicit recovery.');
        }
      }
      final checkpoint = await db
          .customSelect('SELECT * FROM sync_checkpoint')
          .getSingle();
      if (checkpoint.read<int>('cursor') != 0 ||
          checkpoint.data.entries.any(
            (e) => e.key != 'singleton' && e.key != 'cursor' && e.value != null,
          )) {
        throw StateError('Legacy checkpoint needs explicit recovery.');
      }
      await db.customStatement(
        'INSERT INTO account_state(singleton,owner_id,generation) VALUES(1,?,1)',
        [ownerId],
      );
      return AccountStore._(db, ownerId, 1);
    }
    if (states.single.read<String>('owner_id') != ownerId) {
      throw StateError('Account owner mismatch.');
    }
    final next = states.single.read<int>('generation') + 1;
    await db.customStatement(
      'UPDATE account_state SET generation=? WHERE singleton=1',
      [next],
    );
    return AccountStore._(db, ownerId, next);
  });

  Future<QueryRow> _guard() async {
    final profile = await db
        .customSelect('SELECT profile_id FROM profile_metadata')
        .getSingle();
    final state = await db
        .customSelect('SELECT * FROM account_state')
        .getSingle();
    if (profile.read<String>('profile_id') != 'account-$ownerId' ||
        state.read<String>('owner_id') != ownerId ||
        state.read<int>('generation') != generation) {
      throw StateError('Stale account callback.');
    }
    return state;
  }

  Future<AccountCursor?> checkpoint() => db.transaction(() async {
    final state = await _guard();
    final epoch = state.readNullable<String>('server_epoch');
    return epoch == null
        ? null
        : (serverEpoch: epoch, revision: state.read<int>('cursor'));
  });

  /// Commits explicit original bases, identity, local intent history and reminder
  /// invalidation together. No network/OS action or guest translation occurs.
  /// Retry with the same caller-allocated UUID and arguments after uncertainty.
  Future<AccountOperation> commitCommand({
    required String operationId,
    required SyncEntity entity,
    required String command,
    required Map<String, FieldPatch> patches,
    List<OperationDependency> dependencies = const [],
    required DateTime occurredAtUtc,
  }) => db.transaction(() async {
    await _guard();
    if (!occurredAtUtc.isUtc) throw ArgumentError('Expected UTC provenance.');
    final profile = await db
        .customSelect('SELECT * FROM profile_metadata')
        .getSingle();
    final existing = await db
        .customSelect(
          'SELECT envelope_json FROM account_operations WHERE operation_id=?',
          variables: [Variable(operationId)],
        )
        .get();
    final original = existing.isEmpty
        ? null
        : decodeAccountOperation(
            jsonDecode(existing.single.read<String>('envelope_json')),
          );
    final operation = AccountOperation(
      operationId: operationId,
      deviceEpoch: profile.read<String>('device_epoch'),
      sequence: original?.sequence ?? profile.read<int>('next_sequence'),
      entity: entity,
      command: command,
      patches: patches,
      dependencies: dependencies,
      provenance: {'occurred_at': occurredAtUtc.millisecondsSinceEpoch},
    );
    if (!validLocalAccountCommand(operation)) {
      throw const FormatException(
        'Invalid or unsupported local account command.',
      );
    }
    if (original != null) {
      final history = await db
          .customSelect(
            'SELECT 1 FROM account_command_history WHERE operation_id=?',
            variables: [Variable(operationId)],
          )
          .get();
      if (history.isEmpty ||
          original.payloadIdentity != operation.payloadIdentity) {
        throw StateError('Command retry does not match committed intent.');
      }
      return original;
    }
    final before = await _projection(entity);
    await retainOperation(jsonEncode(operation.toJson()));
    final after = await _projection(entity);
    await db.customStatement(
      'INSERT INTO account_command_history VALUES(?,?,?,?,?)',
      [
        operation.operationId,
        entity.identity,
        occurredAtUtc.millisecondsSinceEpoch,
        _json(before.values),
        _json(after.values),
      ],
    );
    final dirty = {entity.identity};
    if (entity.kind == SyncEntityKind.milestone) {
      final parents = before.proposals
          .map((p) => p.operation.patches['parent']?.value)
          .whereType<String>();
      final parent =
          patches['parent']?.value ??
          before.values['parent'] ??
          before.accepted?.fields['parent']?.value ??
          parents.firstOrNull;
      if (parent is String) {
        dirty.add(SyncEntity(SyncEntityKind.task, [parent]).identity);
      }
    }
    for (final key in dirty) {
      await db.customStatement(
        'INSERT INTO account_notification_dirty(entity_key) VALUES(?) '
        'ON CONFLICT(entity_key) DO UPDATE SET generation=generation+1',
        [key],
      );
    }
    return operation;
  });

  /// Retains an already constructed, explicit account envelope. This is not a
  /// guest journal translator. Commands call within their local
  /// projection/history/dirty transaction; this method nests in that transaction.
  Future<void> retainOperation(String envelope) => db.transaction(() async {
    final state = await _guard();
    if (utf8.encode(envelope).length > maxAccountOperationBytes) {
      throw const FormatException('Operation exceeds local envelope bound.');
    }
    final operation = decodeAccountOperation(jsonDecode(envelope));
    final old = await db
        .customSelect(
          'SELECT payload_identity FROM account_operations WHERE operation_id=?',
          variables: [Variable(operation.operationId)],
        )
        .get();
    if (old.isNotEmpty) {
      if (old.single.read<String>('payload_identity') !=
          operation.payloadIdentity) {
        throw StateError('Operation identity mismatch.');
      }
      return;
    }
    final epoch = state.readNullable<String>('server_epoch');
    final waters =
        jsonDecode(state.read<String>('device_high_waters_json')) as Map;
    final profile = await db
        .customSelect('SELECT * FROM profile_metadata')
        .getSingle();
    if (epoch == null ||
        state.read<int>('requires_recovery') != 0 ||
        operation.deviceEpoch != profile.read<String>('device_epoch') ||
        operation.sequence != profile.read<int>('next_sequence') ||
        operation.sequence <= (waters[operation.deviceEpoch] as int? ?? 0)) {
      throw StateError(
        'Account operation requires a snapshot and contiguous local identity.',
      );
    }
    await _retainOriginal(operation);
    await db.customStatement(
      'INSERT INTO account_operations(operation_id,device_epoch,sequence,entity_key,envelope_json,payload_identity,origin_server_epoch) VALUES(?,?,?,?,?,?,?)',
      [
        operation.operationId,
        operation.deviceEpoch,
        operation.sequence,
        operation.entity.identity,
        envelope,
        operation.payloadIdentity,
        epoch,
      ],
    );
    await db.customStatement(
      'UPDATE profile_metadata SET next_sequence=next_sequence+1 WHERE singleton=1',
    );
  });

  /// Upload acknowledgement never advances the download cursor. Accepted
  /// predecessor results are retained separately from original envelopes.
  Future<void> retainApplyResult(ApplyRequest request, ApplyResult result) =>
      db.transaction(() async {
        final state = await _guard();
        validateApplyReply(request, result);
        if (state.readNullable<String>('server_epoch') !=
            request.cursor.serverEpoch) {
          throw StateError('Reply belongs to another server epoch.');
        }
        final encoded = applyCodec.encodeReply(SyncSuccess(result));
        final results = (encoded['result'] as Map)['results'] as List;
        for (var i = 0; i < request.operations.length; i++) {
          final operation = request.operations[i];
          final row = await db
              .customSelect(
                'SELECT * FROM account_operations WHERE operation_id=?',
                variables: [Variable(operation.operationId)],
              )
              .getSingle();
          if (row.read<String>('payload_identity') !=
                  operation.payloadIdentity ||
              row.read<String>('origin_server_epoch') !=
                  request.cursor.serverEpoch) {
            throw StateError('Reply does not match retained original.');
          }
          final receipt = result.results[i];
          if (receipt is AlreadyProcessed) {
            if (row.readNullable<String>('receipt_json') == null) {
              await db.customStatement(
                "UPDATE account_operations SET transport_state='reconcile' WHERE operation_id=?",
                [operation.operationId],
              );
            }
            continue;
          }
          final receiptJson = _json(results[i]);
          final previous = row.readNullable<String>('receipt_json');
          if (previous != null && previous != receiptJson) {
            throw StateError('Immutable receipt mismatch.');
          }
          await db.customStatement(
            "UPDATE account_operations SET transport_state='acknowledged',receipt_json=?,receipt_epoch=? WHERE operation_id=?",
            [receiptJson, request.cursor.serverEpoch, operation.operationId],
          );
          for (final field in (receipt as OperationReceipt).fields) {
            await db.customStatement(
              'INSERT OR REPLACE INTO account_field_outcomes VALUES(?,?,?,?,?)',
              [
                operation.operationId,
                field.group,
                field.disposition.name,
                field.accepted == null
                    ? null
                    : _json({
                        'revision': field.accepted!.revision,
                        'value': field.accepted!.value,
                      }),
                field.recoveryId,
              ],
            );
          }
          if (receipt.disposition == ReceiptDisposition.rejected) {
            for (final group in operation.patches.keys) {
              await db.customStatement(
                "INSERT OR REPLACE INTO account_field_outcomes VALUES(?,?,'recovery',NULL,NULL)",
                [operation.operationId, group],
              );
            }
          }
        }
      });

  Future<void> beginSnapshot(SnapshotManifest manifest, DateTime nowUtc) =>
      db.transaction(() async {
        final state = await _guard();
        validateBeginSnapshotReply(
          BeginSnapshotRequest(manifest.at.serverEpoch),
          manifest,
          nowUtc,
        );
        if (manifest.pageCount > 10000 ||
            manifest.recordCount > 1000000 ||
            (state.readNullable<String>('server_epoch') ==
                    manifest.at.serverEpoch &&
                manifest.at.revision < state.read<int>('cursor'))) {
          throw StateError(
            'Snapshot outside local bounds or older than accepted state.',
          );
        }
        final encoded = _json(
          recoveryBeginSnapshotCodec.encodeReply(SyncSuccess(manifest)),
        );
        if (state.readNullable<String>('server_epoch') ==
            manifest.at.serverEpoch) {
          final waters =
              jsonDecode(state.read<String>('device_high_waters_json')) as Map;
          if (waters.entries.any(
            (e) => (manifest.deviceHighWaters[e.key] ?? -1) < (e.value as int),
          )) {
            throw StateError('Snapshot device watermark moved backwards.');
          }
        }
        final previous = await db
            .customSelect('SELECT manifest_json FROM account_snapshot')
            .get();
        if (previous.isNotEmpty) {
          final old = _manifest(previous.single.read<String>('manifest_json'));
          if (old.token == manifest.token) {
            if (previous.single.read<String>('manifest_json') != encoded) {
              throw StateError('Snapshot manifest identity mismatch.');
            }
            return;
          }
        }
        await _clearStaging();
        await db.customStatement(
          'INSERT INTO account_snapshot(singleton,manifest_json) VALUES(1,?)',
          [encoded],
        );
      });

  /// Applies one bounded, negotiated history/resolution page atomically. The
  /// caller fetches outside SQLite and must refetch from checkpoint after a
  /// stale response (including a retry whose first commit already succeeded).
  /// No upload acknowledgement or device watermark is inferred from a pull.
  Future<void> applyPull(
    PullRequest request,
    RecoveryPullResult result,
  ) => db.transaction(() async {
    final state = await _guard();
    validateRecoveryPullReply(request, result);
    if (state.readNullable<String>('server_epoch') !=
            request.after.serverEpoch ||
        state.read<int>('cursor') != request.after.revision) {
      throw StateError('Pull does not start at the installed checkpoint.');
    }
    // Encoding also validates directly constructed values and the 4 MiB
    // wire bound. Work only from this detached representation after awaits.
    final reply = recoveryPullCodec.encodeReply(SyncSuccess(result));
    final groups = (reply['result'] as Map)['groups'] as List;
    final profile = await db
        .customSelect('SELECT device_epoch,next_sequence FROM profile_metadata')
        .getSingle();
    var needsRecovery = state.read<int>('requires_recovery') != 0;
    var revision = request.after.revision;
    var count = 0;
    for (final raw in groups) {
      final group = (raw as Map).cast<String, Object?>();
      if (group['revision'] != ++revision) {
        throw StateError('Pull revision gap.');
      }
      final records = _records(group);
      final shadows = <String, Map>{
        for (final record in records)
          if (record[0] == 'records')
            record[1] as String: jsonDecode(record[2] as String) as Map,
      };
      count += records.length;
      if (count > 10000) throw StateError('Pull record bound exceeded.');
      for (final record in records) {
        await _applyRecord(record, shadows);
        final value = jsonDecode(record[2] as String) as Map;
        final identity = record[0] == 'resolutions'
            ? value
            : value['operation'] as Map?;
        if (identity != null &&
            identity['device_epoch'] == profile.read<String>('device_epoch') &&
            (identity['sequence'] as int) >=
                profile.read<int>('next_sequence')) {
          // A consumed identity ahead of this installation proves missing
          // local history, not accepted fields or a safe sequence to reuse.
          needsRecovery = true;
        }
      }
    }
    await db.customStatement(
      'UPDATE account_state SET cursor=?,requires_recovery=? WHERE singleton=1',
      [revision, needsRecovery ? 1 : 0],
    );
  });

  Future<void> _applyRecord(
    List<Object?> record,
    Map<String, Map> shadows,
  ) async {
    final kind = record[0] as String;
    final key = record[1] as String;
    final encoded = record[2] as String;
    final value = jsonDecode(encoded) as Map;
    if (kind == 'resolutions') {
      await _checkDecisionIdentity(
        value['operation_id'] as String,
        value['device_epoch'] as String,
        value['sequence'] as int,
      );
    }
    final old = await db
        .customSelect(
          'SELECT record_json FROM account_records WHERE record_kind=? AND record_key=?',
          variables: [Variable(kind), Variable(key)],
        )
        .get();
    if (old.isNotEmpty) {
      final previousJson = old.single.read<String>('record_json');
      final previous = jsonDecode(previousJson) as Map;
      if (kind == 'history' || kind == 'resolutions') {
        if (previousJson != encoded) {
          throw StateError('Immutable downloaded record mismatch.');
        }
      } else if (kind == 'recovery') {
        if ((value['revision'] as int) < (previous['revision'] as int) ||
            (value['revision'] == previous['revision'] &&
                encoded != previousJson)) {
          throw StateError('Recovery revision mismatch.');
        }
      } else {
        final fields = value['fields'] as Map;
        final previousFields = previous['fields'] as Map;
        for (final entry in previousFields.entries) {
          final next = fields[entry.key] as Map?;
          final before = entry.value as Map;
          // Compaction also covers live children of deleted parents. Consult
          // the whole revision, independent of record order, then accepted DB
          // state; pending local visibility cannot authorize remote compaction.
          if (next == null) {
            if (entry.key == 'existence' ||
                entry.key == 'parent' ||
                !await _canCompact(value, shadows)) {
              throw StateError('Shadow lost a retained field.');
            }
          } else if ((next['revision'] as int) < (before['revision'] as int) ||
              (next['revision'] == before['revision'] &&
                  _json(next) != _json(before))) {
            throw StateError('Shadow field revision mismatch.');
          }
        }
        if (previous['delete_operation_id'] != null &&
            value['delete_operation_id'] != previous['delete_operation_id']) {
          if (value['delete_operation_id'] == null ||
              (fields['existence'] as Map?)?['value'] != false ||
              ((fields['existence'] as Map)['revision'] as int) <=
                  ((previousFields['existence'] as Map)['revision'] as int)) {
            throw StateError('Deletion identity mismatch.');
          }
        }
      }
    }
    if (kind == 'recovery' || kind == 'history') {
      if (kind == 'history') {
        final original = await db
            .customSelect(
              'SELECT payload_identity FROM account_originals WHERE operation_id=?',
              variables: [Variable(key)],
            )
            .get();
        if (original.isNotEmpty) {
          _checkHistoryOriginal(
            value,
            decodeAccountOperation(
              jsonDecode(original.single.read<String>('payload_identity')),
            ),
          );
        }
      }
      if (value['operation'] != null) {
        final operation = decodeAccountOperation(value['operation']);
        await _retainOriginal(operation);
        if (kind == 'recovery') {
          await _archiveRecovery(value, encoded, operation);
        }
      }
    }
    if (kind == 'recovery' || kind == 'resolutions') {
      final other = await db
          .customSelect(
            'SELECT record_json FROM account_records WHERE record_kind=? AND record_key=?',
            variables: [
              Variable(kind == 'recovery' ? 'resolutions' : 'recovery'),
              Variable(key),
            ],
          )
          .get();
      if (other.isNotEmpty) {
        final paired =
            jsonDecode(other.single.read<String>('record_json')) as Map;
        if ((kind == 'recovery' ? value['revision'] : paired['revision']) !=
            (kind == 'recovery'
                ? paired['expected_conflict_revision']
                : value['expected_conflict_revision'])) {
          throw StateError('Pull closure version mismatch.');
        }
      }
    }
    await db.customStatement(
      'INSERT OR REPLACE INTO account_records VALUES(?,?,?)',
      record,
    );
  }

  Future<bool> _canCompact(Map shadow, Map<String, Map> shadows) async {
    final fields = shadow['fields'] as Map;
    if ((fields['existence'] as Map?)?['value'] == false) return true;
    if ((shadow['entity'] as Map)['kind'] != 'milestone') return false;
    final parentId = (fields['parent'] as Map?)?['value'];
    if (parentId is! String) return false;
    final key = SyncEntity(SyncEntityKind.task, [parentId]).identity;
    var parent = shadows[key];
    if (parent == null) {
      final rows = await db
          .customSelect(
            "SELECT record_json FROM account_records WHERE record_kind='records' AND record_key=?",
            variables: [Variable(key)],
          )
          .get();
      if (rows.isEmpty) return false;
      parent = jsonDecode(rows.single.read<String>('record_json')) as Map;
    }
    return ((parent['fields'] as Map)['existence'] as Map?)?['value'] == false;
  }

  Future<void> _archiveRecovery(
    Map value,
    String encoded,
    AccountOperation operation,
  ) async {
    final previous = await db
        .customSelect(
          'SELECT * FROM account_recovery_archive WHERE candidate_id=?',
          variables: [Variable(value['id'] as String)],
        )
        .get();
    if (previous.isEmpty) {
      await db.customStatement(
        'INSERT INTO account_recovery_archive VALUES(?,?,?,?)',
        [value['id'], operation.operationId, value['group'], encoded],
      );
    } else if (previous.single.read<String>('operation_id') !=
            operation.operationId ||
        previous.single.read<String>('field_group') != value['group']) {
      throw StateError('Recovery original identity mismatch.');
    }
  }

  Future<SnapshotManifest?> stagedManifest() => db.transaction(() async {
    await _guard();
    final rows = await db
        .customSelect('SELECT manifest_json FROM account_snapshot')
        .get();
    return rows.isEmpty
        ? null
        : _manifest(rows.single.read<String>('manifest_json'));
  });

  Future<int?> nextSnapshotPage() => db.transaction(() async {
    await _guard();
    final rows = await db
        .customSelect('SELECT next_page FROM account_snapshot')
        .get();
    return rows.isEmpty ? null : rows.single.read<int>('next_page');
  });

  Future<void> stagePage(
    RecoverySnapshotPage page,
    DateTime nowUtc,
  ) => db.transaction(() async {
    await _guard();
    final stage = await db
        .customSelect('SELECT * FROM account_snapshot')
        .getSingle();
    final manifest = _manifest(stage.read<String>('manifest_json'));
    final changes = page.changes.changes;
    validateRecoverySnapshotPage(
      manifest,
      SnapshotPageRequest(
        serverEpoch: manifest.at.serverEpoch,
        token: manifest.token,
        page: changes.page,
      ),
      page,
      nowUtc,
    );
    final reply = recoverySnapshotPageCodec.encodeReply(SyncSuccess(page));
    final encoded = _json(reply);
    final next = stage.read<int>('next_page');
    if (changes.page < next) {
      final previous = await db
          .customSelect(
            'SELECT reply_json FROM account_snapshot_pages WHERE page=?',
            variables: [Variable(changes.page)],
          )
          .getSingle();
      if (previous.read<String>('reply_json') != encoded) {
        throw StateError('Snapshot page identity mismatch.');
      }
      return;
    }
    if (changes.page != next) throw StateError('Snapshot page gap.');
    final records = _records((reply['result'] as Map).cast<String, Object?>());
    final count = stage.read<int>('record_count') + records.length;
    final bytes = stage.read<int>('byte_count') + utf8.encode(encoded).length;
    if (count > manifest.recordCount ||
        bytes > maxSnapshotBytes ||
        (changes.isLast && count != manifest.recordCount)) {
      throw StateError('Snapshot count or storage bound mismatch.');
    }
    for (final record in records) {
      // Plain INSERT enforces global uniqueness across all pages.
      await db.customStatement(
        'INSERT INTO account_snapshot_records VALUES(?,?,?)',
        record,
      );
    }
    await db.customStatement('INSERT INTO account_snapshot_pages VALUES(?,?)', [
      next,
      encoded,
    ]);
    await db.customStatement(
      'UPDATE account_snapshot SET next_page=?,record_count=?,byte_count=? WHERE singleton=1',
      [next + 1, count, bytes],
    );
  });

  Future<void> installSnapshot(DateTime nowUtc) => db.transaction(() async {
    final state = await _guard();
    final stage = await db
        .customSelect('SELECT * FROM account_snapshot')
        .getSingle();
    final manifest = _manifest(stage.read<String>('manifest_json'));
    validateBeginSnapshotReply(
      BeginSnapshotRequest(manifest.at.serverEpoch),
      manifest,
      nowUtc,
    );
    if (stage.read<int>('next_page') != manifest.pageCount ||
        stage.read<int>('record_count') != manifest.recordCount ||
        (state.readNullable<String>('server_epoch') ==
                manifest.at.serverEpoch &&
            manifest.at.revision < state.read<int>('cursor'))) {
      throw StateError('Incomplete or stale snapshot.');
    }
    final profile = await db
        .customSelect('SELECT * FROM profile_metadata')
        .getSingle();
    final oldEpoch = state.readNullable<String>('server_epoch');
    final needsRecovery =
        state.read<int>('requires_recovery') != 0 ||
        (oldEpoch != null && oldEpoch != manifest.at.serverEpoch) ||
        (manifest.deviceHighWaters[profile.read<String>('device_epoch')] ??
                0) >=
            profile.read<int>('next_sequence');
    // Captures intentionally retain originals beside closure facts. A closure
    // must match the candidate version when both payloads are present.
    if ((await db
            .customSelect(
              "SELECT 1 FROM account_snapshot_records a JOIN account_snapshot_records b ON a.record_key=b.record_key WHERE a.record_kind='recovery' AND b.record_kind='resolutions' AND json_extract(a.record_json,'\$.revision') != json_extract(b.record_json,'\$.expected_conflict_revision') LIMIT 1",
            )
            .get())
        .isNotEmpty) {
      throw StateError('Snapshot closure version mismatch.');
    }
    // Preserve original payload proofs and recovery archives independently of
    // the current snapshot. Closing/compacting a candidate is not permission
    // to destroy an original already retained on this device.
    final originals = await db
        .customSelect(
          "SELECT * FROM account_snapshot_records WHERE record_kind IN ('recovery','history')",
        )
        .get();
    for (final row in originals) {
      final value = jsonDecode(row.read<String>('record_json')) as Map;
      if (value['operation'] != null) {
        final operation = decodeAccountOperation(value['operation']);
        if (operation.sequence >
            (manifest.deviceHighWaters[operation.deviceEpoch] ?? 0)) {
          throw StateError('Snapshot original exceeds its device watermark.');
        }
        await _retainOriginal(operation);
        if (row.read<String>('record_kind') == 'recovery') {
          final previous = await db
              .customSelect(
                'SELECT * FROM account_recovery_archive WHERE candidate_id=?',
                variables: [Variable(value['id'] as String)],
              )
              .get();
          if (previous.isEmpty) {
            await db.customStatement(
              'INSERT INTO account_recovery_archive VALUES(?,?,?,?)',
              [
                value['id'],
                operation.operationId,
                value['group'],
                row.read<String>('record_json'),
              ],
            );
          } else if (previous.single.read<String>('operation_id') !=
                  operation.operationId ||
              previous.single.read<String>('field_group') != value['group']) {
            throw StateError('Recovery original identity mismatch.');
          }
        }
      }
    }
    await db.customStatement('DELETE FROM account_records');
    await db.customStatement(
      'INSERT INTO account_records SELECT * FROM account_snapshot_records',
    );
    await db.customStatement(
      'UPDATE account_state SET server_epoch=?,cursor=?,device_high_waters_json=?,requires_recovery=? WHERE singleton=1',
      [
        manifest.at.serverEpoch,
        manifest.at.revision,
        _json(manifest.deviceHighWaters),
        needsRecovery ? 1 : 0,
      ],
    );
    // Watermarks prove consumption only, never per-field acceptance. Preserve
    // all originals and receipts and require explicit reconciliation.
    for (final watermark in manifest.deviceHighWaters.entries) {
      await db.customStatement(
        "UPDATE account_operations SET transport_state='reconcile' WHERE device_epoch=? AND sequence<=? AND receipt_json IS NULL",
        [watermark.key, watermark.value],
      );
    }
    await _clearStaging();
  });

  Future<AccountProjection> projection(SyncEntity entity) =>
      db.transaction(() => _projection(entity));

  Future<AccountProjection> _projection(
    SyncEntity entity, {
    int? beforeSequence,
  }) async {
    final state = await _guard();
    final rows = await db
        .customSelect(
          "SELECT record_json FROM account_records WHERE record_kind='records' AND record_key=?",
          variables: [Variable(entity.identity)],
        )
        .get();
    ShadowRecord? shadow;
    if (rows.isNotEmpty) {
      shadow = decodeAccountShadow(
        jsonDecode(rows.single.read<String>('record_json')),
      );
    }
    final operations = await db
        .customSelect(
          'SELECT * FROM account_operations WHERE entity_key=? '
          '${beforeSequence == null ? '' : 'AND sequence < ? '}ORDER BY sequence',
          variables: [
            Variable(entity.identity),
            if (beforeSequence != null) Variable(beforeSequence),
          ],
        )
        .get();
    final proposals = <AccountProposal>[];
    for (final row in operations) {
      final operation = decodeAccountOperation(
        jsonDecode(row.read<String>('envelope_json')),
      );
      final outcomes = await db
          .customSelect(
            'SELECT * FROM account_field_outcomes WHERE operation_id=?',
            variables: [Variable(operation.operationId)],
          )
          .get();
      final closed = await db
          .customSelect(
            "SELECT a.field_group FROM account_recovery_archive a JOIN account_records c ON c.record_kind='resolutions' AND c.record_key=a.candidate_id WHERE a.operation_id=? UNION SELECT f.field_group FROM account_field_outcomes f JOIN account_records c ON c.record_kind='resolutions' AND c.record_key=f.recovery_id WHERE f.operation_id=?",
            variables: [
              Variable(operation.operationId),
              Variable(operation.operationId),
            ],
          )
          .get();
      proposals.add(
        AccountProposal(
          operation,
          row.read<String>('transport_state'),
          state.read<int>('requires_recovery') != 0 ||
              row.read<String>('origin_server_epoch') !=
                  state.readNullable<String>('server_epoch') ||
              row.read<String>('transport_state') == 'reconcile',
          Map.unmodifiable({
            for (final outcome in outcomes)
              outcome.read<String>('field_group'): outcome.read<String>(
                'disposition',
              ),
          }),
          Set.unmodifiable(closed.map((r) => r.read<String>('field_group'))),
          Map.unmodifiable({
            for (final outcome in outcomes)
              if (outcome.readNullable<String>('accepted_json')
                  case final String json)
                outcome.read<String>('field_group'): AcceptedField(
                  (jsonDecode(json) as Map)['revision'] as int,
                  (jsonDecode(json) as Map)['value'],
                ),
          }),
          {},
        ),
      );
    }
    final recovery = await db
        .customSelect(
          "SELECT r.record_json FROM account_records r WHERE r.record_kind='recovery' AND json_extract(r.record_json,'\$.operation.entity')=? AND NOT EXISTS (SELECT 1 FROM account_records c WHERE c.record_kind='resolutions' AND c.record_key=r.record_key)",
          variables: [Variable(entity.identity)],
        )
        .get();
    final unresolved = recovery
        .map(
          (r) =>
              decodeAccountRecovery(jsonDecode(r.read<String>('record_json'))),
        )
        .toList();
    final values = <String, Object?>{
      for (final entry
          in shadow?.fields.entries ?? <MapEntry<String, AcceptedField>>[])
        entry.key: entry.value.value,
    };
    final sources = <String, String>{};
    final pending = <String>{};
    final comparisonFields = <String, AcceptedField>{...?shadow?.fields};
    // Ephemeral causal identities, never serialized or presented as server
    // revisions. Equivalent operations share an identity; applied writes replace
    // it. Keep each operation's identity so either equivalent predecessor binds.
    final fieldVersions = <String, String>{
      for (final entry in comparisonFields.entries)
        entry.key: 'accepted:${entry.value.revision}',
    };
    final operationVersions = <String, Map<String, String>>{};
    final seen = <String, AccountProposal>{};
    for (final proposal in proposals) {
      final operation = proposal.operation;
      final completeCreate =
          operation.command == 'task.create' ||
          operation.command == 'milestone.create';
      final wholeDecision = await _commandDecision(operation, shadow, values);
      final decisions = <String, FieldDisposition>{};
      for (final entry in operation.patches.entries) {
        final group = entry.key;
        final patch = entry.value;
        if (proposal.closedGroups.contains(group)) continue;
        FieldDisposition decision;
        final candidate = unresolved.where(
          (r) =>
              r.operation.operationId == operation.operationId &&
              r.group == group,
        );
        final outcome = proposal.outcomes[group];
        final accepted = proposal.acceptedFields[group];
        if (proposal.needsReconciliation) {
          decision = FieldDisposition.recovery;
        } else if (candidate.isNotEmpty) {
          decision = candidate.single.disposition;
        } else if (outcome != null &&
            outcome != 'applied' &&
            outcome != 'equivalent') {
          decision = FieldDisposition.values.byName(outcome);
        } else if (accepted != null) {
          // Keep acknowledged values visible until pull reaches their revision,
          // but never overlay them over a later downloaded accepted value.
          if (accepted.revision > state.read<int>('cursor') &&
              accepted.revision > (shadow?.fields[group]?.revision ?? 0)) {
            values[group] = accepted.value;
            sources[group] = operation.operationId;
            pending.remove(group);
            comparisonFields[group] = accepted;
            fieldVersions[group] = 'accepted:${accepted.revision}';
          }
          decision = FieldDisposition.values.byName(outcome!);
          proposal._projectedOutcomes[group] = decision;
          (operationVersions[operation.operationId] ??= {})[group] =
              'accepted:${accepted.revision}';
          seen[operation.operationId] = proposal;
          continue;
        } else if (wholeDecision != null) {
          decision = wholeDecision;
        } else if ((!completeCreate && operation.command.endsWith('.create')) ||
            operation.command == 'task.restore') {
          // Complete creates and exact-deletion restore need command-level
          // validation; individual field equivalence cannot authorize them.
          decision = FieldDisposition.held;
        } else if (values['existence'] == false &&
            operation.command != 'task.delete' &&
            operation.command != 'milestone.delete' &&
            operation.command != 'tag.delete' &&
            operation.command != 'view.delete') {
          decision = FieldDisposition.recovery;
        } else if (patch.base case PredecessorBase base) {
          final predecessor = seen[base.operationId];
          if (predecessor == null ||
              predecessor.operation.sequence != base.sequence ||
              predecessor.operation.deviceEpoch != operation.deviceEpoch ||
              !predecessor.operation.patches.containsKey(group) ||
              predecessor.closedGroups.contains(group)) {
            decision = FieldDisposition.held;
          } else if (!predecessor.needsReconciliation &&
              const [
                FieldDisposition.conflict,
                FieldDisposition.held,
              ].contains(predecessor.projectedOutcomes[group])) {
            decision = FieldDisposition.held;
          } else if (operationVersions[base.operationId]?[group]
              case final String version) {
            final predecessorValue = predecessor.acceptedFields[group] != null
                ? predecessor.acceptedFields[group]!.value
                : predecessor.operation.patches[group]!.value;
            if (_json(base.value) != _json(predecessorValue)) {
              decision = FieldDisposition.recovery;
            } else if (version == fieldVersions[group]) {
              decision = FieldDisposition.applied;
            } else {
              decision =
                  values.containsKey(group) &&
                      _json(patch.value) == _json(values[group])
                  ? FieldDisposition.equivalent
                  : FieldDisposition.conflict;
            }
          } else {
            decision = compareField(
              patch,
              comparisonFields[group],
              acceptedPredecessor: predecessor.acceptedFields[group],
              predecessorNeedsRecovery:
                  predecessor.needsReconciliation ||
                  ![
                    FieldDisposition.applied,
                    FieldDisposition.equivalent,
                  ].contains(predecessor.projectedOutcomes[group]),
            );
            if (pending.contains(group) &&
                (decision == FieldDisposition.applied ||
                    decision == FieldDisposition.equivalent)) {
              decision = _json(patch.value) == _json(values[group])
                  ? FieldDisposition.equivalent
                  : FieldDisposition.conflict;
            }
          }
        } else {
          decision = compareField(patch, comparisonFields[group]);
          if (pending.contains(group)) {
            decision = _json(patch.value) == _json(values[group])
                ? FieldDisposition.equivalent
                : FieldDisposition.conflict;
          }
        }
        // Bind a missing milestone's causal chain first: held descendants stay
        // held, but neither an absent base nor a successful field comparison can
        // manufacture a child that its complete create has not projected.
        if (operation.entity.kind == SyncEntityKind.milestone &&
            !completeCreate &&
            shadow == null &&
            values.isEmpty &&
            (decision == FieldDisposition.applied ||
                decision == FieldDisposition.equivalent)) {
          decision = FieldDisposition.recovery;
        }
        decisions[group] = decision;
      }
      // A create is one command: never project a title or existence independently
      // after any of its groups failed or closed. Receipts remain authoritative.
      final failedCreate =
          completeCreate &&
          (proposal.closedGroups.isNotEmpty ||
              decisions.values.any(
                (d) =>
                    d != FieldDisposition.applied &&
                    d != FieldDisposition.equivalent,
              ));
      for (final entry in decisions.entries) {
        final group = entry.key;
        final decision =
            failedCreate &&
                (entry.value == FieldDisposition.applied ||
                    entry.value == FieldDisposition.equivalent)
            ? FieldDisposition.held
            : entry.value;
        proposal._projectedOutcomes[group] = decision;
        if (decision == FieldDisposition.applied ||
            decision == FieldDisposition.equivalent) {
          values[group] = operation.patches[group]!.value;
          sources[group] = operation.operationId;
          // Equivalence against accepted state preserves its revision. Keep an
          // existing pending marker, but do not invent one for a no-op.
          if (decision == FieldDisposition.applied) {
            pending.add(group);
            fieldVersions[group] = 'pending:${operation.operationId}';
          }
          (operationVersions[operation.operationId] ??= {})[group] =
              fieldVersions[group]!;
        }
      }
      seen[operation.operationId] = proposal;
    }
    var visible = values['existence'] == true;
    if (entity.kind == SyncEntityKind.membership) {
      visible =
          values['membership'] == true &&
          (await _projection(
            SyncEntity(SyncEntityKind.task, [entity.key[0]]),
            beforeSequence: beforeSequence,
          )).visible &&
          (await _projection(
            SyncEntity(SyncEntityKind.tag, [entity.key[1]]),
            beforeSequence: beforeSequence,
          )).visible;
    } else if (entity.kind == SyncEntityKind.milestone) {
      final parent = values['parent'];
      visible =
          visible &&
          parent is String &&
          (await _projection(
            SyncEntity(SyncEntityKind.task, [parent]),
            beforeSequence: beforeSequence,
          )).visible;
    } else if (entity.kind == SyncEntityKind.preference) {
      final view = values['value'];
      visible =
          view == null ||
          (view is String &&
              (await _projection(
                SyncEntity(SyncEntityKind.view, [view]),
                beforeSequence: beforeSequence,
              )).visible);
    }
    return AccountProjection(
      shadow,
      List.unmodifiable(proposals),
      List.unmodifiable(unresolved),
      Map.unmodifiable(values),
      Map.unmodifiable(sources),
      visible,
    );
  }

  Future<FieldDisposition?> _commandDecision(
    AccountOperation operation,
    ShadowRecord? shadow,
    Map<String, Object?> values,
  ) async {
    final supported = const {
      'task.create',
      'task.edit',
      'task.status',
      'task.delete',
      'milestone.create',
      'milestone.edit',
      'milestone.delete',
    }.contains(operation.command);
    if (supported && !validLocalAccountCommand(operation)) {
      return FieldDisposition.recovery;
    }
    if (!supported) {
      return operation.dependencies.isEmpty ? null : FieldDisposition.held;
    }
    if (operation.command.endsWith('.create') &&
        (shadow != null || values.isNotEmpty)) {
      return values['existence'] == false
          ? FieldDisposition.recovery
          : FieldDisposition.conflict;
    }
    if (!operation.command.endsWith('.create') &&
        shadow == null &&
        values.isEmpty) {
      return operation.entity.kind == SyncEntityKind.milestone
          ? null
          : FieldDisposition.recovery;
    }
    if (operation.entity.kind != SyncEntityKind.milestone) return null;
    // Independent child deletion survives a hidden/deleted parent.
    if (operation.command == 'milestone.delete') return null;
    final parentId = operation.patches['parent']?.value ?? values['parent'];
    if (parentId is! String) return FieldDisposition.recovery;
    final parent = await _projection(
      SyncEntity(SyncEntityKind.task, [parentId]),
      beforeSequence: operation.sequence,
    );
    if (operation.dependencies.isEmpty) {
      // Unproven pending parents cannot authorize a child. The caller must name
      // their exact earlier create/restore operation, not just its UUID.
      return parent.visible &&
              (parent.accepted?.fields['existence']?.value == true ||
                  (operation.command != 'milestone.create' &&
                      values['existence'] == true))
          ? null
          : FieldDisposition.recovery;
    }
    final dep = operation.dependencies.single;
    final matches = parent.proposals.where(
      (p) => p.operation.operationId == dep.operationId,
    );
    if (matches.length != 1) return FieldDisposition.recovery;
    final predecessor = matches.single;
    if (predecessor.operation.deviceEpoch != operation.deviceEpoch ||
        predecessor.operation.sequence != dep.sequence ||
        predecessor.operation.sequence >= operation.sequence ||
        predecessor.operation.entity.identity != dep.entity.identity ||
        predecessor.operation.patches['existence']?.value != true ||
        predecessor.closedGroups.contains('existence') ||
        predecessor.needsReconciliation) {
      return FieldDisposition.recovery;
    }
    final decision = predecessor.projectedOutcomes['existence'];
    if (decision == FieldDisposition.conflict ||
        decision == FieldDisposition.held) {
      return FieldDisposition.held;
    }
    if (!parent.visible ||
        (decision != FieldDisposition.applied &&
            decision != FieldDisposition.equivalent)) {
      return FieldDisposition.recovery;
    }
    final accepted = predecessor.acceptedFields['existence'];
    if (accepted?.value == true ||
        parent.pendingSources['existence'] == dep.operationId) {
      return null;
    }
    return FieldDisposition.held;
  }

  Future<void> _clearStaging() async {
    await db.customStatement('DELETE FROM account_snapshot_records');
    await db.customStatement('DELETE FROM account_snapshot_pages');
    await db.customStatement('DELETE FROM account_snapshot');
  }

  Future<void> _retainOriginal(AccountOperation operation) async {
    await _checkDecisionIdentity(
      operation.operationId,
      operation.deviceEpoch,
      operation.sequence,
    );
    final history = await db
        .customSelect(
          "SELECT record_json FROM account_records WHERE record_kind='history' AND record_key=?",
          variables: [Variable(operation.operationId)],
        )
        .get();
    if (history.isNotEmpty) {
      _checkHistoryOriginal(
        jsonDecode(history.single.read<String>('record_json')) as Map,
        operation,
      );
    }
    final rows = await db
        .customSelect(
          'SELECT payload_identity FROM account_originals WHERE operation_id=?',
          variables: [Variable(operation.operationId)],
        )
        .get();
    if (rows.isNotEmpty) {
      if (rows.single.read<String>('payload_identity') !=
          operation.payloadIdentity) {
        throw StateError('Original payload identity mismatch.');
      }
      return;
    }
    await db.customStatement('INSERT INTO account_originals VALUES(?,?,?,?)', [
      operation.operationId,
      operation.deviceEpoch,
      operation.sequence,
      operation.payloadIdentity,
    ]);
  }

  static void _checkHistoryOriginal(Map history, AccountOperation operation) {
    if (operation.entity.kind != SyncEntityKind.task ||
        operation.entity.key.single != history['task_id'] ||
        !['task.create', 'task.status'].contains(operation.command) ||
        !operation.patches.containsKey('status_group') ||
        _json(operation.patches['status_group']!.value) !=
            _json((history['status'] as Map)['value'])) {
      throw StateError('History original identity mismatch.');
    }
  }

  /// Closure decisions have no original payload to put in account_originals,
  /// but their operation/device/sequence proof still cannot be reassigned.
  Future<void> _checkDecisionIdentity(
    String operationId,
    String deviceEpoch,
    int sequence,
  ) async {
    final identities = await db
        .customSelect(
          'SELECT operation_id,device_epoch,sequence FROM account_originals WHERE operation_id=? OR (device_epoch=? AND sequence=?) '
          "UNION ALL SELECT json_extract(record_json,'\$.operation_id'),json_extract(record_json,'\$.device_epoch'),json_extract(record_json,'\$.sequence') FROM account_records WHERE record_kind='resolutions' AND (json_extract(record_json,'\$.operation_id')=? OR (json_extract(record_json,'\$.device_epoch')=? AND json_extract(record_json,'\$.sequence')=?))",
          variables: [
            Variable(operationId),
            Variable(deviceEpoch),
            Variable(sequence),
            Variable(operationId),
            Variable(deviceEpoch),
            Variable(sequence),
          ],
        )
        .get();
    if (identities.any(
      (row) =>
          row.read<String>('operation_id') != operationId ||
          row.read<String>('device_epoch') != deviceEpoch ||
          row.read<int>('sequence') != sequence,
    )) {
      throw StateError('Downloaded operation identity mismatch.');
    }
  }

  static String _json(Object? value) =>
      canonicalSyncJson(value, maxDepth: maxSyncReplyDepth);
  static SnapshotManifest _manifest(String json) =>
      (recoveryBeginSnapshotCodec.decodeReply(
        jsonDecode(json),
      ) as SyncSuccess<SnapshotManifest>).value;

  static List<List<Object?>> _records(Map<String, Object?> page) => [
    for (final kind in ['records', 'recovery', 'history', 'resolutions'])
      for (final raw in page[kind] as List)
        [
          kind,
          switch (kind) {
            'records' => _json((raw as Map)['entity']),
            'recovery' => (raw as Map)['id'],
            'history' => (raw as Map)['operation_id'],
            _ => (raw as Map)['conflict_id'],
          },
          _json(raw),
        ],
  ];
}
