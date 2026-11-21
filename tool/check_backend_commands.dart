import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/data/local/account_bulk.dart';
import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart' hide AccountOperation;
import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';

Map<String, Object?> reply(Object? value) => {
  'protocol_version': 2,
  'status': 'success',
  'result': value,
};

/// Synthetic owner-correlated integration only; credentials stay in Python.
Future<void> main(List<String> args) async {
  if (args.length != 4 || !{'prepare', 'undo', 'verify'}.contains(args[0])) {
    throw ArgumentError(
      'Expected prepare|undo|verify fixture database output.',
    );
  }
  final fixture = jsonDecode(File(args[1]).readAsStringSync()) as Map;
  final owner = fixture['owner'] as String;
  final db = AppDatabase.file(File(args[2]));
  try {
    await db.initializeProfile('account-$owner');
    if (args[0] == 'prepare') {
      await db.customStatement('UPDATE profile_metadata SET device_epoch=?', [
        fixture['device'],
      ]);
    }
    final store = await AccountStore.open(db, owner);
    final task = SyncEntity(SyncEntityKind.task, [fixture['task'] as String]);
    final child = SyncEntity(SyncEntityKind.milestone, [
      fixture['child'] as String,
    ]);
    final scenario = fixture['scenario'] as String? ?? 'chain';
    final bulk = scenario.startsWith('bulk-');
    if (args[0] != 'verify') {
      final now = DateTime.parse(fixture['checked_at_utc'] as String);
      if (args[0] == 'prepare') {
        final m = (recoveryBeginSnapshotCodec.decodeReply(
          reply(fixture['manifest']),
        ) as SyncSuccess<SnapshotManifest>).value;
        await store.beginSnapshot(m, now);
        for (final p in fixture['pages'] as List) {
          await store.stagePage(
            (recoverySnapshotPageCodec.decodeReply(
              reply(p),
            ) as SyncSuccess<RecoverySnapshotPage>).value,
            now,
          );
        }
        await store.installSnapshot(now);
      }
      final ids = (fixture['operations'] as List).cast<String>();
      final ops = <AccountOperation>[];
      Future<AccountOperation> commit(
        String command,
        SyncEntity entity,
        Map<String, FieldPatch> patches, [
        List<OperationDependency> deps = const [],
      ]) async {
        final op = await store.commitCommand(
          operationId: ids[ops.length],
          entity: entity,
          command: command,
          patches: patches,
          dependencies: deps,
          occurredAtUtc: now,
        );
        ops.add(op);
        return op;
      }

      FieldPatch absent(Object? value) => FieldPatch(const AbsentBase(), value);
      FieldPatch predecessor(
        AccountOperation op,
        String group,
        Object? value,
      ) => FieldPatch(
        PredecessorBase(op.operationId, op.sequence, op.patches[group]!.value),
        value,
      );
      Future<AccountOperation> commitOriginal(Object? raw) async {
        final op = decodeAccountOperation(raw);
        final committed = await store.commitCommand(
          operationId: op.operationId,
          entity: op.entity,
          command: op.command,
          patches: op.patches,
          dependencies: op.dependencies,
          restore: op.restore,
          occurredAtUtc: DateTime.fromMillisecondsSinceEpoch(
            op.provenance['occurred_at'] as int,
            isUtc: true,
          ),
        );
        if (committed.payloadIdentity != op.payloadIdentity) {
          throw StateError(
            'SQLite command did not preserve the proposed original.',
          );
        }
        return committed;
      }

      if (fixture['seed'] case final Map seed) {
        final request = applyCodec.decodeRequest(seed['request']);
        if (!bulk) {
          for (final op in request.operations) {
            await commitOriginal(op.toJson());
          }
        }
        await store.retainApplyResult(
          request,
          (applyCodec.decodeReply(
            seed['receipt'],
          ) as SyncSuccess<ApplyResult>).value,
        );
        for (final raw in seed['downloads'] as List) {
          await store.applyPull(
            recoveryPullCodec.decodeRequest(raw['request']),
            (recoveryPullCodec.decodeReply(
              raw['reply'],
            ) as SyncSuccess<RecoveryPullResult>).value,
          );
        }
      }
      if (bulk) {
        final targets = <BulkTaskTarget>[];
        if (args[0] == 'undo') {
          final seed = applyCodec.decodeRequest(
            (fixture['seed'] as Map)['request'],
          );
          for (final original in seed.operations) {
            final inverse = await store.undoTarget(original);
            if (inverse != null) targets.add(inverse);
          }
        } else {
          final deleting = scenario == 'bulk-delete';
          for (final taskId in (fixture['selection'] as List).cast<String>()) {
            final selected = await store.projection(
              SyncEntity(SyncEntityKind.task, [taskId]),
            );
            final field = selected
                .accepted!
                .fields[deleting ? 'existence' : 'status_group']!;
            final base = ObservedBase(field.revision, field.value);
            targets.add(
              deleting
                  ? BulkTaskTarget.delete(taskId, base)
                  : BulkTaskTarget.status(taskId, base, {
                      'status': 'completed',
                      'completed_at': 100,
                    }),
            );
          }
        }
        final batchId = args[0] == 'prepare' ? ids.first : ids[1];
        ops.addAll(
          await store.commitBulk(
            batchId: batchId,
            targets: targets,
            occurredAtUtc: now,
          ),
        );
        final retry = await store.commitBulk(
          batchId: batchId,
          targets: targets,
          occurredAtUtc: now,
        );
        if (jsonEncode(retry.map((op) => op.toJson()).toList()) !=
            jsonEncode(ops.map((op) => op.toJson()).toList())) {
          throw StateError('Bulk retry changed an original operation.');
        }
      } else if (fixture['proposals'] case final List proposals) {
        for (final raw in proposals) {
          ops.add(await commitOriginal(raw));
        }
        if (scenario == 'restore-stale' || scenario == 'restore-expired') {
          for (final op in ops) {
            final local = await store.projection(op.entity);
            if (!local.visible ||
                local.proposals.last.projectedOutcomes.values.any(
                  (d) => d != FieldDisposition.applied,
                )) {
              throw StateError(
                'Exact restore and dependent child must preview before rejection.',
              );
            }
          }
        }
      } else {
        final creation = await commit('task.create', task, {
          'title': absent('SQLite task'),
          'priority': absent('none'),
          'existence': absent(true),
          'status_group': absent({'status': 'todo', 'completed_at': null}),
        });
        final step = await commit(
          'milestone.create',
          child,
          {
            'title': absent('SQLite step'),
            'parent': absent(task.key.single),
            'completion': absent(null),
            'existence': absent(true),
          },
          [
            OperationDependency(
              entity: task,
              operationId: creation.operationId,
              sequence: creation.sequence,
            ),
          ],
        );
        await commit('task.status', task, {
          'status_group': predecessor(creation, 'status_group', {
            'status': 'completed',
            'completed_at': 100,
          }),
        });
        await commit('milestone.edit', child, {
          'title': predecessor(step, 'title', 'Edited step'),
        });
        await commit('task.edit', task, {
          'title': predecessor(creation, 'title', 'Edited task'),
        });
        await commit('task.delete', task, {
          'existence': predecessor(creation, 'existence', false),
        });
        await commit('milestone.delete', child, {
          'existence': predecessor(step, 'existence', false),
        });
        final local = await store.projection(child);
        if (local.visible ||
            local.values['existence'] != false ||
            local.values['title'] != 'Edited step') {
          throw StateError('Local dependency/deletion projection mismatch.');
        }
      }
      File(args[3]).writeAsStringSync(
        jsonEncode(
          ApplyRequest(
            cursor: (await store.checkpoint())!,
            operations: ops,
          ).toJson(),
        ),
      );
      stdout.writeln(
        'PASS: ${ops.length} $scenario commands committed in SQLite with explicit bases/dependency',
      );
    } else {
      final request = applyCodec.decodeRequest(fixture['request']);
      final originals = await db
          .customSelect(
            'SELECT envelope_json FROM account_operations ORDER BY sequence',
          )
          .get();
      final bytes = originals
          .map((r) => r.read<String>('envelope_json'))
          .toList();
      final result = (applyCodec.decodeReply(
        fixture['receipt'],
      ) as SyncSuccess<ApplyResult>).value;
      Future<void> applyPage(Map raw) => store.applyPull(
        recoveryPullCodec.decodeRequest(raw['request']),
        (recoveryPullCodec.decodeReply(
          raw['reply'],
        ) as SyncSuccess<RecoveryPullResult>).value,
      );
      if (fixture['intervening_pull'] case final Map raw) {
        await applyPage(raw);
      }
      Future<void> checkOrder() async {
        if (fixture['visible_order'] case final List expectedOrder) {
          if (jsonEncode(await store.visibleMilestoneOrder(task)) !=
              jsonEncode(expectedOrder)) {
            throw StateError('Local visible order disagrees with PostgreSQL.');
          }
        }
      }

      Future<void> checkProjectedRecords() async {
        final restore = scenario.startsWith('restore-');
        if (!restore &&
            !bulk &&
            !scenario.startsWith('tags-') &&
            !scenario.startsWith('views-')) {
          return;
        }
        final shadows = <String, ShadowRecord>{};
        for (final p in fixture['terminal_pages'] as List) {
          for (final raw in p['records'] as List) {
            final shadow = decodeAccountShadow(raw);
            shadows[shadow.entity.identity] = shadow;
          }
        }
        final entities = <String, SyncEntity>{
          if (restore || bulk)
            for (final shadow in shadows.values)
              shadow.entity.identity: shadow.entity,
          if (scenario.startsWith('views-'))
            for (final record in shadows.values)
              if (record.entity.kind == SyncEntityKind.preference ||
                  record.entity.kind == SyncEntityKind.view)
                record.entity.identity: record.entity,
          for (final op in request.operations)
            if (restore ||
                op.entity.kind == SyncEntityKind.tag ||
                op.entity.kind == SyncEntityKind.membership ||
                op.entity.kind == SyncEntityKind.preference ||
                op.entity.kind == SyncEntityKind.view)
              op.entity.identity: op.entity,
        };
        for (final entity in entities.values) {
          final expected = shadows[entity.identity];
          final values = {
            for (final entry
                in expected?.fields.entries ??
                    <MapEntry<String, AcceptedField>>[])
              entry.key: entry.value.value,
          };
          final local = await store.projection(entity);
          var visible = values['existence'] == true;
          if (entity.kind == SyncEntityKind.milestone && visible) {
            visible =
                shadows[SyncEntity(SyncEntityKind.task, [
                      values['parent'] as String,
                    ]).identity]
                    ?.fields['existence']
                    ?.value ==
                true;
          }
          if (entity.kind == SyncEntityKind.membership) {
            visible =
                values['membership'] == true &&
                shadows[SyncEntity(SyncEntityKind.task, [
                          entity.key[0],
                        ]).identity]
                        ?.fields['existence']
                        ?.value ==
                    true &&
                shadows[SyncEntity(SyncEntityKind.tag, [
                          entity.key[1],
                        ]).identity]
                        ?.fields['existence']
                        ?.value ==
                    true;
          }
          if (entity.kind == SyncEntityKind.preference) {
            final selected = values['value'];
            visible =
                selected == null ||
                shadows[SyncEntity(SyncEntityKind.view, [
                          selected as String,
                        ]).identity]
                        ?.fields['existence']
                        ?.value ==
                    true;
          }
          if (canonicalSyncJson(local.values) != canonicalSyncJson(values) ||
              local.visible != visible) {
            throw StateError(
              'Local $scenario ${entity.kind.name} values/visibility disagree with PostgreSQL.',
            );
          }
        }
      }

      await checkOrder();
      // The deletion ledger's trusted clock is only available to PostgreSQL.
      // prepare checked the provisional preview; the rejection below must undo it.
      if (scenario != 'restore-expired') await checkProjectedRecords();
      if (scenario != 'chain' && scenario != 'restore-expired') {
        // Compare the pre-acknowledgement SQLite preview to actual PostgreSQL
        // outcomes, before any receipt/download can conceal a preview defect.
        for (var i = 0; i < request.operations.length; i++) {
          final op = request.operations[i];
          final projection = await store.projection(op.entity);
          final proposal = projection.proposals.singleWhere(
            (p) => p.operation.operationId == op.operationId,
          );
          final receipt = result.results[i] as OperationReceipt;
          final expectedOutcomes = {
            if (receipt.disposition == ReceiptDisposition.rejected)
              for (final group in op.patches.keys)
                group: FieldDisposition.recovery,
            for (final field in receipt.fields) field.group: field.disposition,
          };
          for (final field in expectedOutcomes.entries) {
            if (proposal.projectedOutcomes[field.key] != field.value) {
              throw StateError(
                'Local $scenario operation $i ${field.key}: '
                '${proposal.projectedOutcomes[field.key]} != ${field.value}.',
              );
            }
          }
        }
      }
      await store.retainApplyResult(request, result);
      await store.retainApplyResult(request, result);
      await checkOrder();
      await checkProjectedRecords();
      for (final raw in fixture['downloads'] as List) {
        await applyPage(raw as Map);
        if (scenario.startsWith('views-') ||
            scenario.startsWith('restore-') ||
            bulk) {
          await checkProjectedRecords();
          await checkOrder();
        }
      }
      final projected = await store.projection(child);
      await checkOrder();
      await checkProjectedRecords();
      if (scenario == 'chain' &&
          (projected.visible ||
              projected.values['existence'] != false ||
              projected.values['title'] != 'Edited step')) {
        throw StateError('Accepted projection mismatch.');
      }
      final current = await db
          .customSelect(
            'SELECT envelope_json FROM account_operations ORDER BY sequence',
          )
          .get();
      if (jsonEncode(
            current.map((r) => r.read<String>('envelope_json')).toList(),
          ) !=
          jsonEncode(bytes)) {
        throw StateError('Original bytes changed.');
      }
      final expected = <String>[];
      for (final p in fixture['terminal_pages'] as List) {
        for (final kind in ['records', 'recovery', 'history', 'resolutions']) {
          for (final record in p[kind] as List) {
            expected.add(
              '$kind:${canonicalSyncJson(record, maxDepth: maxSyncReplyDepth)}',
            );
          }
        }
      }
      final actual =
          (await db.customSelect('SELECT * FROM account_records').get())
              .map(
                (r) =>
                    '${r.read<String>('record_kind')}:${r.read<String>('record_json')}',
              )
              .toList()
            ..sort();
      expected.sort();
      if (jsonEncode(actual) != jsonEncode(expected)) {
        throw StateError('Pull differs from authoritative snapshot.');
      }
      final history = await db
          .customSelect('SELECT * FROM account_command_history')
          .get();
      final seedCount = fixture['seed'] is Map
          ? applyCodec
                .decodeRequest((fixture['seed'] as Map)['request'])
                .operations
                .length
          : 0;
      if (history.length != request.operations.length + seedCount) {
        throw StateError('Local history mismatch.');
      }
      stdout.writeln(
        'PASS: ${request.operations.length} $scenario real receipts, duplicate acknowledgement, original bytes and snapshot-equivalent pull',
      );
    }
  } finally {
    await db.close();
  }
}
