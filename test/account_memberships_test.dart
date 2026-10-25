import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_policy.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'membership wire retains exact parent identities and original bases',
    () {
      final fixture = jsonDecode(
        File('test/fixtures/account-protocol-v2-memberships.json')
            .readAsStringSync(),
      );
      final request = applyCodec.decodeRequest(fixture);
      expect(applyCodec.encodeRequest(request), fixture);
      final task = request.operations[0];
      final tag = request.operations[1];
      final add = request.operations[2];
      final remove = request.operations[3];
      final again = request.operations[4];
      expect(add.entity.key, [task.entity.key.single, tag.entity.key.single]);
      expect(add.dependencies.map((d) => d.entity.identity), [
        task.entity.identity,
        tag.entity.identity,
      ]);
      expect(add.dependencies.map((d) => d.operationId), [
        task.operationId,
        tag.operationId,
      ]);
      expect(add.patches['membership']!.base, isA<AbsentBase>());
      expect(remove.patches['membership']!.value, false);
      final removeBase = remove.patches['membership']!.base as PredecessorBase;
      expect(removeBase.operationId, add.operationId);
      expect(removeBase.sequence, add.sequence);
      expect(removeBase.value, true);
      final againBase = again.patches['membership']!.base as PredecessorBase;
      expect(againBase.operationId, remove.operationId);
      expect(againBase.value, false);
      final payload = add.payloadIdentity;
      expect(
        () => add.entity.key[1] = task.operationId,
        throwsUnsupportedError,
      );
      expect(() => add.dependencies.clear(), throwsUnsupportedError);
      expect(add.payloadIdentity, payload);
    },
  );

  test('membership bases distinguish absent, removed and held work', () {
    final removed = AcceptedField(7, false);
    expect(
      compareField(FieldPatch(const AbsentBase(), true), removed),
      FieldDisposition.conflict,
    );
    expect(
      compareField(FieldPatch(ObservedBase(7, false), true), removed),
      FieldDisposition.applied,
    );
    expect(
      compareField(
        FieldPatch(
          PredecessorBase('00000000-0000-0000-0000-000000000001', 1, true),
          false,
        ),
        removed,
      ),
      FieldDisposition.held,
    );
  });

  test(
    'removal parent dependency retains exact evidence under a tombstone',
    () {
      final fixture = jsonDecode(
        File('test/fixtures/account-protocol-v2-memberships.json')
            .readAsStringSync(),
      );
      final operations = applyCodec.decodeRequest(fixture).operations;
      final parent = operations[1];
      final add = operations[2];
      final remove = operations[3];
      final receipt = OperationReceipt(
        operationId: parent.operationId,
        sequence: parent.sequence,
        revision: 2,
        disposition: ReceiptDisposition.applied,
        fields: [
          FieldOutcome(
            group: 'existence',
            disposition: FieldDisposition.applied,
            accepted: AcceptedField(2, true),
          ),
        ],
      );
      ParentDisposition check(AccountOperation child, String? owner) =>
          checkParentDependency(
            authenticatedOwner: 'X',
            parentOwner: owner,
            child: child,
            dependency: add.dependencies[1],
            predecessor: parent,
            receipt: receipt,
            parentVisible: false,
          );
      expect(check(add, 'X'), ParentDisposition.recovery);
      expect(check(remove, 'X'), ParentDisposition.ready);
      expect(check(remove, null), ParentDisposition.recovery);
      expect(check(remove, 'Y'), ParentDisposition.rejected);
    },
  );
}
