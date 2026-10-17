import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/account_protocol_fixture.dart';

String id(int n) => '00000000-0000-0000-0000-${n.toString().padLeft(12, '0')}';

void main() {
  test(
    'safe JSON integer bounds reject native minimum without abs overflow',
    () {
      expect(canonicalSyncJson(-maxSyncInteger), '-9007199254740991');
      expect(canonicalSyncJson(maxSyncInteger), '9007199254740991');
      for (final value in [
        -9223372036854775808,
        -9007199254740992,
        9007199254740992,
      ]) {
        expect(
          () => canonicalSyncJson({'value': value}),
          throwsFormatException,
        );
      }
    },
  );

  late Map<String, dynamic> fixture;
  late List<AccountOperation> chain;
  late FixtureAccount server;
  setUp(() {
    fixture = jsonDecode(
      File('test/fixtures/account-protocol-v2-chain.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    chain = (fixture['operations'] as List)
        .map((o) => readFixtureOperation(o as Map<String, dynamic>))
        .toList();
    server = FixtureAccount(id(10));
    server.fields[server.fieldKey(chain[0].entity, 'title')] = AcceptedField(
      2,
      'Z',
    );
    server.fields[server.fieldKey(chain[2].entity, 'title')] = AcceptedField(
      1,
      'B1',
    );
  });

  test(
    'v2 original bases and backward-clock chain match golden apply request',
    () {
      final request = ApplyRequest(
        cursor: (serverEpoch: id(99), revision: 2),
        operations: chain,
      );
      expect(request.toJson(), fixture);
      expect(jsonDecode(chain[1].payloadIdentity), fixture['operations'][1]);
      expect(
        chain[1].provenance['occurred_at'],
        lessThan(chain[0].provenance['occurred_at'] as int),
      );
    },
  );

  test('conflict and held successor consume contiguous sequences; unrelated work applies', () {
    final originalPayloads = chain.map((o) => o.payloadIdentity).toList();
    final conflict = server.apply(chain[0]) as OperationReceipt;
    expect(conflict.disposition, ReceiptDisposition.conflict);
    expect(server.highWater, 1);
    final held = server.apply(chain[1]) as OperationReceipt;
    expect(held.disposition, ReceiptDisposition.held);
    expect(server.highWater, 2);
    final unrelated = server.apply(chain[2]) as OperationReceipt;
    expect(unrelated.disposition, ReceiptDisposition.applied);
    expect(server.highWater, 3);
    expect(
      server.fields[server.fieldKey(chain[0].entity, 'title')]!.value,
      'Z',
    );
    expect(
      server.fields[server.fieldKey(chain[2].entity, 'title')]!.value,
      'B2',
    );
    expect(server.recovery['${id(1)}/title']!['base'], {
      'kind': 'observed',
      'revision': 1,
      'value': 'X',
    });
    expect(server.recovery['${id(1)}/title']!['local'], 'Y');
    expect(server.recovery['${id(2)}/title']!['local'], 'W');
    expect(chain.map((o) => o.payloadIdentity), originalPayloads);
  });

  test('lost responses and duplicates return original receipts without another revision', () {
    for (final operation in chain) {
      final first = server.apply(operation);
      final revision = server.revision;
      expect(server.apply(operation), same(first));
      expect(server.revision, revision);
    }
    expect(server.recovery.length, 2);
    expect(server.highWater, 3);
  });

  test('snapshot/reload after receipt expiry preserves held originals and prevents replay', () {
    for (final operation in chain) {
      server.apply(operation);
    }
    final originalRecovery = jsonDecode(jsonEncode(server.recovery));
    server.expireReceipts();
    final restored = FixtureAccount.restore(server.snapshot());
    expect(restored.recovery, originalRecovery);
    for (final operation in chain) {
      expect(restored.apply(operation), isA<AlreadyProcessed>());
    }
    expect(restored.operations.keys, unorderedEquals([id(1), id(2)]));
    for (final operation in chain.take(2)) {
      expect(
        restored.operations[operation.operationId]!.payloadIdentity,
        operation.payloadIdentity,
      );
    }
    expect(restored.highWater, 3);
    expect(restored.revision, 5);
    expect(
      restored.fields[restored.fieldKey(chain[0].entity, 'title')]!.value,
      'Z',
    );
  });

  test('an expired successful predecessor needs recovery instead of a guessed base', () {
    server.fields[server.fieldKey(chain[0].entity, 'title')] = AcceptedField(
      1,
      'X',
    );
    server.apply(chain[0]);
    server.expireReceipts();
    expect(
      (server.apply(chain[1]) as OperationReceipt).fields.single.disposition,
      FieldDisposition.recovery,
    );
    expect(
      server.fields[server.fieldKey(chain[0].entity, 'title')]!.value,
      'Y',
    );
  });

  test('terminal rejection consumes its sequence and preserves repair data across expiry', () {
    final invalid = AccountOperation(
      operationId: chain[0].operationId,
      deviceEpoch: chain[0].deviceEpoch,
      sequence: 1,
      entity: chain[0].entity,
      command: 'task.edit',
      patches: {'title': FieldPatch(ObservedBase(1, 'X'), '')},
    );
    final receipt = server.apply(invalid) as OperationReceipt;
    expect(receipt.disposition, ReceiptDisposition.rejected);
    expect(receipt.rejectionCode, 'invalid_title');
    expect(server.apply(invalid), same(receipt));
    final dependent = server.apply(chain[1]) as OperationReceipt;
    expect(dependent.fields.single.disposition, FieldDisposition.recovery);
    expect(
      (server.apply(chain[2]) as OperationReceipt).disposition,
      ReceiptDisposition.applied,
    );
    expect(server.highWater, 3);
    expect(
      server.fields[server.fieldKey(chain[0].entity, 'title')]!.value,
      'Z',
    );
    server.expireReceipts();
    final restored = FixtureAccount.restore(server.snapshot());
    expect(restored.apply(invalid), isA<AlreadyProcessed>());
    expect(
      restored.recovery['${id(1)}/title']!['rejection_code'],
      'invalid_title',
    );
    expect(
      restored.operations[id(1)]!.payloadIdentity,
      invalid.payloadIdentity,
    );
    expect(restored.highWater, 3);
  });

  test('sequence gaps, reused sequence and changed payload cannot mutate canonical state', () {
    expect(() => server.apply(chain[2]), throwsStateError);
    expect(server.highWater, 0);
    server.apply(chain[0]);
    final changed = Map<String, dynamic>.from(fixture['operations'][0] as Map)
      ..['provenance'] = {'occurred_at': 0};
    final before = server.snapshot();
    expect(() => server.apply(readFixtureOperation(changed)), throwsStateError);
    changed['operation_id'] = id(9);
    expect(() => server.apply(readFixtureOperation(changed)), throwsStateError);
    expect(server.snapshot(), before);
  });

  test('successful predecessor binds its accepted revision without rewriting successor', () {
    server.fields[server.fieldKey(chain[0].entity, 'title')] = AcceptedField(
      1,
      'X',
    );
    server.apply(chain[0]);
    final identity = chain[1].payloadIdentity;
    final receipt = server.apply(chain[1]) as OperationReceipt;
    expect(receipt.disposition, ReceiptDisposition.applied);
    expect(
      server.fields[server.fieldKey(chain[0].entity, 'title')]!.value,
      'W',
    );
    expect(chain[1].payloadIdentity, identity);
  });

  test('a concurrent change after predecessor acceptance still conflicts', () {
    server.fields[server.fieldKey(chain[0].entity, 'title')] = AcceptedField(
      1,
      'X',
    );
    server.apply(chain[0]);
    server.fields[server.fieldKey(chain[0].entity, 'title')] = AcceptedField(
      4,
      'Remote',
    );
    server.revision = 4;
    expect(
      (server.apply(chain[1]) as OperationReceipt).disposition,
      ReceiptDisposition.conflict,
    );
    expect(server.recovery['${id(2)}/title']!['local'], 'W');
  });

  test('dependent equality cannot bypass a conflicted predecessor', () {
    final patch = FieldPatch(PredecessorBase(id(1), 1, 'Y'), 'Z');
    expect(compareField(patch, AcceptedField(2, 'Z')), FieldDisposition.held);
    expect(
      compareField(
        patch,
        AcceptedField(2, 'Z'),
        predecessorNeedsRecovery: true,
      ),
      FieldDisposition.recovery,
    );
  });

  test('bad predecessor identity or original value is recovery, never guessed binding', () {
    server.apply(chain[0]);
    final wrongEntity =
        Map<String, dynamic>.from(fixture['operations'][1] as Map)
          ..['entity'] = {
            'kind': 'task',
            'key': [id(30)],
          };
    expect(
      (server.apply(
        readFixtureOperation(wrongEntity),
      ) as OperationReceipt).fields.single.disposition,
      FieldDisposition.recovery,
    );
    expect(
      compareField(
        FieldPatch(PredecessorBase(id(1), 1, 'Y'), 'W'),
        AcceptedField(3, 'X'),
        acceptedPredecessor: AcceptedField(3, 'X'),
      ),
      FieldDisposition.recovery,
    );
  });

  test(
    'independent groups partially apply while same-field candidate is retained',
    () {
      final operation = AccountOperation(
        operationId: id(1),
        deviceEpoch: id(10),
        sequence: 1,
        entity: chain[0].entity,
        command: 'task.edit',
        patches: {
          'title': FieldPatch(ObservedBase(1, 'X'), 'Y'),
          'priority': FieldPatch(ObservedBase(1, 0), 3),
        },
      );
      server.fields[server.fieldKey(operation.entity, 'priority')] =
          AcceptedField(1, 0);
      expect(
        (server.apply(operation) as OperationReceipt).disposition,
        ReceiptDisposition.partial,
      );
      expect(
        server.fields[server.fieldKey(operation.entity, 'priority')]!.value,
        3,
      );
      expect(
        server.fields[server.fieldKey(operation.entity, 'title')]!.value,
        'Z',
      );
    },
  );

  test(
    'observed equivalence, nullable fields and absent fields stay distinct',
    () {
      expect(
        compareField(
          FieldPatch(ObservedBase(1, 'X'), 'Z'),
          AcceptedField(2, 'Z'),
        ),
        FieldDisposition.equivalent,
      );
      expect(
        compareField(
          FieldPatch(ObservedBase(2, 'wrong'), 'Y'),
          AcceptedField(2, 'Z'),
        ),
        FieldDisposition.recovery,
      );
      expect(
        compareField(FieldPatch(const AbsentBase(), null), null),
        FieldDisposition.applied,
      );
      expect(
        compareField(
          FieldPatch(ObservedBase(1, null), 10),
          AcceptedField(1, null),
        ),
        FieldDisposition.applied,
      );
      expect(
        compareField(FieldPatch(ObservedBase(1, null), 10), null),
        FieldDisposition.conflict,
      );
    },
  );

  test('atomic group conflicts never mix status or due members', () {
    final base = {'status': 'todo', 'completed_at': null};
    final local = {'status': 'completed', 'completed_at': 100};
    final remote = {'status': 'cancelled', 'completed_at': null};
    expect(
      compareField(
        FieldPatch(ObservedBase(1, base), local),
        AcceptedField(2, remote),
      ),
      FieldDisposition.conflict,
    );
    final due = FieldPatch(ObservedBase(1, {'kind': 'none'}), {
      'kind': 'date',
      'date': '2026-10-12',
    });
    expect(
      compareField(
        due,
        AcceptedField(2, {'kind': 'date', 'date': '2026-10-13'}),
      ),
      FieldDisposition.conflict,
    );
  });

  test('caller mutation cannot change an operation payload or nested base', () {
    final value = {
      'ordered_ids': [id(20)],
    };
    final patches = {
      'milestone_order': FieldPatch(ObservedBase(1, value), value),
    };
    final operation = AccountOperation(
      operationId: id(1),
      deviceEpoch: id(10),
      sequence: 1,
      entity: chain[0].entity,
      command: 'task.milestone_order',
      patches: patches,
    );
    final identity = operation.payloadIdentity;
    value['ordered_ids']!.add(id(30));
    patches.clear();
    expect(operation.payloadIdentity, identity);
    expect(
      () =>
          (operation.patches['milestone_order']!.value as Map)['ordered_ids'] =
              [],
      throwsUnsupportedError,
    );
    expect(
      canonicalSyncJson({'b': 2, 'a': 1}),
      canonicalSyncJson({'a': 1, 'b': 2}),
    );
  });

  test('entity kinds and composite memberships cannot collide', () {
    final task = SyncEntity(SyncEntityKind.task, [id(20)]);
    final tag = SyncEntity(SyncEntityKind.tag, [id(20)]);
    final membership = SyncEntity(SyncEntityKind.membership, [id(20), id(30)]);
    expect({task.identity, tag.identity, membership.identity}.length, 3);
    expect(
      membership.identity,
      isNot(SyncEntity(SyncEntityKind.membership, [id(30), id(20)]).identity),
    );
    expect(
      () => SyncEntity(SyncEntityKind.membership, [id(20)]),
      throwsFormatException,
    );
    expect(
      () => SyncEntity(SyncEntityKind.preference, ['device_theme']),
      throwsFormatException,
    );
  });

  test('cycles, unsafe values, unsupported field fragments and oversized batches fail closed', () {
    AccountOperation make(FieldPatch patch, {String group = 'title'}) =>
        AccountOperation(
          operationId: id(2),
          deviceEpoch: id(10),
          sequence: 2,
          entity: chain[0].entity,
          command: 'task.edit',
          patches: {group: patch},
        );
    expect(
      () => make(FieldPatch(PredecessorBase(id(2), 2, 'X'), 'Y')),
      throwsFormatException,
    );
    expect(
      () => make(FieldPatch(const AbsentBase(), 'Y'), group: 'completed_at'),
      throwsFormatException,
    );
    expect(
      () => make(FieldPatch(const AbsentBase(), 'x' * 65536)),
      throwsFormatException,
    );
    expect(() => canonicalSyncJson(double.nan), throwsFormatException);
    expect(() => canonicalSyncJson(9007199254740992), throwsFormatException);
    expect(
      () => ApplyRequest(
        cursor: (serverEpoch: id(99), revision: 2),
        operations: [chain[0], chain[2]],
      ),
      throwsFormatException,
    );
    expect(
      () => ApplyRequest(
        cursor: (serverEpoch: id(99), revision: 2),
        operations: List.filled(33, chain.first),
      ),
      throwsFormatException,
    );
  });
}
