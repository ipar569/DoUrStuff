import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> copy(Object? value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  final golden = jsonDecode(
    File('test/fixtures/account-recovery-v1.json').readAsStringSync(),
  ) as Map;
  test('recovery choice golden round-trips and correlates exact closures', () {
    final request = resolveRecoveryCodec.decodeRequest(golden['request']);
    final reply = resolveRecoveryCodec.decodeReply(
      golden['reply'],
    ) as SyncSuccess<ResolveRecoveryResult>;
    expect(resolveRecoveryCodec.encodeRequest(request), golden['request']);
    expect(resolveRecoveryCodec.encodeReply(reply), golden['reply']);
    validateRecoveryResolutionReply(request, reply.value);
    final retry = copy(golden['request']);
    retry['cursor']['revision'] = 30;
    validateRecoveryResolutionReply(
      resolveRecoveryCodec.decodeRequest(retry),
      reply.value,
    );
  });
  test('malformed decisions and unbound replacements are rejected', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (q) => q.remove('resolution_version'),
      (q) => q['resolution_version'] = 2,
      (q) => q['choice'] = 'automatic',
      (q) => q['choice'] = 'discard',
      (q) => q['replacement']['sequence'] = 9,
      (q) => q['replacement']['patches']['title']['base'] = {
        'kind': 'predecessor',
        'operation_id': q['operation_id'],
        'sequence': 1,
        'value': 'X',
      },
      (q) => q['held_choices'].add(q['held_choices'][0]),
      (q) => q['held_choices'][0]['revision'] = 100,
      (q) => q['observed_fields']['title']['revision'] = 100,
    ]) {
      final q = copy(golden['request']);
      mutate(q);
      expect(
        () => resolveRecoveryCodec.decodeRequest(q),
        throwsFormatException,
      );
    }
  });
  test(
    'reply cannot close unchosen held work or mislabel the original revision',
    () {
      final q = resolveRecoveryCodec.decodeRequest(golden['request']);
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (r) => r['result']['resolutions'][0]['expected_conflict_revision'] = 2,
        (r) => r['result']['resolutions'][1]['conflict_id'] =
            golden['request']['held_choices'][0]['id'],
        (r) => r['result']['resolutions'][0]['sequence'] = 10,
        (r) => r['result']['resolutions'][0]['revision'] = 4,
      ]) {
        final r = copy(golden['reply']);
        mutate(r);
        expect(() {
          final reply = resolveRecoveryCodec.decodeReply(
            r,
          ) as SyncSuccess<ResolveRecoveryResult>;
          validateRecoveryResolutionReply(q, reply.value);
        }, throwsFormatException);
      }
    },
  );
  test('download negotiation requires complete resolution metadata', () {
    final request = recoveryPullCodec.decodeRequest(golden['pull_request']);
    final result = recoveryPullCodec.decodeReply(
      golden['pull_reply'],
    ) as SyncSuccess<RecoveryPullResult>;
    validateRecoveryPullReply(request, result.value);
    expect(recoveryPullCodec.encodeReply(result), golden['pull_reply']);
    final missing = copy(golden['pull_reply']);
    missing['result']['groups'][0].remove('resolutions');
    expect(() => recoveryPullCodec.decodeReply(missing), throwsFormatException);
    expect(
      () => historyPullCodec.decodeReply(golden['pull_reply']),
      throwsFormatException,
    );
    final future = copy(golden['pull_reply']);
    future['result']['groups'][0]['resolutions'][0]['revision'] = 7;
    expect(() => recoveryPullCodec.decodeReply(future), throwsFormatException);
  });
}
