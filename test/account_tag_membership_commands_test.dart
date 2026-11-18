import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart' hide AccountOperation;
import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:dourstuff/domain/tag_normalization.dart';

import 'account_commands_test.dart' show createFields;
import 'account_store_test.dart' show id, now, at, task, manifest, page;

void main() {
  late Directory dir;
  late AppDatabase db;
  late AccountStore store;
  var serial = 10;
  final a = SyncEntity(SyncEntityKind.tag, [id(3)]);
  final b = SyncEntity(SyncEntityKind.tag, [id(4)]);
  SyncEntity pair(SyncEntity tag) =>
      SyncEntity(SyncEntityKind.membership, [task.key.single, tag.key.single]);
  Map<String, String> name(String s) => {
    'name': s,
    'normalized_name': normalizedTagName(s),
  };
  FieldPatch absent(Object? v) => FieldPatch(const AbsentBase(), v);
  PredecessorBase base(AccountOperation op, String group) =>
      PredecessorBase(op.operationId, op.sequence, op.patches[group]!.value);
  OperationDependency dep(AccountOperation op) => OperationDependency(
    entity: op.entity,
    operationId: op.operationId,
    sequence: op.sequence,
  );
  Future<AccountOperation> commit(
    String command,
    SyncEntity entity,
    Map<String, FieldPatch> patches, [
    List<OperationDependency> dependencies = const [],
  ]) => store.commitCommand(
    operationId: id(serial++),
    entity: entity,
    command: command,
    patches: patches,
    dependencies: dependencies,
    occurredAtUtc: now,
  );
  Future<AccountOperation> tag(SyncEntity entity, String s) => commit(
    'tag.create',
    entity,
    {'existence': absent(true), 'name': absent(name(s))},
  );
  Future<AccountOperation> member(
    SyncEntity entity,
    bool value, {
    FieldBase base = const AbsentBase(),
    List<OperationDependency> deps = const [],
  }) => commit('task.tag', pair(entity), {
    'membership': FieldPatch(base, value),
  }, deps);
  Future<FieldDisposition> decision(AccountOperation op) async =>
      (await store.projection(op.entity)).proposals
          .singleWhere((p) => p.operation.operationId == op.operationId)
          .projectedOutcomes
          .values
          .first;
  Future<String> durable() async => jsonEncode({
    for (final table in [
      'profile_metadata',
      'account_operations',
      'account_originals',
      'account_command_history',
      'account_notification_dirty',
    ])
      table: (await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
          .map((r) => r.data)
          .toList(),
  });

  setUp(() async {
    serial = 10;
    dir = await Directory.systemTemp.createTemp('account-tags-');
    db = AppDatabase.file(File('${dir.path}/profile.sqlite'));
    await db.initializeProfile('account-${id(1)}');
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

  test('receipt values reserve names during pull lag and newer snapshots supersede them', () async {
    final g = await tag(a, 'Work');
    await store.retainApplyResult(
      ApplyRequest(cursor: at, operations: [g]),
      ApplyResult(
        cursor: (serverEpoch: id(99), revision: 6),
        deviceHighWater: 1,
        results: [
          OperationReceipt(
            operationId: g.operationId,
            sequence: 1,
            revision: 6,
            disposition: ReceiptDisposition.applied,
            fields: [
              for (final e in g.patches.entries)
                FieldOutcome(
                  group: e.key,
                  disposition: FieldDisposition.applied,
                  accepted: AcceptedField(6, e.value.value),
                ),
            ],
          ),
        ],
      ),
    );
    final loser = await tag(b, 'WORK');
    expect(await decision(loser), FieldDisposition.conflict);
    final changed = await commit('tag.edit', a, {
      'name': FieldPatch(ObservedBase(6, name('Work')), name('Renamed')),
    });
    expect(await decision(changed), FieldDisposition.applied);
    final m = manifest(token: 71, revision: 7);
    await store.beginSnapshot(m, now);
    await store.stagePage(
      page(
        m,
        records: [
          ShadowRecord(
            entity: a,
            fields: {
              'existence': AcceptedField(6, true),
              'name': AcceptedField(7, name('Remote')),
            },
          ),
        ],
      ),
      now,
    );
    await store.installSnapshot(now);
    expect((await store.projection(a)).values['name'], name('Remote'));
    expect(await decision(changed), FieldDisposition.conflict);
    expect(
      (await store.projection(a)).proposals.first.operation.payloadIdentity,
      g.payloadIdentity,
    );
  });

  for (final receipt in [true, false]) {
    test(
      'closed tag source uses retained receipt=$receipt for membership and same-field chains',
      () async {
        await commit('task.create', task, createFields('Task'));
        await tag(a, 'Work');
        final g = await tag(b, 'WORK');
        final groups = g.patches.keys.toList();
        final recovery = [
          for (var i = 0; i < groups.length; i++)
            RecoveryRecord(
              id: id(100 + i),
              revision: 6,
              operation: g,
              group: groups[i],
              disposition: FieldDisposition.conflict,
            ),
        ];
        if (receipt) {
          await store.retainApplyResult(
            ApplyRequest(cursor: at, operations: [g]),
            ApplyResult(
              cursor: (serverEpoch: id(99), revision: 6),
              deviceHighWater: g.sequence,
              results: [
                OperationReceipt(
                  operationId: g.operationId,
                  sequence: g.sequence,
                  revision: 6,
                  disposition: ReceiptDisposition.conflict,
                  fields: [
                    for (final r in recovery)
                      FieldOutcome(
                        group: r.group,
                        disposition: r.disposition,
                        recoveryId: r.id,
                      ),
                  ],
                ),
              ],
            ),
          );
        }
        await store.applyPull(
          PullRequest(at),
          RecoveryPullResult(
            HistoryPullResult(
              through: (serverEpoch: id(99), revision: 7),
              committedHighWater: 7,
              hasMore: false,
              groups: [
                HistoryRevisionGroup(
                  RevisionGroup(revision: 6, records: [], recovery: recovery),
                  [],
                ),
                HistoryRevisionGroup(
                  RevisionGroup(revision: 7, records: [], recovery: []),
                  [],
                ),
              ],
            ),
            [
              [],
              [
                for (final r in recovery)
                  RecoveryResolution(
                    conflictId: r.id,
                    expectedConflictRevision: 6,
                    revision: 7,
                    operationId: id(80),
                    deviceEpoch: id(81),
                    sequence: 1,
                    choice: RecoveryChoice.discard,
                  ),
              ],
            ],
          ),
        );
        final add = await member(b, true, deps: [dep(g)]);
        final rename = await commit('tag.edit', b, {
          'name': FieldPatch(base(g, 'name'), name('Free')),
        });
        expect(
          await decision(add),
          receipt ? FieldDisposition.held : FieldDisposition.recovery,
        );
        expect(
          await decision(rename),
          receipt ? FieldDisposition.held : FieldDisposition.recovery,
        );
        expect((await store.projection(b)).visible, isFalse);
      },
    );
  }

  test('tag and exact-pair intent survives reopen and retry without extra sequence/history/dirty writes', () async {
    final t = await commit('task.create', task, createFields('Task'));
    final g = await tag(a, 'Work');
    final add = await member(a, true, deps: [dep(t), dep(g)]);
    expect((await store.projection(pair(a))).visible, isTrue);
    final before = await durable();
    await db.close();
    db = AppDatabase.file(File('${dir.path}/profile.sqlite'));
    await db.initializeProfile('account-${id(1)}');
    store = await AccountStore.open(db, id(1));
    await store.commitCommand(
      operationId: add.operationId,
      entity: add.entity,
      command: add.command,
      patches: add.patches,
      dependencies: add.dependencies,
      occurredAtUtc: now,
    );
    expect(await durable(), before);
    expect((await store.projection(pair(a))).visible, isTrue);
    expect(
      (await db
              .customSelect(
                'SELECT generation FROM account_notification_dirty WHERE entity_key=\'${task.identity}\'',
              )
              .getSingle())
          .read<int>('generation'),
      2,
    );
    expect(await db.customSelect('SELECT * FROM task_tags').get(), isEmpty);
  });

  test('normalized-name collision is whole-create and never aliases dependent pairs', () async {
    final t = await commit('task.create', task, createFields('Task'));
    await tag(a, 'Work');
    final loser = await tag(b, 'WORK');
    final add = await member(b, true, deps: [dep(t), dep(loser)]);
    expect((await store.projection(b)).values, isEmpty);
    expect(
      (await store.projection(b)).proposals.single.projectedOutcomes.values,
      everyElement(FieldDisposition.conflict),
    );
    expect(await decision(add), FieldDisposition.held);
    expect((await store.projection(pair(a))).values, isEmpty);
    expect((await store.projection(pair(b))).visible, isFalse);
  });

  test(
    'freeing a name does not replay an earlier collision or held rename',
    () async {
      final first = await tag(a, 'Work');
      final loser = await tag(b, 'WORK');
      await commit('tag.delete', a, {
        'existence': FieldPatch(base(first, 'existence'), false),
      });
      final edit = await commit('tag.edit', b, {
        'name': FieldPatch(base(loser, 'name'), name('Free')),
      });
      expect(await decision(loser), FieldDisposition.conflict);
      expect(await decision(edit), FieldDisposition.held);
      final replacement = await tag(
        SyncEntity(SyncEntityKind.tag, [id(5)]),
        'Work',
      );
      expect(await decision(replacement), FieldDisposition.applied);
      expect((await store.projection(b)).values, isEmpty);
    },
  );

  test(
    'rename collision preserves complete name and stale causal edits conflict',
    () async {
      final first = await tag(a, 'Work');
      await tag(b, 'Home');
      final collision = await commit('tag.edit', a, {
        'name': FieldPatch(base(first, 'name'), name('HOME')),
      });
      expect(await decision(collision), FieldDisposition.conflict);
      expect((await store.projection(a)).values['name'], name('Work'));
      final changed = await commit('tag.edit', a, {
        'name': FieldPatch(base(first, 'name'), name('Other')),
      });
      expect(await decision(changed), FieldDisposition.applied);
      final stale = await commit('tag.edit', a, {
        'name': FieldPatch(base(first, 'name'), name('Stale')),
      });
      expect(await decision(stale), FieldDisposition.conflict);
    },
  );

  test('hidden parents suppress additions but preserve independent false removal and exact UUID', () async {
    final t = await commit('task.create', task, createFields('Task'));
    final g = await tag(a, 'Work');
    final add = await member(a, true, deps: [dep(t), dep(g)]);
    await commit('tag.delete', a, {
      'existence': FieldPatch(base(g, 'existence'), false),
    });
    final remove = await member(a, false, base: base(add, 'membership'));
    final readd = await member(a, true, base: base(remove, 'membership'));
    await tag(b, 'Work');
    expect(await decision(add), FieldDisposition.applied);
    expect(await decision(remove), FieldDisposition.applied);
    expect(await decision(readd), FieldDisposition.recovery);
    expect((await store.projection(pair(a))).values['membership'], false);
    expect((await store.projection(pair(a))).visible, isFalse);
    expect((await store.projection(pair(b))).values, isEmpty);
  });

  test(
    'missing evidence wins over held parent regardless of dependency order',
    () async {
      final t = await commit('task.create', task, createFields('Task'));
      await tag(a, 'Work');
      final loser = await tag(b, 'WORK');
      final missing = OperationDependency(
        entity: task,
        operationId: id(999),
        sequence: t.sequence,
      );
      for (final deps in [
        [missing, dep(loser)],
        [dep(loser), missing],
      ]) {
        expect(
          await decision(await member(b, true, deps: deps)),
          FieldDisposition.recovery,
        );
      }
    },
  );

  test('absent pair differs from accepted false and missing same-field proof needs recovery', () async {
    await commit('task.create', task, createFields('Task'));
    await tag(a, 'Work');
    final removed = await member(a, false);
    expect(await decision(removed), FieldDisposition.applied);
    final stale = await member(a, true);
    expect(await decision(stale), FieldDisposition.conflict);
    final missing = await member(
      a,
      true,
      base: PredecessorBase(id(999), 1, false),
    );
    expect(await decision(missing), FieldDisposition.recovery);
  });

  test(
    'invalid names, bases and duplicate/wrong dependencies consume nothing',
    () async {
      final t = await commit('task.create', task, createFields('Task'));
      await tag(a, 'Work');
      final before = await durable();
      for (final value in [
        name(' Work '),
        {'name': 'Work', 'normalized_name': 'wrong'},
        name(''),
        name('x' * 81),
        name('x\u0000'),
      ]) {
        await expectLater(
          commit('tag.edit', a, {'name': absent(value)}),
          throwsFormatException,
        );
      }
      await expectLater(
        member(a, true, base: ObservedBase(2, 'false')),
        throwsFormatException,
      );
      await expectLater(
        member(a, true, deps: [dep(t), dep(t)]),
        throwsFormatException,
      );
      await expectLater(
        member(
          b,
          true,
          deps: [
            OperationDependency(entity: a, operationId: id(11), sequence: 2),
          ],
        ),
        throwsFormatException,
      );
      expect(await durable(), before);
    },
  );

  test('history and dirty failures roll back the entire tag/membership transaction', () async {
    await commit('task.create', task, createFields('Task'));
    await tag(a, 'Work');
    for (final table in [
      'account_command_history',
      'account_notification_dirty',
    ]) {
      final before = await durable();
      await db.customStatement(
        "CREATE TRIGGER fail_intent BEFORE INSERT ON $table BEGIN SELECT RAISE(ABORT,'injected'); END",
      );
      await expectLater(member(a, true), throwsA(anything));
      expect(await durable(), before);
      await db.customStatement('DROP TRIGGER fail_intent');
    }
  });
}
