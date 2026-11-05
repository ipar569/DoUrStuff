import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart';
import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';

Map<String, Object?> reply(Object? result) => {
  'protocol_version': 2,
  'status': 'success',
  'result': result,
};

/// Consumes an owner-correlated synthetic capture, never guesses ownership from
/// a shared server epoch or matches unrelated harness accounts by revision.
Future<void> main(List<String> args) async {
  if (args.length != 1) throw ArgumentError('Expected synthetic pull capture.');
  final fixture = jsonDecode(File(args.single).readAsStringSync()) as Map;
  final manifest = (recoveryBeginSnapshotCodec.decodeReply(
    reply(fixture['manifest']),
  ) as SyncSuccess<SnapshotManifest>).value;
  final operation = decodeAccountOperation(
    jsonDecode(fixture['pending_envelope'] as String),
  );
  final db = AppDatabase(NativeDatabase.memory());
  try {
    const owner = '00000000-0000-0000-0000-000000000001';
    await db.initializeProfile('account-$owner');
    await db.customStatement('UPDATE profile_metadata SET device_epoch=?', [
      operation.deviceEpoch,
    ]);
    final store = await AccountStore.open(db, owner);
    final now = DateTime.parse(fixture['checked_at_utc'] as String);
    await store.beginSnapshot(manifest, now);
    for (final raw in fixture['pages'] as List) {
      await store.stagePage(
        (recoverySnapshotPageCodec.decodeReply(
          reply(raw),
        ) as SyncSuccess<RecoverySnapshotPage>).value,
        now,
      );
    }
    await store.installSnapshot(now);
    await store.retainOperation(fixture['pending_envelope'] as String);
    if ((await store.projection(operation.entity)).values['title'] !=
        'offline original') {
      throw StateError('Initial local proposal not projected.');
    }
    var pages = 0;
    for (final download in fixture['downloads'] as List) {
      final request = recoveryPullCodec.decodeRequest(download['request']);
      final result = (recoveryPullCodec.decodeReply(
        download['reply'],
      ) as SyncSuccess<RecoveryPullResult>).value;
      await store.applyPull(request, result);
      if (await store.checkpoint() != result.changes.through) {
        throw StateError('Pull checkpoint mismatch.');
      }
      pages++;
    }
    final projection = await store.projection(operation.entity);
    if (projection.values['title'] != 'chosen' ||
        projection.unresolvedRecovery.isNotEmpty ||
        projection.proposals.single.operation.payloadIdentity !=
            operation.payloadIdentity ||
        projection.proposals.single.projectedOutcomes['title'] !=
            FieldDisposition.conflict) {
      throw StateError('Pending-safe final projection mismatch.');
    }
    final expected = <String>[];
    for (final page in fixture['terminal_pages'] as List) {
      for (final kind in ['records', 'recovery', 'history', 'resolutions']) {
        for (final value in page[kind] as List) {
          expected.add(
            '$kind:${canonicalSyncJson(value, maxDepth: maxSyncReplyDepth)}',
          );
        }
      }
    }
    expected.sort();
    final rows = await db.customSelect('SELECT * FROM account_records').get();
    final actual =
        rows
            .map(
              (r) =>
                  '${r.read<String>('record_kind')}:${r.read<String>('record_json')}',
            )
            .toList()
          ..sort();
    if (jsonEncode(actual) != jsonEncode(expected)) {
      throw StateError(
        'Incremental state differs from authoritative snapshot.',
      );
    }
    if ((await db
                .customSelect('SELECT envelope_json FROM account_operations')
                .getSingle())
            .read<String>('envelope_json') !=
        fixture['pending_envelope']) {
      throw StateError('Original envelope bytes changed.');
    }
    stdout.writeln(
      '$pages real pull pages / ${rows.length} records match the terminal snapshot; pending bytes and conflict preserved.',
    );
  } finally {
    await db.close();
  }
}
