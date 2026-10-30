import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

String id(int n) => '00000000-0000-0000-0000-${n.toString().padLeft(12, '0')}';
Map<String, dynamic> copy(Object? value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  final fixtures = jsonDecode(
    File('test/fixtures/account-protocol-v2-rpc.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final chain = jsonDecode(
    File('test/fixtures/account-protocol-v2-chain.json').readAsStringSync(),
  );
  final codecs = <String, AccountRpcCodec<dynamic, dynamic>>{
    'register': registerDeviceCodec,
    'apply': applyCodec,
    'pull': pullCodec,
    'begin_snapshot': beginSnapshotCodec,
    'snapshot_page': snapshotPageCodec,
    'resolve': resolveConflictCodec,
  };

  test(
    'depth-valid operations survive pull and snapshot recovery wrappers',
    () {
      Object nested = 0;
      for (var i = 0; i < 12; i++) {
        nested = [nested];
      }
      final request = copy(chain);
      request['operations'][0]['provenance'] = {'nested': nested};
      final operation = applyCodec.decodeRequest(request).operations.first;
      final snapshot = copy(fixtures['snapshot_page']['reply']);
      snapshot['result']['recovery'][0]['operation'] = operation.toJson();
      final pull = copy(fixtures['pull']['reply']);
      pull['result']['groups'][0]['recovery'] = snapshot['result']['recovery'];
      final decoded = pullCodec.decodeReply(pull) as SyncSuccess<PullResult>;
      expect(
        decoded.value.groups.single.recovery.single.operation.payloadIdentity,
        operation.payloadIdentity,
      );
      expect(pullCodec.encodeReply(decoded), pull);
      expect(
        snapshotPageCodec.encodeReply(snapshotPageCodec.decodeReply(snapshot)),
        snapshot,
      );

      // Reply wrapping must not relax the embedded operation's own depth limit.
      for (var i = 0; i < 3; i++) {
        nested = [nested];
      }
      pull['result']['groups'][0]['recovery'][0]['operation']['provenance'] = {
        'nested': nested,
      };
      expect(() => pullCodec.decodeReply(pull), throwsFormatException);
    },
  );

  for (final entry in codecs.entries) {
    final golden = fixtures[entry.key] as Map;
    final request = entry.key == 'apply' ? chain : golden['request'];
    test('${entry.key} request/reply match retained v2 goldens', () {
      expect(
        entry.value.encodeRequest(entry.value.decodeRequest(request)),
        request,
      );
      expect(
        entry.value.encodeReply(entry.value.decodeReply(golden['reply'])),
        golden['reply'],
      );
    });
    test(
      '${entry.key} rejects missing, unknown and wrong-version envelopes',
      () {
        for (final mutation in <void Function(Map<String, dynamic>)>[
          (j) => j.remove('protocol_version'),
          (j) => j['protocol_version'] = 1,
          (j) => j['protocol_version'] = 2.0,
          (j) => j['owner_id'] = id(999),
        ]) {
          final q = copy(request);
          mutation(q);
          final r = copy(golden['reply']);
          mutation(r);
          expect(() => entry.value.decodeRequest(q), throwsFormatException);
          expect(() => entry.value.decodeReply(r), throwsFormatException);
        }
      },
    );
  }

  test('registration rejects a response from another server incarnation', () {
    final request = registerDeviceCodec.decodeRequest(
      fixtures['register']['request'],
    );
    final json = fixtures['register']['reply'];
    RegisteredDevice read(Object? value) => (registerDeviceCodec.decodeReply(
      value,
    ) as SyncSuccess<RegisteredDevice>).value;
    validateRegisterDeviceReply(request, read(json));
    final altered = copy(json);
    altered['result']['cursor']['server_epoch'] = id(98);
    expect(
      () => validateRegisterDeviceReply(request, read(altered)),
      throwsFormatException,
    );
  });

  test('snapshot creation rejects another epoch and expired manifests before staging', () {
    final request = beginSnapshotCodec.decodeRequest(
      fixtures['begin_snapshot']['request'],
    );
    final json = fixtures['begin_snapshot']['reply'];
    SnapshotManifest read(Object? value) => (beginSnapshotCodec.decodeReply(
      value,
    ) as SyncSuccess<SnapshotManifest>).value;
    final manifest = read(json);
    final beforeExpiry = manifest.expiresAtUtc.subtract(
      const Duration(microseconds: 1),
    );
    validateBeginSnapshotReply(request, manifest, beforeExpiry);
    for (final now in [
      manifest.expiresAtUtc,
      manifest.expiresAtUtc.add(const Duration(microseconds: 1)),
      DateTime(2026, 10, 13),
    ]) {
      expect(
        () => validateBeginSnapshotReply(request, manifest, now),
        throwsFormatException,
      );
    }
    final altered = copy(json);
    altered['result']['at']['server_epoch'] = id(98);
    expect(
      () => validateBeginSnapshotReply(request, read(altered), beforeExpiry),
      throwsFormatException,
    );
  });

  test('every failure is typed and sequence/rate hints are constrained', () {
    expect(SyncFailureCode.values.map((c) => c.name).toList(), [
      ...fixtures['failure_codes'],
      'recoveryChanged',
      'replacementRejected',
    ]);
    for (final code in SyncFailureCode.values) {
      final golden = {
        'protocol_version': 2,
        'status': 'failure',
        'code': code.name,
        'expected_sequence': code == SyncFailureCode.sequenceGap ? 4 : null,
        'retry_after_seconds': code == SyncFailureCode.rateLimited ? 30 : null,
      };
      final reply = applyCodec.decodeReply(golden) as SyncFailure<ApplyResult>;
      expect(reply.code, code);
      expect(applyCodec.encodeReply(reply), golden);
    }
    for (final reply in [
      const SyncFailure<ApplyResult>(SyncFailureCode.sequenceGap),
      const SyncFailure<ApplyResult>(
        SyncFailureCode.authenticationRequired,
        expectedSequence: 1,
      ),
      const SyncFailure<ApplyResult>(
        SyncFailureCode.accountDeleted,
        retryAfterSeconds: 1,
      ),
      const SyncFailure<ApplyResult>(
        SyncFailureCode.rateLimited,
        retryAfterSeconds: -1,
      ),
    ]) {
      expect(() => applyCodec.encodeReply(reply), throwsFormatException);
    }
  });

  test('apply correlation rejects another operation, epoch, field or accepted value', () {
    final request = applyCodec.decodeRequest(chain);
    final json = fixtures['apply']['reply'];
    ApplyResult read(Object? value) =>
        (applyCodec.decodeReply(value) as SyncSuccess<ApplyResult>).value;
    validateApplyReply(request, read(json));
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['result']['cursor']['server_epoch'] = id(98),
      (j) => j['result']['results'][0]['operation_id'] = id(44),
      (j) => j['result']['results'][0]['fields'][0]['group'] = 'priority',
      (j) =>
          j['result']['results'][2]['fields'][0]['accepted']['value'] = 'wrong',
    ]) {
      final altered = copy(json);
      mutate(altered);
      expect(
        () => validateApplyReply(request, read(altered)),
        throwsFormatException,
      );
    }
    final expired = copy(json);
    expired['result']['results'] = request.operations
        .map(
          (o) => {
            'kind': 'already_processed',
            'operation_id': o.operationId,
            'sequence': o.sequence,
          },
        )
        .toList();
    validateApplyReply(request, read(expired));
    expect(read(expired).results.every((r) => r is AlreadyProcessed), isTrue);
  });

  test('contradictory receipts, future revisions and acknowledgement gaps fail closed', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['result']['results'][0]['disposition'] = 'applied',
      (j) => j['result']['results'][1]['fields'][0]['recovery_id'] = null,
      (j) => j['result']['results'][2]['fields'][0]['recovery_id'] = id(64),
      (j) => j['result']['results'][2]['fields'][0]['accepted']['revision'] = 6,
      (j) => j['result']['results'][2]['revision'] = 6,
      (j) => j['result']['device_high_water'] = 2,
      (j) => j['result']['results'][1]['sequence'] = 3,
      (j) => j['result']['results'][1]['operation_id'] = id(1),
    ]) {
      final value = copy(fixtures['apply']['reply']);
      mutate(value);
      expect(() => applyCodec.decodeReply(value), throwsFormatException);
    }
    final rejected = copy(fixtures['apply']['reply']);
    rejected['result']['results'][0].addAll({
      'disposition': 'rejected',
      'fields': [],
      'rejection_code': 'invalid_title',
    });
    final value =
        (applyCodec.decodeReply(rejected) as SyncSuccess<ApplyResult>).value;
    expect(
      (value.results.first as OperationReceipt).disposition,
      ReceiptDisposition.rejected,
    );
    validateApplyReply(applyCodec.decodeRequest(chain), value);
    rejected['result']['results'][0]['rejection_code'] =
        'SQL error containing task text';
    expect(() => applyCodec.decodeReply(rejected), throwsFormatException);
  });

  test('pull pages cannot regress, split the through cursor, or skip empty progress', () {
    final request = pullCodec.decodeRequest(fixtures['pull']['request']);
    final json = fixtures['pull']['reply'];
    PullResult read(Object? value) =>
        (pullCodec.decodeReply(value) as SyncSuccess<PullResult>).value;
    validatePullReply(request, read(json));
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['result']['has_more'] = true,
      (j) => j['result']['through']['revision'] = 4,
      (j) => j['result']['groups'][0]['revision'] = 4,
      (j) =>
          j['result']['groups'][0]['records'][0]['fields']['title']['revision'] =
              6,
      (j) => j['result']['groups'].add(copy(j['result']['groups'][0])),
      (j) => j['result']['through']['server_epoch'] = id(98),
      (j) => j['result']['groups'] = [],
    ]) {
      final altered = copy(json);
      mutate(altered);
      expect(
        () => validatePullReply(request, read(altered)),
        throwsFormatException,
      );
    }
  });

  test(
    'snapshot binds token, epoch, revision, page, expiry and terminal flag',
    () {
      final manifest = (beginSnapshotCodec.decodeReply(
        fixtures['begin_snapshot']['reply'],
      ) as SyncSuccess<SnapshotManifest>).value;
      final request = snapshotPageCodec.decodeRequest(
        fixtures['snapshot_page']['request'],
      );
      final now = DateTime.utc(2026, 10, 13);
      SnapshotPage read(Object? value) => (snapshotPageCodec.decodeReply(
        value,
      ) as SyncSuccess<SnapshotPage>).value;
      final json = fixtures['snapshot_page']['reply'];
      validateSnapshotPage(manifest, request, read(json), now);
      expect(
        () => validateSnapshotPage(
          manifest,
          request,
          read(json),
          manifest.expiresAtUtc,
        ),
        throwsFormatException,
      );
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (j) => j['result']['token'] = id(81),
        (j) => j['result']['page'] = 1,
        (j) => j['result']['is_last'] = false,
        (j) => j['result']['at']['revision'] = 6,
        (j) => j['result']['at']['server_epoch'] = id(98),
        (j) => j['result']['recovery'][0]['group'] = 'priority',
        (j) => j['result']['recovery'][0]['revision'] = 6,
        (j) => j['result']['records'].add(copy(j['result']['records'][0])),
      ]) {
        final altered = copy(json);
        mutate(altered);
        expect(
          () => validateSnapshotPage(manifest, request, read(altered), now),
          throwsFormatException,
        );
      }
    },
  );

  test('snapshot dates, identifiers, unsafe counters and unknown fields are strict', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['result']['expires_at_utc'] = '2026-02-30T00:00:00.000Z',
      (j) => j['result']['expires_at_utc'] = '2026-10-14T00:00:00.000',
      (j) => j['result']['token'] = 'arbitrary',
      (j) => j['result']['record_count'] = 9007199254740992,
      (j) => j['result']['page_count'] = 0,
      (j) => j['result']['device_high_waters'][id(10)] = -1,
      (j) => j['result']['owner_id'] = id(99),
    ]) {
      final value = copy(fixtures['begin_snapshot']['reply']);
      mutate(value);
      expect(
        () => beginSnapshotCodec.decodeReply(value),
        throwsFormatException,
      );
    }
  });

  test(
    'encoding validates drafts and decoding preserves nullable original bases',
    () {
      expect(
        () => pullCodec.encodeRequest(
          PullRequest((serverEpoch: id(99), revision: -1)),
        ),
        throwsFormatException,
      );
      expect(
        () => pullCodec.encodeRequest(
          PullRequest((serverEpoch: id(99), revision: 0), limit: 201),
        ),
        throwsFormatException,
      );
      final json = copy(chain['operations'][0]);
      json['patches']['title']['base']['value'] = null;
      final operation = decodeAccountOperation(json);
      expect((operation.patches['title']!.base as ObservedBase).value, isNull);
      json['patches']['title']['base'].remove('value');
      expect(() => decodeAccountOperation(json), throwsFormatException);
      expect(
        () => AcceptedField(maxSyncInteger + 1, null),
        throwsFormatException,
      );
    },
  );

  test('parent dependency encoding keeps composite identity and rejects bad targets', () {
    final json = copy(chain['operations'][1]);
    json['entity'] = {
      'kind': 'membership',
      'key': [id(20), id(30)],
    };
    json['command'] = 'task.tag';
    json['patches'] = {
      'membership': {
        'base': {'kind': 'absent'},
        'value': true,
      },
    };
    json['dependencies'] = [
      {
        'entity': {
          'kind': 'task',
          'key': [id(20)],
        },
        'operation_id': id(1),
        'sequence': 1,
        'group': 'existence',
      },
    ];
    expect(decodeAccountOperation(json).toJson(), json);
    json['dependencies'][0]['entity'] = {
      'kind': 'preference',
      'key': ['default_view'],
    };
    expect(() => decodeAccountOperation(json), throwsFormatException);
  });
}
