import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/account_sync.dart';
import '../../domain/account_sync_codec.dart';
import '../../domain/account_sync_rpc.dart';
import 'database.dart' hide AccountOperation;

/// A read model for recovery/projection work, not a native task or an upload.
/// Original operations remain separate from accepted state; no implicit rebase.
final class AccountProjection {
  AccountProjection(this.accepted, this.proposals, this.unresolvedRecovery);
  final ShadowRecord? accepted;
  final List<AccountProposal> proposals;
  final List<RecoveryRecord> unresolvedRecovery;
}

final class AccountProposal {
  AccountProposal(
    this.operation,
    this.transportState,
    this.needsReconciliation,
    this.outcomes,
    this.closedGroups,
  );
  final AccountOperation operation;
  final String transportState;
  final bool needsReconciliation;
  final Map<String, String> outcomes;
  final Set<String> closedGroups;
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

  /// Retains an already constructed, explicit account envelope. This is not a
  /// guest journal translator. Future commands must call within their local
  /// entity/history/dirty transaction; this method nests in that transaction.
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

  Future<AccountProjection> projection(
    SyncEntity entity,
  ) => db.transaction(() async {
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
          'SELECT * FROM account_operations WHERE entity_key=? ORDER BY sequence',
          variables: [Variable(entity.identity)],
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
        ),
      );
    }
    final recovery = await db
        .customSelect(
          "SELECT r.record_json FROM account_records r WHERE r.record_kind='recovery' AND json_extract(r.record_json,'\$.operation.entity')=? AND NOT EXISTS (SELECT 1 FROM account_records c WHERE c.record_kind='resolutions' AND c.record_key=r.record_key)",
          variables: [Variable(entity.identity)],
        )
        .get();
    return AccountProjection(
      shadow,
      List.unmodifiable(proposals),
      List.unmodifiable(
        recovery.map(
          (r) =>
              decodeAccountRecovery(jsonDecode(r.read<String>('record_json'))),
        ),
      ),
    );
  });

  Future<void> _clearStaging() async {
    await db.customStatement('DELETE FROM account_snapshot_records');
    await db.customStatement('DELETE FROM account_snapshot_pages');
    await db.customStatement('DELETE FROM account_snapshot');
  }

  Future<void> _retainOriginal(AccountOperation operation) async {
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
