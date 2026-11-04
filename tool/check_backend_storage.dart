import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';

/// Installs complete negotiated snapshots captured by real backend tests into
/// isolated SQLite databases. Never reads account credentials or real user data.
Future<void> main(List<String> args) async {
  if (args.length != 1) throw ArgumentError('Expected synthetic wire file.');
  final entries = jsonDecode(File(args.single).readAsStringSync()) as List;
  final manifests = <String, SnapshotManifest>{};
  final pages = <String, Map<int, RecoverySnapshotPage>>{};
  final times = <String, DateTime>{};
  for (final entry in entries) {
    if (entry['request']['resolution_version'] != 1 ||
        entry['reply']['status'] != 'success') {
      continue;
    }
    if (entry['rpc'] == 'snapshot_begin') {
      final manifest = (recoveryBeginSnapshotCodec.decodeReply(
        entry['reply'],
      ) as SyncSuccess<SnapshotManifest>).value;
      manifests[manifest.token] = manifest;
      times[manifest.token] = DateTime.parse(entry['checked_at_utc'] as String);
    } else if (entry['rpc'] == 'snapshot_page') {
      final page = (recoverySnapshotPageCodec.decodeReply(
        entry['reply'],
      ) as SyncSuccess<RecoverySnapshotPage>).value;
      final changes = page.changes.changes;
      (pages[changes.token] ??= {})[changes.page] = page;
    }
  }
  var installed = 0, records = 0;
  for (final manifest in manifests.values) {
    final captured = pages[manifest.token] ?? {};
    if (captured.length != manifest.pageCount ||
        !List.generate(
          manifest.pageCount,
          (i) => i,
        ).every(captured.containsKey)) {
      continue; // Harnesses also intentionally capture abandoned snapshots.
    }
    final db = AppDatabase(NativeDatabase.memory());
    try {
      const owner = '00000000-0000-0000-0000-000000000001';
      await db.initializeProfile('account-$owner');
      final store = await AccountStore.open(db, owner);
      final time = times[manifest.token]!;
      await store.beginSnapshot(manifest, time);
      for (var i = 0; i < manifest.pageCount; i++) {
        await store.stagePage(captured[i]!, time);
      }
      await store.installSnapshot(time);
      final count =
          (await db
                  .customSelect('SELECT count(*) AS n FROM account_records')
                  .getSingle())
              .read<int>('n');
      if (await store.checkpoint() != manifest.at ||
          count != manifest.recordCount) {
        throw StateError('Installed snapshot mismatch.');
      }
      installed++;
      records += count;
    } finally {
      await db.close();
    }
  }
  if (installed == 0) throw StateError('No complete negotiated snapshots.');
  stdout.writeln(
    '$installed real backend snapshots / $records records installed in SQLite.',
  );
}
