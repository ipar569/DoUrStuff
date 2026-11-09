import 'dart:convert';
import 'dart:io';

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
  if (args.length != 4 || !{'prepare', 'verify'}.contains(args[0])) {
    throw ArgumentError('Expected prepare|verify fixture database output.');
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
    if (args[0] == 'prepare') {
      final now = DateTime.parse(fixture['checked_at_utc'] as String);
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
      File(args[3]).writeAsStringSync(
        jsonEncode(ApplyRequest(cursor: m.at, operations: ops).toJson()),
      );
      stdout.writeln(
        'PASS: seven commands committed in SQLite with explicit bases/dependency',
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
      await store.retainApplyResult(request, result);
      await store.retainApplyResult(request, result);
      for (final raw in fixture['downloads'] as List) {
        await store.applyPull(
          recoveryPullCodec.decodeRequest(raw['request']),
          (recoveryPullCodec.decodeReply(
            raw['reply'],
          ) as SyncSuccess<RecoveryPullResult>).value,
        );
      }
      final projected = await store.projection(child);
      if (projected.visible ||
          projected.values['existence'] != false ||
          projected.values['title'] != 'Edited step') {
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
      if (history.length != 7) throw StateError('Local history mismatch.');
      stdout.writeln(
        'PASS: seven real receipts, duplicate acknowledgement, original bytes and snapshot-equivalent pull',
      );
    }
  } finally {
    await db.close();
  }
}
