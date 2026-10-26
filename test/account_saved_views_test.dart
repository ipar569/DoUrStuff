import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_policy.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:dourstuff/domain/account_view_validation.dart';
import 'package:dourstuff/domain/query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/account-protocol-v2-saved-views.json')
        .readAsStringSync(),
  );
  final request = applyCodec.decodeRequest(fixture);
  test(
    'saved views retain atomic queries and exact reference dependencies',
    () {
      expect(applyCodec.encodeRequest(request), fixture);
      final create = request.operations[0];
      final select = request.operations[1];
      final rename = request.operations[2];
      final queryEdit = request.operations[3];
      expect(select.entity.key, ['default_view']);
      expect(
        select.dependencies.single.entity.identity,
        create.entity.identity,
      );
      expect(select.dependencies.single.operationId, create.operationId);
      expect(select.patches['value']!.value, create.entity.key.single);
      expect(rename.patches.keys, ['name']);
      expect(queryEdit.patches.keys, ['query']);
      expect(queryEdit.patches['query']!.base, isA<PredecessorBase>());
      expect(validAccountViewQuery(queryEdit.patches['query']!.value), isTrue);
      expect(
        () => (queryEdit.patches['query']!.value as Map)['search'] = 'Changed',
        throwsUnsupportedError,
      );
      expect(
        compareField(
          FieldPatch(
            ObservedBase(1, TaskQuery().toJson()),
            TaskQuery(group: TaskGrouping.tag).toJson(),
          ),
          AcceptedField(3, TaskQuery(search: 'Focus').toJson()),
        ),
        FieldDisposition.conflict,
      );
    },
  );

  test(
    'complete query validation preserves canonical set and filter semantics',
    () {
      final query = TaskQuery().toJson();
      expect(validAccountViewQuery(query), isTrue);
      for (final invalid in [
        {...query, 'version': 1.0},
        {...query}..remove('from'),
        {...query, 'extra': true},
        {
          ...query,
          'statuses': ['todo', 'todo'],
        },
        {
          ...query,
          'statuses': ['todo', 'completed'],
        },
        {
          ...query,
          'tags': ['not-a-uuid'],
        },
        {...query, 'search': '😀' * 1001},
        {...query, 'from': '2026-02-29'},
        {...query, 'undated': true, 'overdue': true},
        {...query, 'from': '2026-10-26', 'to': '2026-10-25'},
      ]) {
        expect(validAccountViewQuery(invalid), isFalse);
      }
      expect(validAccountViewQuery({...query, 'search': '😀' * 1000}), isTrue);
      expect(validAccountViewName('😀' * 40), isTrue);
      for (final invalid in ['', ' Work', 'Work\tNow', '😀' * 41, null]) {
        expect(validAccountViewName(invalid), isFalse);
      }
    },
  );

  test(
    'view references require exact live same-owner predecessor evidence',
    () {
      final parent = request.operations[0];
      final child = request.operations[1];
      ParentDisposition check({
        String? owner = 'X',
        bool visible = true,
        bool held = false,
      }) => checkParentDependency(
        authenticatedOwner: 'X',
        parentOwner: owner,
        child: child,
        dependency: child.dependencies.single,
        predecessor: parent,
        receipt: OperationReceipt(
          operationId: parent.operationId,
          sequence: parent.sequence,
          revision: 1,
          disposition: held
              ? ReceiptDisposition.conflict
              : ReceiptDisposition.applied,
          fields: [
            FieldOutcome(
              group: 'existence',
              disposition: held
                  ? FieldDisposition.conflict
                  : FieldDisposition.applied,
              accepted: held ? null : AcceptedField(1, true),
              recoveryId: held ? '40000000-0000-0000-0000-000000000001' : null,
            ),
          ],
        ),
        parentVisible: visible,
      );
      expect(check(), ParentDisposition.ready);
      expect(check(owner: 'Y'), ParentDisposition.rejected);
      expect(check(owner: null), ParentDisposition.recovery);
      expect(check(visible: false), ParentDisposition.recovery);
      expect(check(held: true), ParentDisposition.held);
      expect(
        defaultAfterViewDeletion('other', parent.entity.key.single),
        'other',
      );
      expect(
        defaultAfterViewDeletion(
          parent.entity.key.single,
          parent.entity.key.single,
        ),
        isNull,
      );
    },
  );
}
