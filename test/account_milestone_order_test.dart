import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_policy.dart';
import 'package:dourstuff/domain/account_task_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/account-protocol-v2-milestone-order.json')
        .readAsStringSync(),
  ) as Map;
  test(
    'ordering golden retains original groups, dependencies and payloads',
    () {
      final request = applyCodec.decodeRequest(fixture['request']);
      expect(applyCodec.encodeRequest(request), fixture['request']);
      final first = request.operations[3];
      final next = request.operations[4];
      expect(first.command, 'task.milestone_order');
      expect(first.dependencies.length, 3);
      expect(next.patches['milestone_order']!.base, isA<PredecessorBase>());
      final base = next.patches['milestone_order']!.base as PredecessorBase;
      expect(base.operationId, first.operationId);
      expect(base.value, first.patches['milestone_order']!.value);
      expect(
        () => (base.value as Map)['ordered_ids'].clear(),
        throwsUnsupportedError,
      );
    },
  );
  test(
    'order validation and deletion/addition projection match shared cases',
    () {
      for (final entry in fixture['validity'] as List) {
        expect(validAccountMilestoneOrder(entry['value']), entry['valid']);
      }
      for (final entry in fixture['projections'] as List) {
        final original = canonicalSyncJson(entry['order']);
        expect(
          projectMilestoneOrder(
            entry['order'],
            (entry['visible'] as List).cast<String>().toSet(),
          ),
          entry['expected'],
        );
        expect(canonicalSyncJson(entry['order']), original);
      }
      expect(
        () => projectMilestoneOrder({
          'ordered_ids': [true],
        }, {}),
        throwsFormatException,
      );
    },
  );
}
