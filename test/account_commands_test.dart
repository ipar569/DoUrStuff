import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart' hide AccountOperation;
import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';

import 'account_store_test.dart' show id, now, at, task, manifest, page;

Map<String, FieldPatch> createFields([String title = 'Local task']) => {
  'title': FieldPatch(const AbsentBase(), title),
  'priority': FieldPatch(const AbsentBase(), 'none'),
  'status_group': FieldPatch(const AbsentBase(), {
    'status': 'todo',
    'completed_at': null,
  }),
  'existence': FieldPatch(const AbsentBase(), true),
};

void main() {
  late Directory dir;
  late AppDatabase db;
  late AccountStore store;
  late String device;
  final child = SyncEntity(SyncEntityKind.milestone, [id(3)]);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('account-commands-');
    db = AppDatabase.file(File('${dir.path}/profile.sqlite'));
    await db.initializeProfile('account-${id(1)}');
    device =
        (await db
                .customSelect('SELECT device_epoch FROM profile_metadata')
                .getSingle())
            .read<String>('device_epoch');
    store = await AccountStore.open(db, id(1));
    final m = manifest(count: 0);
    await store.beginSnapshot(m, now);
    await store.stagePage(page(m, records: []), now);
    await store.installSnapshot(now);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  Future<int> count(String table) async =>
      (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
          .read<int>('n');
  Future<int> next() async =>
      (await db
              .customSelect('SELECT next_sequence FROM profile_metadata')
              .getSingle())
          .read<int>('next_sequence');
  Future<AccountOperation> create({int op = 10, String title = 'Local task'}) =>
      store.commitCommand(
        operationId: id(op),
        entity: task,
        command: 'task.create',
        patches: createFields(title),
        occurredAtUtc: now,
      );
  Future<AccountOperation> milestone(
    AccountOperation parent, {
    int? dependencySequence,
    String? dependencyId,
  }) => store.commitCommand(
    operationId: id(11),
    entity: child,
    command: 'milestone.create',
    occurredAtUtc: now,
    patches: {
      'title': FieldPatch(const AbsentBase(), 'Step'),
      'completion': FieldPatch(const AbsentBase(), null),
      'existence': FieldPatch(const AbsentBase(), true),
      'parent': FieldPatch(const AbsentBase(), task.key.single),
    },
    dependencies: [
      OperationDependency(
        entity: task,
        operationId: dependencyId ?? parent.operationId,
        sequence: dependencySequence ?? parent.sequence,
      ),
    ],
  );
  Future<void> acknowledge(AccountOperation op, {bool conflict = false}) =>
      store.retainApplyResult(
        ApplyRequest(cursor: at, operations: [op]),
        ApplyResult(
          cursor: (serverEpoch: id(99), revision: 6),
          deviceHighWater: op.sequence,
          results: [
            OperationReceipt(
              operationId: op.operationId,
              sequence: op.sequence,
              revision: 6,
              disposition: conflict
                  ? ReceiptDisposition.conflict
                  : ReceiptDisposition.applied,
              fields: [
                for (final p in op.patches.entries)
                  FieldOutcome(
                    group: p.key,
                    disposition: conflict
                        ? FieldDisposition.conflict
                        : FieldDisposition.applied,
                    accepted: conflict ? null : AcceptedField(6, p.value.value),
                    recoveryId: conflict
                        ? id(100 + op.patches.keys.toList().indexOf(p.key))
                        : null,
                  ),
              ],
            ),
          ],
        ),
      );
  Future<void> download(List<ShadowRecord> records) => store.applyPull(
    PullRequest(at),
    RecoveryPullResult(
      HistoryPullResult(
        through: (serverEpoch: id(99), revision: 6),
        committedHighWater: 6,
        hasMore: false,
        groups: [
          HistoryRevisionGroup(
            RevisionGroup(revision: 6, records: records, recovery: []),
            [],
          ),
        ],
      ),
      [[]],
    ),
  );

  test('complete task and dependent child survive reopen with atomic history and dirty intent', () async {
    final parent = await create();
    final step = await milestone(parent);
    expect(step.sequence, 2);
    expect((await store.projection(task)).visible, isTrue);
    expect((await store.projection(child)).visible, isTrue);
    expect(await count('account_command_history'), 2);
    expect(await count('account_notification_dirty'), 2);
    expect(await count('tasks'), 0);
    expect(await count('history'), 0);
    final original =
        (await db
                .customSelect(
                  'SELECT envelope_json FROM account_operations ORDER BY sequence',
                )
                .get())
            .map((r) => r.read<String>('envelope_json'))
            .toList();
    await db.close();
    db = AppDatabase.file(File('${dir.path}/profile.sqlite'));
    await db.initializeProfile('account-${id(1)}');
    store = await AccountStore.open(db, id(1));
    expect((await store.projection(child)).values['title'], 'Step');
    expect(
      (await db
              .customSelect(
                'SELECT envelope_json FROM account_operations ORDER BY sequence',
              )
              .get())
          .map((r) => r.read<String>('envelope_json')),
      original,
    );
    expect(await next(), 3);
  });

  test(
    'command retries are idempotent and changed intent cannot reuse UUID',
    () async {
      final first = await create();
      expect((await create()).payloadIdentity, first.payloadIdentity);
      await expectLater(create(title: 'different'), throwsStateError);
      expect(await next(), 2);
      expect(await count('account_command_history'), 1);
      expect(
        (await db
                .customSelect(
                  'SELECT generation FROM account_notification_dirty',
                )
                .getSingle())
            .read<int>('generation'),
        1,
      );
    },
  );

  for (final table in [
    'account_command_history',
    'account_notification_dirty',
  ]) {
    test(
      'failure at $table rolls back envelope original identity sequence and projection',
      () async {
        await db.customStatement(
          "CREATE TRIGGER injected BEFORE INSERT ON $table BEGIN SELECT RAISE(ABORT,'injected'); END",
        );
        await expectLater(create(), throwsA(anything));
        for (final name in [
          'account_operations',
          'account_originals',
          'account_command_history',
          'account_notification_dirty',
        ]) {
          expect(await count(name), 0, reason: name);
        }
        expect(await next(), 1);
        expect((await store.projection(task)).values, isEmpty);
        await db.customStatement('DROP TRIGGER injected');
        expect((await create()).sequence, 1);
      },
    );
  }

  test(
    'invalid complete creates reject before allocating any durable identity',
    () async {
      for (final fields in [
        {'title': FieldPatch(const AbsentBase(), 'Incomplete')},
        {
          ...createFields(),
          'priority': FieldPatch(const AbsentBase(), 'urgent'),
        },
        {
          ...createFields(),
          'title': FieldPatch(const AbsentBase(), 'NUL\u0000'),
        },
        {...createFields(), 'title': FieldPatch(ObservedBase(1, 'old'), 'new')},
        {
          ...createFields(),
          'due': FieldPatch(const AbsentBase(), {'kind': 'bad'}),
        },
      ]) {
        await expectLater(
          store.commitCommand(
            operationId: id(10),
            entity: task,
            command: 'task.create',
            patches: fields,
            occurredAtUtc: now,
          ),
          throwsFormatException,
        );
      }
      expect(await next(), 1);
      expect(await count('account_originals'), 0);
    },
  );

  test('collision holds the entire create and leaves original accepted fields intact', () async {
    await download([
      ShadowRecord(
        entity: task,
        fields: {
          'title': AcceptedField(6, 'Remote'),
          'existence': AcceptedField(6, true),
        },
      ),
    ]);
    final op = await create();
    final projected = await store.projection(task);
    expect(projected.values, {'title': 'Remote', 'existence': true});
    expect(
      projected.proposals.single.operation.payloadIdentity,
      op.payloadIdentity,
    );
    expect(
      projected.proposals.single.projectedOutcomes.values,
      everyElement(FieldDisposition.conflict),
    );
    expect(await count('account_command_history'), 1);
  });

  test('a second pending create cannot partially overlay the first', () async {
    await create();
    await create(op: 12, title: 'Collision');
    expect((await store.projection(task)).values['title'], 'Local task');
    expect(
      (await store.projection(task)).proposals.last.projectedOutcomes.values,
      everyElement(FieldDisposition.conflict),
    );
  });

  test('receipt binds a dependent child before pull without changing original bytes', () async {
    final parent = await create();
    final step = await milestone(parent);
    await acknowledge(parent);
    expect((await store.projection(child)).visible, isTrue);
    expect(await store.checkpoint(), at);
    await download([
      ShadowRecord(
        entity: task,
        fields: {
          for (final p in parent.patches.entries)
            p.key: AcceptedField(6, p.value.value),
        },
      ),
    ]);
    expect((await store.projection(child)).visible, isTrue);
    expect(
      (await store.projection(child))
          .proposals
          .single
          .operation
          .payloadIdentity,
      step.payloadIdentity,
    );
  });

  test(
    'parent conflict holds all child groups while unrelated commands progress',
    () async {
      final parent = await create();
      await milestone(parent);
      await acknowledge(parent, conflict: true);
      final projected = await store.projection(child);
      expect(projected.values, isEmpty);
      expect(
        projected.proposals.single.projectedOutcomes.values,
        everyElement(FieldDisposition.held),
      );
      final other = SyncEntity(SyncEntityKind.task, [id(4)]);
      await store.commitCommand(
        operationId: id(12),
        entity: other,
        command: 'task.create',
        patches: createFields('Unrelated'),
        occurredAtUtc: now,
      );
      expect((await store.projection(other)).visible, isTrue);
      expect(await next(), 4);
    },
  );

  test(
    'unknown parent dependency cannot bind through a visible UUID',
    () async {
      final parent = await create();
      await milestone(parent, dependencyId: id(999));
      expect((await store.projection(child)).values, isEmpty);
      expect(
        (await store.projection(child))
            .proposals
            .single
            .projectedOutcomes
            .values,
        everyElement(FieldDisposition.recovery),
      );
    },
  );

  test(
    'expired receipt suppresses dependency without fabricating acceptance',
    () async {
      final parent = await create();
      await milestone(parent);
      await store.retainApplyResult(
        ApplyRequest(cursor: at, operations: [parent]),
        ApplyResult(
          cursor: (serverEpoch: id(99), revision: 6),
          deviceHighWater: 1,
          results: [AlreadyProcessed(parent.operationId, 1)],
        ),
      );
      expect((await store.projection(child)).values, isEmpty);
      expect(
        (await store.projection(task)).proposals.single.needsReconciliation,
        isTrue,
      );
    },
  );

  test('same-field local successors bind receipt and preserve original predecessor', () async {
    final parent = await create();
    final edit = await store.commitCommand(
      operationId: id(12),
      entity: task,
      command: 'task.edit',
      patches: {
        'title': FieldPatch(
          PredecessorBase(parent.operationId, 1, 'Local task'),
          'Edited',
        ),
      },
      occurredAtUtc: now,
    );
    expect((await store.projection(task)).values['title'], 'Edited');
    await acknowledge(parent);
    expect((await store.projection(task)).values['title'], 'Edited');
    await download([
      ShadowRecord(
        entity: task,
        fields: {
          for (final p in parent.patches.entries)
            p.key: AcceptedField(6, p.value.value),
        },
      ),
    ]);
    expect((await store.projection(task)).values['title'], 'Edited');
    expect(
      (await store.projection(task)).proposals.last.operation.payloadIdentity,
      edit.payloadIdentity,
    );
  });

  test(
    'local parent delete suppresses child edit and dirty intent covers parent',
    () async {
      final parent = await create();
      final step = await milestone(parent);
      await store.commitCommand(
        operationId: id(12),
        entity: task,
        command: 'task.delete',
        patches: {
          'existence': FieldPatch(
            PredecessorBase(parent.operationId, 1, true),
            false,
          ),
        },
        occurredAtUtc: now,
      );
      await store.commitCommand(
        operationId: id(13),
        entity: child,
        command: 'milestone.edit',
        patches: {
          'title': FieldPatch(
            PredecessorBase(step.operationId, 2, 'Step'),
            'Hidden edit',
          ),
        },
        occurredAtUtc: now,
      );
      final projection = await store.projection(child);
      expect(projection.visible, isFalse);
      expect(
        projection.proposals.last.projectedOutcomes['title'],
        FieldDisposition.recovery,
      );
      expect(await count('account_command_history'), 4);
      expect(
        (await db
                .customSelect(
                  'SELECT max(generation) AS n FROM account_notification_dirty',
                )
                .getSingle())
            .read<int>('n'),
        4,
      );
    },
  );

  test(
    'stale generations and recovery latch cannot allocate a command',
    () async {
      final old = store;
      store = await AccountStore.open(db, id(1));
      await expectLater(
        old.commitCommand(
          operationId: id(10),
          entity: task,
          command: 'task.create',
          patches: createFields(),
          occurredAtUtc: now,
        ),
        throwsStateError,
      );
      await db.customStatement('UPDATE account_state SET requires_recovery=1');
      await expectLater(create(), throwsStateError);
      expect(await next(), 1);
      expect(await count('account_command_history'), 0);
    },
  );

  test(
    'malformed retained whole create never leaks individual fields',
    () async {
      final op = AccountOperation(
        operationId: id(10),
        deviceEpoch: device,
        sequence: 1,
        entity: task,
        command: 'task.create',
        patches: {
          'existence': FieldPatch(const AbsentBase(), true),
          'title': FieldPatch(const AbsentBase(), 'Incomplete'),
        },
      );
      await store.retainOperation(jsonEncode(op.toJson()));
      expect((await store.projection(task)).values, isEmpty);
      expect((await store.projection(task)).visible, isFalse);
    },
  );

  test('observed bases bind accepted receipts while pull is behind', () async {
    final parent = await create();
    await acknowledge(parent);
    await store.commitCommand(
      operationId: id(12),
      entity: task,
      command: 'task.edit',
      patches: {
        'title': FieldPatch(ObservedBase(6, 'Local task'), 'From receipt'),
      },
      occurredAtUtc: now,
    );
    expect((await store.projection(task)).values['title'], 'From receipt');
    expect(await store.checkpoint(), at);
  });

  test(
    'independent original bases cannot overwrite an earlier pending field',
    () async {
      await download([
        ShadowRecord(
          entity: task,
          fields: {
            'existence': AcceptedField(6, true),
            'title': AcceptedField(6, 'Server'),
          },
        ),
      ]);
      for (final n in [10, 11]) {
        await store.commitCommand(
          operationId: id(n),
          entity: task,
          command: 'task.edit',
          patches: {'title': FieldPatch(ObservedBase(6, 'Server'), 'Edit $n')},
          occurredAtUtc: now,
        );
      }
      final result = await store.projection(task);
      expect(result.values['title'], 'Edit 10');
      expect(
        result.proposals.last.projectedOutcomes['title'],
        FieldDisposition.conflict,
      );
    },
  );

  test('independent child deletion projects even beneath a pending parent deletion', () async {
    final parent = await create();
    final step = await milestone(parent);
    await store.commitCommand(
      operationId: id(12),
      entity: task,
      command: 'task.delete',
      patches: {
        'existence': FieldPatch(
          PredecessorBase(parent.operationId, 1, true),
          false,
        ),
      },
      occurredAtUtc: now,
    );
    await store.commitCommand(
      operationId: id(13),
      entity: child,
      command: 'milestone.delete',
      patches: {
        'existence': FieldPatch(
          PredecessorBase(step.operationId, 2, true),
          false,
        ),
      },
      occurredAtUtc: now,
    );
    final result = await store.projection(child);
    expect(result.values['existence'], false);
    expect(
      result.proposals.last.projectedOutcomes['existence'],
      FieldDisposition.applied,
    );
  });

  test(
    'older accepted predecessor cannot overwrite an intervening pending edit',
    () async {
      final parent = await create();
      await acknowledge(parent);
      for (final n in [12, 13]) {
        await store.commitCommand(
          operationId: id(n),
          entity: task,
          command: 'task.edit',
          patches: {
            'title': FieldPatch(
              PredecessorBase(parent.operationId, 1, 'Local task'),
              'Edit $n',
            ),
          },
          occurredAtUtc: now,
        );
      }
      final result = await store.projection(task);
      expect(result.values['title'], 'Edit 12');
      expect(
        result.proposals.last.projectedOutcomes['title'],
        FieldDisposition.conflict,
      );
    },
  );

  test('pending milestone edits retain their validated parent chain', () async {
    final parent = await create();
    final step = await milestone(parent);
    await store.commitCommand(
      operationId: id(12),
      entity: child,
      command: 'milestone.edit',
      patches: {
        'title': FieldPatch(
          PredecessorBase(step.operationId, 2, 'Step'),
          'Edit',
        ),
      },
      occurredAtUtc: now,
    );
    expect((await store.projection(child)).values['title'], 'Edit');
  });

  test('literal escapes survive while unpaired Unicode is rejected without truncation', () async {
    await create(title: r'Literal \u0000');
    expect((await store.projection(task)).values['title'], r'Literal \u0000');
    await expectLater(
      create(op: 12, title: String.fromCharCode(0xd800)),
      throwsFormatException,
    );
    expect(await next(), 2);
  });
}
