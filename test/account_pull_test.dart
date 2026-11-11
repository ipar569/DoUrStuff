import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart' hide AccountOperation;
import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';

import 'account_store_test.dart' show id, now, task, at, manifest, page;

void main() {
  late Directory dir;
  late AppDatabase db;
  late AccountStore store;
  late String device;
  ShadowRecord shadow({
    int revision = 2,
    String title = 'server',
    bool exists = true,
  }) => ShadowRecord(
    entity: task,
    fields: {
      'title': AcceptedField(revision, title),
      'existence': AcceptedField(revision, exists),
    },
    deleteOperationId: exists ? null : id(90),
  );
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('account-pull-');
    db = AppDatabase.file(File('${dir.path}/account.sqlite'));
    await db.initializeProfile('account-${id(1)}');
    device =
        (await db
                .customSelect('SELECT device_epoch FROM profile_metadata')
                .getSingle())
            .read<String>('device_epoch');
    store = await AccountStore.open(db, id(1));
    final m = manifest();
    await store.beginSnapshot(m, now);
    await store.stagePage(page(m, records: [shadow()]), now);
    await store.installSnapshot(now);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  AccountOperation op({
    int sequence = 1,
    String title = 'local',
    FieldBase? base,
  }) => AccountOperation(
    operationId: id(sequence + 10),
    deviceEpoch: device,
    sequence: sequence,
    entity: task,
    command: 'task.edit',
    patches: {'title': FieldPatch(base ?? ObservedBase(2, 'server'), title)},
  );
  RecoveryRecord candidate(AccountOperation operation, {int revision = 6}) =>
      RecoveryRecord(
        id: id(30),
        revision: revision,
        operation: operation,
        group: 'title',
        disposition: FieldDisposition.conflict,
        canonical: AcceptedField(2, 'server'),
      );
  RecoveryResolution closure({int revision = 7, int expected = 6}) =>
      RecoveryResolution(
        conflictId: id(30),
        expectedConflictRevision: expected,
        revision: revision,
        operationId: id(31),
        deviceEpoch: id(32),
        sequence: 1,
        choice: RecoveryChoice.discard,
      );
  RecoveryPullResult pull({
    int revision = 6,
    List<ShadowRecord> records = const [],
    List<RecoveryRecord> recovery = const [],
    List<StatusHistoryEvent> history = const [],
    List<RecoveryResolution> resolutions = const [],
    bool more = false,
  }) => RecoveryPullResult(
    HistoryPullResult(
      through: (serverEpoch: id(99), revision: revision),
      committedHighWater: more ? revision + 1 : revision,
      hasMore: more,
      groups: [
        HistoryRevisionGroup(
          RevisionGroup(
            revision: revision,
            records: records,
            recovery: recovery,
          ),
          history,
        ),
      ],
    ),
    [resolutions],
  );
  Future<int> count(String table) async =>
      (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
          .read<int>('n');
  Future<void> retain(AccountOperation operation) =>
      store.retainOperation(jsonEncode(operation.toJson()));
  Future<void> receipt(AccountOperation operation, {int revision = 6}) =>
      store.retainApplyResult(
        ApplyRequest(cursor: at, operations: [operation]),
        ApplyResult(
          cursor: (serverEpoch: id(99), revision: revision),
          deviceHighWater: operation.sequence,
          results: [
            OperationReceipt(
              operationId: operation.operationId,
              sequence: operation.sequence,
              revision: revision,
              disposition: ReceiptDisposition.applied,
              fields: [
                FieldOutcome(
                  group: 'title',
                  disposition: FieldDisposition.applied,
                  accepted: AcceptedField(
                    revision,
                    operation.patches['title']!.value,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  test('total page record bound rejects atomically', () async {
    final groups = List.generate(
      11,
      (n) => HistoryRevisionGroup(
        RevisionGroup(
          revision: n + 6,
          records: List.generate(
            n == 10 ? 1 : 1000,
            (i) => ShadowRecord(
              entity: SyncEntity(SyncEntityKind.tag, [id(1000 + n * 1000 + i)]),
              fields: {'existence': AcceptedField(n + 6, true)},
            ),
          ),
          recovery: [],
        ),
        [],
      ),
    );
    await expectLater(
      store.applyPull(
        PullRequest(at),
        RecoveryPullResult(
          HistoryPullResult(
            through: (serverEpoch: id(99), revision: 16),
            committedHighWater: 16,
            hasMore: false,
            groups: groups,
          ),
          List.generate(11, (_) => []),
        ),
      ),
      throwsStateError,
    );
    expect(await count('account_records'), 1);
    expect(await store.checkpoint(), at);
  });

  for (final kind in ['closure', 'original', 'history']) {
    test(
      'own-device $kind ahead of next sequence atomically latches recovery',
      () async {
        final original = op(sequence: 5);
        final status = AcceptedField(6, {
          'status': 'completed',
          'completed_at': 100,
        });
        final result = pull(
          recovery: kind == 'original' ? [candidate(original)] : [],
          history: kind == 'history'
              ? [
                  StatusHistoryEvent(
                    operationId: original.operationId,
                    taskId: task.key.single,
                    revision: 6,
                    previousStatus: null,
                    status: status,
                    fields: {'status_group': status},
                    provenance: {},
                    recordedAtUtc: now,
                    operation: AccountOperation(
                      operationId: original.operationId,
                      deviceEpoch: device,
                      sequence: 5,
                      entity: task,
                      command: 'task.status',
                      patches: {
                        'status_group': FieldPatch(
                          const AbsentBase(),
                          status.value,
                        ),
                      },
                    ),
                  ),
                ]
              : [],
          resolutions: kind == 'closure'
              ? [
                  RecoveryResolution(
                    conflictId: id(30),
                    expectedConflictRevision: 5,
                    revision: 6,
                    operationId: id(31),
                    deviceEpoch: device,
                    sequence: 5,
                    choice: RecoveryChoice.discard,
                  ),
                ]
              : [],
        );
        await db.customStatement(
          "CREATE TRIGGER fail_pull BEFORE UPDATE OF cursor ON account_state BEGIN SELECT RAISE(ABORT,'injected'); END",
        );
        await expectLater(
          store.applyPull(PullRequest(at), result),
          throwsA(anything),
        );
        expect(
          (await db
                  .customSelect('SELECT requires_recovery FROM account_state')
                  .getSingle())
              .read<int>('requires_recovery'),
          0,
        );
        expect(await store.checkpoint(), at);
        await db.customStatement('DROP TRIGGER fail_pull');
        await store.applyPull(PullRequest(at), result);
        expect(
          (await db
                  .customSelect('SELECT requires_recovery FROM account_state')
                  .getSingle())
              .read<int>('requires_recovery'),
          1,
        );
        expect(
          (await db
                  .customSelect('SELECT next_sequence FROM profile_metadata')
                  .getSingle())
              .read<int>('next_sequence'),
          1,
        );
        await expectLater(retain(op()), throwsStateError);
        await store.applyPull(
          PullRequest((await store.checkpoint())!),
          pull(revision: 7),
        );
        await expectLater(retain(op()), throwsStateError);
      },
    );
  }

  test('downloaded receipt cannot reintroduce compacted payload', () async {
    final operation = op();
    await retain(operation);
    await receipt(operation);
    await store.applyPull(
      PullRequest(at),
      pull(records: [shadow(revision: 6, title: 'local')]),
    );
    await store.applyPull(
      PullRequest((await store.checkpoint())!),
      pull(
        revision: 7,
        records: [shadow(revision: 7, title: 'local', exists: false)],
      ),
    );
    await store.applyPull(
      PullRequest((await store.checkpoint())!),
      pull(
        revision: 8,
        records: [
          ShadowRecord(
            entity: task,
            fields: {'existence': AcceptedField(7, false)},
            deleteOperationId: id(90),
          ),
        ],
      ),
    );
    final projected = await store.projection(task);
    expect(projected.values.containsKey('title'), isFalse);
    expect(projected.pendingSources, isEmpty);
    expect(projected.proposals.single.acceptedFields['title']!.value, 'local');
    expect(
      projected.proposals.single.operation.payloadIdentity,
      operation.payloadIdentity,
    );
  });

  test('inherited child compaction accepts deleted parent without changing child identity', () async {
    final child = SyncEntity(SyncEntityKind.milestone, [id(3)]);
    final retained = {
      'parent': AcceptedField(6, task.key.single),
      'existence': AcceptedField(6, true),
    };
    await store.applyPull(
      PullRequest(at),
      pull(
        records: [
          ShadowRecord(
            entity: child,
            fields: {
              ...retained,
              'title': AcceptedField(6, 'child'),
              'completion': AcceptedField(6, false),
            },
          ),
        ],
      ),
    );
    final before = (await store.checkpoint())!;
    final compact = ShadowRecord(entity: child, fields: retained);
    await expectLater(
      store.applyPull(
        PullRequest(before),
        pull(revision: 7, records: [compact]),
      ),
      throwsStateError,
    );
    expect(await store.checkpoint(), before);
    // Child first deliberately: a whole revision cannot depend on row order.
    await store.applyPull(
      PullRequest(before),
      pull(revision: 7, records: [compact, shadow(revision: 7, exists: false)]),
    );
    final projected = await store.projection(child);
    expect(projected.visible, isFalse);
    expect(projected.values, {'existence': true, 'parent': task.key.single});
    expect(projected.accepted!.deleteOperationId, isNull);
  });

  test(
    'known and unknown history survives; repeated event identity cannot change',
    () async {
      final status = AcceptedField(6, {'status': 'todo', 'completed_at': null});
      final event = StatusHistoryEvent(
        operationId: id(40),
        taskId: task.key.single,
        revision: 6,
        previousStatus: null,
        status: status,
        fields: {'status_group': status},
        provenance: {},
        recordedAtUtc: now,
        operation: null,
      );
      await store.applyPull(PullRequest(at), pull(history: [event]));
      final changed = StatusHistoryEvent(
        operationId: id(40),
        taskId: task.key.single,
        revision: 7,
        previousStatus: null,
        status: AcceptedField(7, status.value),
        fields: {'status_group': AcceptedField(7, status.value)},
        provenance: {},
        recordedAtUtc: now,
        operation: null,
      );
      await expectLater(
        store.applyPull(
          PullRequest((await store.checkpoint())!),
          pull(revision: 7, history: [changed]),
        ),
        throwsStateError,
      );
      expect(await count('account_records'), 2);
    },
  );

  test('closure decision device/sequence proof cannot be reassigned', () async {
    await store.applyPull(
      PullRequest(at),
      pull(resolutions: [closure(revision: 6, expected: 5)]),
    );
    final substituted = AccountOperation(
      operationId: id(33),
      deviceEpoch: id(32),
      sequence: 1,
      entity: task,
      command: 'task.edit',
      patches: {'title': FieldPatch(ObservedBase(2, 'server'), 'other')},
    );
    await expectLater(
      store.applyPull(
        PullRequest((await store.checkpoint())!),
        pull(
          revision: 7,
          recovery: [
            RecoveryRecord(
              id: id(34),
              revision: 7,
              operation: substituted,
              group: 'title',
              disposition: FieldDisposition.conflict,
            ),
          ],
        ),
      ),
      throwsStateError,
    );
    expect(await count('account_originals'), 0);
    expect((await store.checkpoint())!.revision, 6);
  });

  test(
    'invalid creates need recovery as whole commands, never merged fieldwise',
    () async {
      final create = AccountOperation(
        operationId: id(10),
        deviceEpoch: device,
        sequence: 1,
        entity: task,
        command: 'task.create',
        patches: {
          'existence': FieldPatch(const AbsentBase(), true),
          'description': FieldPatch(
            const AbsentBase(),
            'must not merge into another create',
          ),
        },
      );
      await retain(create);
      final projected = await store.projection(task);
      expect(projected.values.containsKey('description'), isFalse);
      expect(
        projected.proposals.single.projectedOutcomes.values.every(
          (d) => d == FieldDisposition.recovery,
        ),
        isTrue,
      );
    },
  );

  test('pull preserves exact local bytes, merges unrelated fields and survives reopen', () async {
    final original = '  ${jsonEncode(op().toJson())}\n';
    await store.retainOperation(original);
    await store.applyPull(
      PullRequest(at),
      pull(
        records: [
          ShadowRecord(
            entity: task,
            fields: {...shadow().fields, 'priority': AcceptedField(6, 'high')},
          ),
        ],
      ),
    );
    await db.close();
    db = AppDatabase.file(File('${dir.path}/account.sqlite'));
    store = await AccountStore.open(db, id(1));
    final projection = await store.projection(task);
    expect(projection.values['title'], 'local');
    expect(projection.values['priority'], 'high');
    expect(projection.accepted!.fields['title']!.value, 'server');
    expect(projection.pendingSources, {'title': op().operationId});
    expect(
      (await db
              .customSelect('SELECT envelope_json FROM account_operations')
              .getSingle())
          .read<String>('envelope_json'),
      original,
    );
    expect((await store.checkpoint())!.revision, 6);
  });

  test(
    'late cursor failure rolls back records, archives, proofs and entire page',
    () async {
      final operation = op();
      final result = pull(
        records: [shadow(revision: 6, title: 'download')],
        recovery: [candidate(operation)],
      );
      await db.customStatement(
        "CREATE TRIGGER fail_pull BEFORE UPDATE OF cursor ON account_state BEGIN SELECT RAISE(ABORT,'injected'); END",
      );
      await expectLater(
        store.applyPull(PullRequest(at), result),
        throwsA(anything),
      );
      expect(await store.checkpoint(), at);
      expect((await store.projection(task)).values['title'], 'server');
      expect(await count('account_originals'), 0);
      expect(await count('account_recovery_archive'), 0);
      await db.customStatement('DROP TRIGGER fail_pull');
      await store.applyPull(PullRequest(at), result);
      expect(await count('account_recovery_archive'), 1);
      await expectLater(
        store.applyPull(PullRequest(at), result),
        throwsStateError,
      );
      expect(await count('account_recovery_archive'), 1);
    },
  );

  test(
    'gaps, wrong epochs, stale leases and excessive request limits fail closed',
    () async {
      await expectLater(
        store.applyPull(PullRequest(at), pull(revision: 7)),
        throwsStateError,
      );
      await expectLater(
        store.applyPull(
          PullRequest((serverEpoch: id(98), revision: 5)),
          pull(),
        ),
        throwsFormatException,
      );
      await expectLater(
        store.applyPull(PullRequest(at, limit: 201), pull()),
        throwsFormatException,
      );
      final stale = store;
      store = await AccountStore.open(db, id(1));
      await expectLater(
        stale.applyPull(PullRequest(at), pull()),
        throwsStateError,
      );
      expect(await store.checkpoint(), at);
    },
  );

  test('empty committed revisions and terminal no-change replies advance only as specified', () async {
    await store.applyPull(PullRequest(at), pull(more: true));
    final cursor = (await store.checkpoint())!;
    await store.applyPull(PullRequest(cursor), pull(revision: 7));
    final empty = RecoveryPullResult(
      HistoryPullResult(
        through: (serverEpoch: id(99), revision: 7),
        committedHighWater: 7,
        hasMore: false,
        groups: [],
      ),
      [],
    );
    await store.applyPull(PullRequest((await store.checkpoint())!), empty);
    expect((await store.checkpoint())!.revision, 7);
  });

  test(
    'multi-revision page is atomic and never advances to unreturned high water',
    () async {
      final a = pull(records: [shadow(revision: 6, title: 'first')]);
      final b = pull(revision: 7, recovery: [candidate(op(), revision: 7)]);
      await store.applyPull(
        PullRequest(at),
        RecoveryPullResult(
          HistoryPullResult(
            through: b.changes.through,
            committedHighWater: 9,
            hasMore: true,
            groups: [...a.changes.groups, ...b.changes.groups],
          ),
          [[], []],
        ),
      );
      expect((await store.checkpoint())!.revision, 7);
      expect((await store.projection(task)).values['title'], 'first');
    },
  );

  test('conflict downloads suppress pending chains without changing originals or receipts', () async {
    final first = op();
    final next = op(
      sequence: 2,
      title: 'next',
      base: PredecessorBase(first.operationId, 1, 'local'),
    );
    await retain(first);
    await retain(next);
    expect((await store.projection(task)).values['title'], 'next');
    await store.applyPull(
      PullRequest(at),
      pull(
        records: [shadow(revision: 6, title: 'other')],
        recovery: [candidate(first)],
      ),
    );
    final projected = await store.projection(task);
    expect(projected.values['title'], 'other');
    expect(
      projected.proposals.first.projectedOutcomes['title'],
      FieldDisposition.conflict,
    );
    expect(
      projected.proposals.last.projectedOutcomes['title'],
      FieldDisposition.held,
    );
    expect(projected.proposals.map((p) => p.operation.payloadIdentity), [
      first.payloadIdentity,
      next.payloadIdentity,
    ]);
    expect(
      projected.proposals.every(
        (p) => p.outcomes.isEmpty && p.transportState == 'pending',
      ),
      isTrue,
    );
  });

  test(
    'closures preserve candidates and archives but stop local proposal replay',
    () async {
      final operation = op();
      await retain(operation);
      await store.applyPull(
        PullRequest(at),
        pull(recovery: [candidate(operation)]),
      );
      await store.applyPull(
        PullRequest((await store.checkpoint())!),
        pull(revision: 7, resolutions: [closure()]),
      );
      final projected = await store.projection(task);
      expect(projected.unresolvedRecovery, isEmpty);
      expect(projected.proposals.single.closedGroups, {'title'});
      expect(projected.values['title'], 'server');
      expect(await count('account_recovery_archive'), 1);
      expect(await count('account_operations'), 1);
      expect(await count('account_records'), 3);
    },
  );

  test(
    'closure version and original identity substitution roll back',
    () async {
      await store.applyPull(PullRequest(at), pull(recovery: [candidate(op())]));
      final before = (await store.checkpoint())!;
      await expectLater(
        store.applyPull(
          PullRequest(before),
          pull(revision: 7, resolutions: [closure(expected: 5)]),
        ),
        throwsStateError,
      );
      await expectLater(
        store.applyPull(
          PullRequest(before),
          pull(
            revision: 7,
            recovery: [candidate(op(title: 'substituted'), revision: 7)],
          ),
        ),
        throwsStateError,
      );
      expect(await store.checkpoint(), before);
      expect(await count('account_records'), 2);
    },
  );

  test('shadow revision substitution rejects but deleted-content compaction is valid', () async {
    await expectLater(
      store.applyPull(
        PullRequest(at),
        pull(records: [shadow(title: 'substituted')]),
      ),
      throwsStateError,
    );
    await store.applyPull(
      PullRequest(at),
      pull(records: [shadow(revision: 6, exists: false)]),
    );
    await store.applyPull(
      PullRequest((await store.checkpoint())!),
      pull(
        revision: 7,
        records: [
          ShadowRecord(
            entity: task,
            fields: {'existence': AcceptedField(6, false)},
            deleteOperationId: id(90),
          ),
        ],
      ),
    );
    expect((await store.projection(task)).values.keys, ['existence']);
    expect((await store.projection(task)).visible, isFalse);
  });

  test(
    'acknowledged values bridge pull lag then yield to newer canonical values',
    () async {
      final operation = op();
      await retain(operation);
      await receipt(operation);
      expect((await store.projection(task)).values['title'], 'local');
      await store.applyPull(
        PullRequest(at),
        pull(records: [shadow(revision: 6, title: 'local')]),
      );
      expect((await store.projection(task)).pendingSources, isEmpty);
      await store.applyPull(
        PullRequest((await store.checkpoint())!),
        pull(revision: 7, records: [shadow(revision: 7, title: 'newer')]),
      );
      expect((await store.projection(task)).values['title'], 'newer');
      expect(
        (await store.projection(task))
            .proposals
            .single
            .acceptedFields['title']!
            .value,
        'local',
      );
    },
  );

  test('lost receipts never become accepted from value equality', () async {
    final operation = op();
    await retain(operation);
    await store.retainApplyResult(
      ApplyRequest(cursor: at, operations: [operation]),
      ApplyResult(
        cursor: at,
        deviceHighWater: 1,
        results: [AlreadyProcessed(operation.operationId, 1)],
      ),
    );
    await store.applyPull(
      PullRequest(at),
      pull(records: [shadow(revision: 6, title: 'local')]),
    );
    final projected = await store.projection(task);
    expect(projected.pendingSources, isEmpty);
    expect(projected.proposals.single.needsReconciliation, isTrue);
    expect(
      projected.proposals.single.projectedOutcomes['title'],
      FieldDisposition.recovery,
    );
  });

  test(
    'snapshot staging survives pull but an older capture cannot overwrite it',
    () async {
      final m = manifest(token: 71);
      await store.beginSnapshot(m, now);
      await store.stagePage(page(m, records: [shadow()]), now);
      await store.applyPull(
        PullRequest(at),
        pull(records: [shadow(revision: 6, title: 'new')]),
      );
      await expectLater(store.installSnapshot(now), throwsStateError);
      expect(await store.nextSnapshotPage(), 1);
      expect((await store.projection(task)).values['title'], 'new');
    },
  );

  test('parent deletion hides milestones and exact memberships; restore retains child removal', () async {
    final child = SyncEntity(SyncEntityKind.milestone, [id(3)]);
    final tag = SyncEntity(SyncEntityKind.tag, [id(4)]);
    final membership = SyncEntity(SyncEntityKind.membership, [
      task.key.single,
      id(4),
    ]);
    await store.applyPull(
      PullRequest(at),
      pull(
        records: [
          ShadowRecord(
            entity: child,
            fields: {
              'parent': AcceptedField(6, task.key.single),
              'existence': AcceptedField(6, true),
            },
          ),
          ShadowRecord(
            entity: tag,
            fields: {'existence': AcceptedField(6, true)},
          ),
          ShadowRecord(
            entity: membership,
            fields: {'membership': AcceptedField(6, true)},
          ),
        ],
      ),
    );
    expect((await store.projection(child)).visible, isTrue);
    expect((await store.projection(membership)).visible, isTrue);
    await store.applyPull(
      PullRequest((await store.checkpoint())!),
      pull(revision: 7, records: [shadow(revision: 7, exists: false)]),
    );
    expect((await store.projection(child)).visible, isFalse);
    expect((await store.projection(membership)).visible, isFalse);
    await store.applyPull(
      PullRequest((await store.checkpoint())!),
      pull(
        revision: 8,
        records: [
          ShadowRecord(
            entity: task,
            fields: shadow(revision: 8).fields,
            deleteOperationId: id(90),
          ),
          ShadowRecord(
            entity: membership,
            fields: {'membership': AcceptedField(8, false)},
          ),
        ],
      ),
    );
    expect((await store.projection(child)).visible, isTrue);
    expect((await store.projection(membership)).visible, isFalse);
  });
}
