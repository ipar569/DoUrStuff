import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> copy(Object? value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  final golden = jsonDecode(
    File('test/fixtures/account-recovery-v2.json').readAsStringSync(),
  ) as Map;

  test(
    'compound create golden round-trips and binds every closure and mapping',
    () {
      final q = resolveCreateRecoveryCodec.decodeRequest(golden['request']);
      final r = resolveCreateRecoveryCodec.decodeReply(
        golden['reply'],
      ) as SyncSuccess<ResolveCreateRecoveryResult>;
      expect(resolveCreateRecoveryCodec.encodeRequest(q), golden['request']);
      expect(resolveCreateRecoveryCodec.encodeReply(r), golden['reply']);
      validateCreateRecoveryReply(q, r.value);
      final refreshed = copy(golden['request']);
      refreshed['cursor']['revision'] = 100;
      validateCreateRecoveryReply(
        resolveCreateRecoveryCodec.decodeRequest(refreshed),
        r.value,
      );
    },
  );

  test(
    'copy-as-new binds a distinct destination without changing originals',
    () {
      final q = copy(golden['request']);
      q['choice'] = 'copyAsNew';
      q['replacement']['entity']['key'][0] =
          '00000000-0000-0000-0000-000000000080';
      final r = copy(golden['reply']);
      r['result']['mapping']['created_entity'] = q['replacement']['entity'];
      validateCreateRecoveryReply(
        resolveCreateRecoveryCodec.decodeRequest(q),
        (resolveCreateRecoveryCodec.decodeReply(
          r,
        ) as SyncSuccess<ResolveCreateRecoveryResult>).value,
      );
      expect(q['source_entity'], golden['request']['source_entity']);
      expect(
        () => resolveRecoveryCodec.decodeRequest(q),
        throwsFormatException,
      );
      expect(() => resolveRecoveryCodec.decodeReply(r), throwsFormatException);
    },
  );

  test('malformed or incomplete compound identities and previews fail closed', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (q) => q.remove('resolution_version'),
      (q) => q['resolution_version'] = 1,
      (q) => q['choice'] = 'discard',
      (q) => q['choice'] = 'copyAsNew',
      (q) => q['replacement']['entity']['key'][0] =
          '00000000-0000-0000-0000-000000000080',
      (q) => q['replacement']['sequence'] = 6,
      (q) => q['source_operation_id'] = q['operation_id'],
      (q) => q['conflicts'] = [],
      (q) => q['conflicts'].add(q['conflicts'][0]),
      (q) => q['conflicts'][0]['revision'] = 100,
      (q) => q['held_choices'][0]['id'] = q['conflicts'][0]['id'],
      (q) => q['replacement']['command'] = 'task.edit',
      (q) => q['replacement']['patches']['title']['base'] = {
        'kind': 'observed',
        'revision': 1,
        'value': 'X',
      },
      (q) => q['observed_fields'] = {
        'title': {'revision': 1, 'value': 'existing'},
      },
      (q) => q['conflicts'] = List.generate(
        201,
        (n) => {
          'id':
              '00000000-0000-0000-0000-${(1000 + n).toString().padLeft(12, '0')}',
          'revision': 2,
        },
      ),
    ]) {
      final q = copy(golden['request']);
      mutate(q);
      expect(
        () => resolveCreateRecoveryCodec.decodeRequest(q),
        throwsFormatException,
      );
    }
  });

  test(
    'reply rejects wrong mappings, missing groups and unchosen held closures',
    () {
      final q = resolveCreateRecoveryCodec.decodeRequest(golden['request']);
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (r) => r['result']['mapping']['created_entity']['key'][0] =
            '00000000-0000-0000-0000-000000000080',
        (r) => r['result']['mapping']['source_operation_id'] =
            q.replacement.operationId,
        (r) => r['result']['resolutions'].removeAt(0),
        (r) => r['result']['resolutions'][0]['choice'] = 'discard',
        (r) => r['result']['resolutions'][0]['expected_conflict_revision'] = 1,
        (r) => r['result']['resolutions'][0]['conflict_id'] =
            q.heldChoices.first.id,
        (r) => r['result']['device_high_water'] = 6,
      ]) {
        final r = copy(golden['reply']);
        mutate(r);
        expect(
          () => validateCreateRecoveryReply(
            q,
            (resolveCreateRecoveryCodec.decodeReply(
              r,
            ) as SyncSuccess<ResolveCreateRecoveryResult>).value,
          ),
          throwsFormatException,
        );
      }
    },
  );
}
