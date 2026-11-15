import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart' hide AccountOperation;
import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';

import 'account_commands_test.dart' show createFields;
import 'account_store_test.dart' show id, now, at, task, manifest, page;

void main() {
  late Directory dir;
  late AppDatabase db;
  late AccountStore store;
  var serial = 10;
  final a = SyncEntity(SyncEntityKind.milestone, [id(3)]);
  final b = SyncEntity(SyncEntityKind.milestone, [id(4)]);
  Map<String, Object?> order(List<String> ids) => {'ordered_ids': ids};
  Future<void> install(List<ShadowRecord> records) async {
    final m = manifest(count: records.length);
    await store.beginSnapshot(m, now);
    await store.stagePage(page(m, records: records), now);
    await store.installSnapshot(now);
  }

  ShadowRecord child(SyncEntity entity, {bool exists = true, String? parent}) =>
      ShadowRecord(
        entity: entity,
        fields: {
          'existence': AcceptedField(2, exists),
          'parent': AcceptedField(2, parent ?? task.key.single),
          'title': AcceptedField(2, 'Step'),
          'completion': AcceptedField(2, null),
        },
        deleteOperationId: exists ? null : id(90),
      );
  Future<AccountOperation> commit(
    String command,
    SyncEntity entity,
    Map<String, FieldPatch> patches, [
    List<OperationDependency> deps = const [],
    String? operationId,
  ]) => store.commitCommand(
    operationId: operationId ?? id(serial++),
    entity: entity,
    command: command,
    patches: patches,
    dependencies: deps,
    occurredAtUtc: now,
  );
  Future<AccountOperation> reorder(
    List<String> ids, {
    FieldBase base = const AbsentBase(),
    List<OperationDependency> deps = const [],
    String? operationId,
  }) => commit(
    'task.milestone_order',
    task,
    {'milestone_order': FieldPatch(base, order(ids))},
    deps,
    operationId,
  );
  OperationDependency dep(AccountOperation op) => OperationDependency(
    entity: op.entity,
    operationId: op.operationId,
    sequence: op.sequence,
  );
  PredecessorBase base(AccountOperation op, String group) =>
      PredecessorBase(op.operationId, op.sequence, op.patches[group]!.value);
  Future<AccountOperation> createChild(
    AccountOperation parent,
    SyncEntity entity,
  ) => commit(
    'milestone.create',
    entity,
    {
      'existence': FieldPatch(const AbsentBase(), true),
      'parent': FieldPatch(const AbsentBase(), task.key.single),
      'title': FieldPatch(const AbsentBase(), 'Pending step'),
      'completion': FieldPatch(const AbsentBase(), null),
    },
    [dep(parent)],
  );
  Future<FieldDisposition> decision(AccountOperation op) async =>
      (await store.projection(op.entity)).proposals
          .singleWhere((p) => p.operation.operationId == op.operationId)
          .projectedOutcomes
          .values
          .single;
  Future<String> durable() async => jsonEncode([
    for (final table in [
      'profile_metadata',
      'account_operations',
      'account_originals',
      'account_command_history',
      'account_notification_dirty',
    ])
      (await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
          .map((r) => r.data)
          .toList(),
  ]);
  setUp(() async {
    serial = 10;
    dir = await Directory.systemTemp.createTemp('account-order-');
    db = AppDatabase.file(File('${dir.path}/profile.sqlite'));
    await db.initializeProfile('account-${id(1)}');
    store = await AccountStore.open(db, id(1));
    await install([
      ShadowRecord(entity: task, fields: {'existence': AcceptedField(1, true)}),
      child(a),
      child(b),
    ]);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('order and causal reorder persist atomically, retry once, and survive reopen', () async {
    final first = await reorder([id(4), id(3)], operationId: id(20));
    final beforeRetry = await durable();
    expect(
      (await reorder([id(4), id(3)], operationId: id(20))).payloadIdentity,
      first.payloadIdentity,
    );
    expect(await durable(), beforeRetry);
    await expectLater(reorder([id(3)], operationId: id(20)), throwsStateError);
    final second = await reorder([
      id(3),
      id(4),
    ], base: base(first, 'milestone_order'));
    expect(await decision(second), FieldDisposition.applied);
    final beforeReopen = await durable();
    await db.close();
    db = AppDatabase.file(File('${dir.path}/profile.sqlite'));
    store = await AccountStore.open(db, id(1));
    expect(await store.visibleMilestoneOrder(task), [id(3), id(4)]);
    expect(await durable(), beforeReopen);
    final history = await db
        .customSelect('SELECT * FROM account_command_history ORDER BY rowid')
        .get();
    expect(history.length, 2);
    expect(
      jsonDecode(history.last.read<String>('before_json'))['milestone_order'],
      order([id(4), id(3)]),
    );
    expect(
      jsonDecode(history.last.read<String>('after_json'))['milestone_order'],
      order([id(3), id(4)]),
    );
    expect(
      (await db
              .customSelect('SELECT generation FROM account_notification_dirty')
              .getSingle())
          .read<int>('generation'),
      2,
    );
  });

  for (final table in [
    'account_command_history',
    'account_notification_dirty',
  ]) {
    test('reorder rolls back all local state at $table failure', () async {
      final before = await durable();
      await db.customStatement(
        "CREATE TRIGGER injected BEFORE INSERT ON $table BEGIN SELECT RAISE(ABORT,'injected'); END",
      );
      await expectLater(reorder([id(4)]), throwsA(anything));
      expect(await durable(), before);
      expect(
        (await store.projection(task)).values.containsKey('milestone_order'),
        isFalse,
      );
    });
  }

  test('invalid shape, duplicate IDs and invalid dependency targets allocate nothing', () async {
    final before = await durable();
    for (final value in [
      null,
      {
        'ordered_ids': [id(3), id(3)],
      },
      {
        'ordered_ids': ['bad'],
      },
      {'ordered_ids': [], 'extra': true},
    ]) {
      await expectLater(
        commit('task.milestone_order', task, {
          'milestone_order': FieldPatch(const AbsentBase(), value),
        }),
        throwsFormatException,
      );
    }
    await expectLater(
      commit('task.edit', task, {
        'milestone_order': FieldPatch(const AbsentBase(), order([])),
      }),
      throwsFormatException,
    );
    await expectLater(
      commit('task.milestone_order', task, {
        'milestone_order': FieldPatch(const AbsentBase(), order([])),
        'title': FieldPatch(const AbsentBase(), 'mixed'),
      }),
      throwsFormatException,
    );
    expect(await durable(), before);
    final first = await reorder([]);
    final invalid = OperationDependency(
      entity: a,
      operationId: first.operationId,
      sequence: first.sequence,
    );
    final afterFirst = await durable();
    await expectLater(reorder([], deps: [invalid]), throwsFormatException);
    await expectLater(
      reorder([id(3)], deps: [invalid, invalid]),
      throwsFormatException,
    );
    expect(await durable(), afterFirst);
  });

  test(
    'concurrent order conflicts and holds descendants before equivalence',
    () async {
      final first = await reorder([id(4), id(3)]);
      final conflict = await reorder([id(3), id(4)]);
      final held = await reorder([
        id(4),
        id(3),
      ], base: base(conflict, 'milestone_order'));
      expect(await decision(first), FieldDisposition.applied);
      expect(await decision(conflict), FieldDisposition.conflict);
      expect(await decision(held), FieldDisposition.held);
      expect(await store.visibleMilestoneOrder(task), [id(4), id(3)]);
    },
  );

  test(
    'a full batch of dependent reorders projects each causal prefix safely',
    () async {
      var op = await reorder([id(3), id(4)]);
      for (var i = 1; i < 32; i++) {
        op = await reorder(
          i.isOdd ? [id(4), id(3)] : [id(3), id(4)],
          base: base(op, 'milestone_order'),
        );
      }
      expect(await decision(op), FieldDisposition.applied);
      expect(await store.visibleMilestoneOrder(task), [id(4), id(3)]);
    },
  );

  test('pending parent and children bind exact dependencies without recursive visibility loops', () async {
    await install([]);
    final parent = await commit('task.create', task, createFields());
    final stepA = await createChild(parent, a);
    final stepB = await createChild(parent, b);
    final op = await reorder(
      [id(4), id(3)],
      deps: [dep(parent), dep(stepA), dep(stepB)],
    );
    expect(await decision(op), FieldDisposition.applied);
    expect(await store.visibleMilestoneOrder(task), [id(4), id(3)]);
    await commit('milestone.delete', a, {
      'existence': FieldPatch(base(stepA, 'existence'), false),
    });
    expect(await store.visibleMilestoneOrder(task), [id(4)]);
    expect(
      (await store.projection(task)).values['milestone_order'],
      order([id(4), id(3)]),
    );
  });

  test('held child dependency stays held, while any missing identity wins recovery', () async {
    await install([
      ShadowRecord(entity: task, fields: {'existence': AcceptedField(1, true)}),
    ]);
    final collision = await commit('task.create', task, createFields());
    final heldChild = await createChild(collision, a);
    final held = await reorder([id(3)], deps: [dep(heldChild)]);
    expect(await decision(held), FieldDisposition.held);
    final missing = await reorder([id(3), id(4)], deps: [dep(heldChild)]);
    expect(await decision(missing), FieldDisposition.recovery);
    expect(await store.visibleMilestoneOrder(task), isEmpty);
  });

  test('wrong parent, missing dependency proof and wrong sequence require recovery', () async {
    await install([
      ShadowRecord(entity: task, fields: {'existence': AcceptedField(1, true)}),
      child(a, parent: id(8)),
      child(b),
    ]);
    expect(await decision(await reorder([id(3)])), FieldDisposition.recovery);
    final op = await reorder([id(4)]);
    expect(
      await decision(
        await reorder(
          [id(4)],
          deps: [
            OperationDependency(
              entity: b,
              operationId: op.operationId,
              sequence: op.sequence,
            ),
          ],
        ),
      ),
      FieldDisposition.recovery,
    );
  });

  test('tombstones filter and independent additions append without rewriting order', () async {
    final op = await reorder([id(4), id(3)]);
    await install([
      ShadowRecord(entity: task, fields: {'existence': AcceptedField(1, true)}),
      child(a, exists: false),
      child(b),
      child(SyncEntity(SyncEntityKind.milestone, [id(6)])),
      child(SyncEntity(SyncEntityKind.milestone, [id(5)])),
    ]);
    expect(await decision(op), FieldDisposition.applied);
    expect(await store.visibleMilestoneOrder(task), [id(4), id(5), id(6)]);
    expect(
      (await store.projection(task)).values['milestone_order'],
      order([id(4), id(3)]),
    );
    await commit('task.delete', task, {
      'existence': FieldPatch(ObservedBase(1, true), false),
    });
    expect(await store.visibleMilestoneOrder(task), isEmpty);
    expect(await decision(await reorder([])), FieldDisposition.recovery);
  });

  test('receipt bridges pull lag then newer snapshot supersedes it, keeping originals', () async {
    final op = await reorder([id(4), id(3)]);
    final original = op.payloadIdentity;
    final request = ApplyRequest(cursor: at, operations: [op]);
    final result = ApplyResult(
      cursor: (serverEpoch: id(99), revision: 6),
      deviceHighWater: 1,
      results: [
        OperationReceipt(
          operationId: op.operationId,
          sequence: 1,
          revision: 6,
          disposition: ReceiptDisposition.applied,
          fields: [
            FieldOutcome(
              group: 'milestone_order',
              disposition: FieldDisposition.applied,
              accepted: AcceptedField(6, order([id(4), id(3)])),
            ),
          ],
        ),
      ],
    );
    await store.retainApplyResult(request, result);
    await store.retainApplyResult(request, result);
    expect(await store.visibleMilestoneOrder(task), [id(4), id(3)]);
    final m = manifest(token: 71, count: 3, revision: 7);
    await store.beginSnapshot(m, now);
    await store.stagePage(
      page(
        m,
        records: [
          ShadowRecord(
            entity: task,
            fields: {
              'existence': AcceptedField(1, true),
              'milestone_order': AcceptedField(7, order([id(3), id(4)])),
            },
          ),
          child(a),
          child(b),
        ],
      ),
      now,
    );
    await store.installSnapshot(now);
    expect(await store.visibleMilestoneOrder(task), [id(3), id(4)]);
    expect(
      (await store.projection(task)).proposals.single.operation.payloadIdentity,
      original,
    );
  });
}
