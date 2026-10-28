import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';

Map<String, dynamic> copy(Object? value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/account-history-v1.json').readAsStringSync(),
  ) as Map;
  final codecs = <String, AccountRpcCodec<dynamic, dynamic>>{
    'pull': historyPullCodec,
    'begin': historyBeginSnapshotCodec,
    'page': historySnapshotPageCodec,
  };
  test(
    'versioned history golden round trips retain known and unknown originals',
    () {
      for (final e in codecs.entries) {
        final f = fixture[e.key];
        expect(
          e.value.encodeRequest(e.value.decodeRequest(f['request'])),
          f['request'],
        );
        expect(
          e.value.encodeReply(e.value.decodeReply(f['reply'])),
          f['reply'],
        );
      }
      final result = (historyPullCodec.decodeReply(
        fixture['pull']['reply'],
      ) as SyncSuccess<HistoryPullResult>).value;
      expect(result.groups[0].history.single.operation, isNull);
      expect(
        result.groups[1].history.single.operation!.operationId,
        result.groups[1].history.single.operationId,
      );
      result.groups[1].history.single.provenance['occurred_at'] = 999;
      expect(result.groups[1].history.single.provenance['occurred_at'], 100);
      validateHistoryPullReply(
        historyPullCodec.decodeRequest(fixture['pull']['request']),
        result,
      );
    },
  );
  test(
    'negotiation rejects downgrade, unknown versions and mixed legacy codecs',
    () {
      for (final e in codecs.entries) {
        for (final v in [null, 0, 2, true, '1']) {
          final request = copy(fixture[e.key]['request'])
            ..['history_version'] = v;
          final reply = copy(fixture[e.key]['reply']);
          reply['result']['history_version'] = v;
          expect(() => e.value.decodeRequest(request), throwsFormatException);
          expect(() => e.value.decodeReply(reply), throwsFormatException);
        }
      }
      expect(
        () => pullCodec.decodeReply(fixture['pull']['reply']),
        throwsFormatException,
      );
      expect(
        () => beginSnapshotCodec.decodeReply(fixture['begin']['reply']),
        throwsFormatException,
      );
      expect(
        () => snapshotPageCodec.decodeReply(fixture['page']['reply']),
        throwsFormatException,
      );
      final legacy = copy(fixture['page']['reply']);
      legacy['result'].remove('history');
      legacy['result'].remove('history_version');
      expect(
        () => historySnapshotPageCodec.decodeReply(legacy),
        throwsFormatException,
      );
    },
  );
  test('history rejects forged identity, future revisions, invalid statuses and original mismatch', () {
    final mutations = <void Function(Map<String, dynamic>)>[
      (e) => e['version'] = 2,
      (e) => e['operation_id'] = 'bad',
      (e) => e['revision'] = 3,
      (e) => e['operation_id'] = fixture['events'][0]['operation_id'],
      (e) => e['task_id'] = fixture['operations'][0]['device_epoch'],
      (e) => e['previous_status']['revision'] = 2,
      (e) => e['status']['value']['status'] = 'invalid',
      (e) => e['fields']['status_group']['revision'] = 1,
      (e) => e['operation']['provenance']['occurred_at'] = 999,
      (e) =>
          e['operation']['patches']['status_group']['value']['completed_at'] =
              101,
      (e) => e['recorded_at_utc'] = '2026-10-28T00:00:00Z',
      (e) => e['extra'] = true,
    ];
    for (final mutate in mutations) {
      final reply = copy(fixture['page']['reply']);
      mutate((reply['result']['history'][1] as Map).cast<String, dynamic>());
      expect(
        () => historySnapshotPageCodec.decodeReply(reply),
        throwsFormatException,
      );
    }
  });
  test('whole revision membership, duplicate identities and page counts are strict', () {
    final reply = copy(fixture['pull']['reply']);
    reply['result']['groups'][1]['history'] = [fixture['events'][0]];
    expect(() => historyPullCodec.decodeReply(reply), throwsFormatException);
    final page = copy(fixture['page']['reply']);
    page['result']['history'] = [fixture['events'][0], fixture['events'][0]];
    expect(
      () => historySnapshotPageCodec.decodeReply(page),
      throwsFormatException,
    );
    page['result']['history'] = List.filled(201, fixture['events'][0]);
    expect(
      () => historySnapshotPageCodec.decodeReply(page),
      throwsFormatException,
    );
  });
  test('snapshot correlations retain fixed revision across interrupted page retries', () {
    final manifest = (historyBeginSnapshotCodec.decodeReply(
      fixture['begin']['reply'],
    ) as SyncSuccess<SnapshotManifest>).value;
    final request = historySnapshotPageCodec.decodeRequest(
      fixture['page']['request'],
    );
    final page = (historySnapshotPageCodec.decodeReply(
      fixture['page']['reply'],
    ) as SyncSuccess<HistorySnapshotPage>).value;
    final now = DateTime.utc(2026, 10, 28);
    for (var i = 0; i < 2; i++) {
      validateHistorySnapshotPage(manifest, request, page, now);
    }
    expect(
      () => validateHistorySnapshotPage(
        manifest,
        request,
        page,
        manifest.expiresAtUtc,
      ),
      throwsFormatException,
    );
    final altered = copy(fixture['page']['reply']);
    altered['result']['at']['revision'] = 3;
    final changed = (historySnapshotPageCodec.decodeReply(
      altered,
    ) as SyncSuccess<HistorySnapshotPage>).value;
    expect(
      () => validateHistorySnapshotPage(manifest, request, changed, now),
      throwsFormatException,
    );
  });
}
