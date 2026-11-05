import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart' hide AccountOperation;
import 'package:dourstuff/data/local/task_repository.dart';
import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';

String id(int n) => '00000000-0000-0000-0000-${n.toString().padLeft(12, '0')}';
final now = DateTime.utc(2026, 11, 4);
final task = SyncEntity(SyncEntityKind.task, [id(2)]);
final at = (serverEpoch: id(99), revision: 5);

SnapshotManifest manifest({
  int token = 70,
  int pages = 1,
  int count = 1,
  int revision = 5,
  int epoch = 99,
  Map<String, int> waters = const {},
}) => SnapshotManifest(
  token: id(token),
  at: (serverEpoch: id(epoch), revision: revision),
  expiresAtUtc: now.add(const Duration(hours: 24)),
  pageCount: pages,
  recordCount: count,
  deviceHighWaters: waters,
);
ShadowRecord shadow([SyncEntity? entity, String title = 'server']) =>
    ShadowRecord(
      entity: entity ?? task,
      fields: {'title': AcceptedField(2, title)},
    );
RecoverySnapshotPage page(
  SnapshotManifest m, {
  int number = 0,
  List<ShadowRecord>? records,
  List<RecoveryRecord> recovery = const [],
  List<StatusHistoryEvent> history = const [],
  List<RecoveryResolution> resolutions = const [],
}) => RecoverySnapshotPage(
  HistorySnapshotPage(
    SnapshotPage(
      token: m.token,
      at: m.at,
      page: number,
      isLast: number == m.pageCount - 1,
      records: records ?? [shadow()],
      recovery: recovery,
    ),
    history,
  ),
  resolutions,
);

void main() {
  late Directory dir;
  late AppDatabase db;
  late AccountStore store;
  late String device;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('account-store-');
    db = AppDatabase.file(File('${dir.path}/account.sqlite'));
    await db.initializeProfile('account-${id(1)}');
    device =
        (await db
                .customSelect('SELECT device_epoch FROM profile_metadata')
                .getSingle())
            .read<String>('device_epoch');
    store = await AccountStore.open(db, id(1));
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  Future<void> install(SnapshotManifest m, RecoverySnapshotPage p) async {
    await store.beginSnapshot(m, now);
    await store.stagePage(p, now);
    await store.installSnapshot(now);
  }

  AccountOperation operation({
    int sequence = 1,
    int operationId = 10,
    String title = 'local',
    FieldBase? base,
  }) => AccountOperation(
    operationId: id(operationId),
    deviceEpoch: device,
    sequence: sequence,
    entity: task,
    command: 'task.edit',
    patches: {'title': FieldPatch(base ?? ObservedBase(2, 'server'), title)},
  );
  Future<int> count(String table) async =>
      (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
          .read<int>('n');

  test('staging resumes after reopen; install preserves original pending bytes and bases', () async {
    final first = manifest();
    await install(first, page(first));
    final original = '  ${jsonEncode(operation().toJson())}  ';
    await store.retainOperation(original);
    final next = manifest(token: 71, pages: 2, count: 2, revision: 6);
    await store.beginSnapshot(next, now);
    await store.stagePage(
      page(next, records: [shadow(null, 'new server')]),
      now,
    );
    expect(
      (await store.projection(task)).accepted!.fields['title']!.value,
      'server',
    );
    await db.close();
    db = AppDatabase.file(File('${dir.path}/account.sqlite'));
    await db.initializeProfile('account-${id(1)}');
    store = await AccountStore.open(db, id(1));
    expect(await store.nextSnapshotPage(), 1);
    await store.stagePage(
      page(
        next,
        number: 1,
        records: [
          shadow(
            SyncEntity(SyncEntityKind.milestone, [id(2)]),
            'same UUID, other kind',
          ),
        ],
      ),
      now,
    );
    await store.installSnapshot(now);
    final projection = await store.projection(task);
    expect(projection.accepted!.fields['title']!.value, 'new server');
    expect(
      projection.proposals.single.operation.payloadIdentity,
      operation().payloadIdentity,
    );
    expect(
      (projection.proposals.single.operation.patches['title']!.base
              as ObservedBase)
          .value,
      'server',
    );
    expect(
      (await db
              .customSelect('SELECT envelope_json FROM account_operations')
              .getSingle())
          .read<String>('envelope_json'),
      original,
    );
    expect(await count('account_records'), 2);
    expect(await store.checkpoint(), next.at);
    expect(await store.nextSnapshotPage(), isNull);
  });

  test(
    'global duplicate, missing page, count, token and replay checks are atomic',
    () async {
      final m = manifest(pages: 2, count: 2);
      await store.beginSnapshot(m, now);
      await expectLater(
        store.stagePage(page(m, number: 1), now),
        throwsStateError,
      );
      await store.stagePage(page(m), now);
      await store.stagePage(page(m), now);
      await expectLater(
        store.stagePage(page(m, records: [shadow(null, 'changed')]), now),
        throwsStateError,
      );
      await expectLater(
        store.stagePage(page(m, number: 1), now),
        throwsA(anything),
      );
      await expectLater(store.installSnapshot(now), throwsStateError);
      expect(await store.nextSnapshotPage(), 1);
      expect((await store.stagedManifest())!.token, m.token);
      expect(await store.checkpoint(), isNull);
      final other = manifest(token: 71, pages: 2, count: 2);
      await expectLater(
        store.stagePage(page(other, number: 1), now),
        throwsFormatException,
      );
      final mismatch = manifest(token: 72, count: 2);
      await store.beginSnapshot(mismatch, now);
      await expectLater(store.stagePage(page(mismatch), now), throwsStateError);
      expect(await store.nextSnapshotPage(), 0);
    },
  );

  test(
    'expired staging restarts without touching accepted data or local work',
    () async {
      final initial = manifest();
      await install(initial, page(initial));
      await store.retainOperation(jsonEncode(operation().toJson()));
      final next = manifest(token: 71, revision: 6);
      await store.beginSnapshot(next, now);
      await store.stagePage(page(next), now);
      await expectLater(
        store.installSnapshot(next.expiresAtUtc),
        throwsFormatException,
      );
      expect(await store.checkpoint(), initial.at);
      final replacement = SnapshotManifest(
        token: id(72),
        at: next.at,
        expiresAtUtc: now.add(const Duration(days: 2)),
        pageCount: 1,
        recordCount: 0,
        deviceHighWaters: {},
      );
      await store.beginSnapshot(replacement, next.expiresAtUtc);
      expect(await count('account_operations'), 1);
      expect(await count('account_records'), 1);
      expect(await store.nextSnapshotPage(), 0);
    },
  );

  test('late install failure rolls back accepted rows, cursor and staging deletion', () async {
    final initial = manifest();
    await install(initial, page(initial));
    final next = manifest(token: 71, revision: 6);
    await store.beginSnapshot(next, now);
    await store.stagePage(page(next, records: [shadow(null, 'new')]), now);
    await db.customStatement(
      "CREATE TRIGGER fail_install BEFORE UPDATE OF cursor ON account_state BEGIN SELECT RAISE(ABORT,'injected'); END",
    );
    await expectLater(store.installSnapshot(now), throwsA(anything));
    expect(await store.checkpoint(), initial.at);
    expect(
      (await store.projection(task)).accepted!.fields['title']!.value,
      'server',
    );
    expect(await store.nextSnapshotPage(), 1);
    await db.customStatement('DROP TRIGGER fail_install');
    await store.installSnapshot(now);
    expect(await store.checkpoint(), next.at);
  });

  test('operation identity, sequence, profile and stale-generation guards fail closed', () async {
    final m = manifest();
    await install(m, page(m));
    await store.retainOperation(jsonEncode(operation().toJson()));
    await store.retainOperation(jsonEncode(operation().toJson()));
    await expectLater(
      store.retainOperation(jsonEncode(operation(title: 'mutated').toJson())),
      throwsStateError,
    );
    await expectLater(
      store.retainOperation(
        jsonEncode(operation(sequence: 3, operationId: 12).toJson()),
      ),
      throwsStateError,
    );
    await expectLater(AccountStore.open(db, id(3)), throwsStateError);
    final stale = store;
    store = await AccountStore.open(db, id(1));
    await expectLater(
      stale.beginSnapshot(manifest(token: 72), now),
      throwsStateError,
    );
    await expectLater(stale.projection(task), throwsStateError);
    await expectLater(
      LocalTaskRepository(db).createTask('still disabled'),
      throwsStateError,
    );
    expect(await count('outbox'), 0);
    expect(await count('tasks'), 0);
    expect(await count('account_operations'), 1);
  });

  test('partial receipts retain field outcomes and bases independently of transport', () async {
    final m = manifest();
    await install(m, page(m));
    final op = AccountOperation(
      operationId: id(10),
      deviceEpoch: device,
      sequence: 1,
      entity: task,
      command: 'task.edit',
      patches: {
        'title': FieldPatch(ObservedBase(2, 'server'), 'local'),
        'description': FieldPatch(const AbsentBase(), 'description'),
      },
    );
    await store.retainOperation(jsonEncode(op.toJson()));
    final request = ApplyRequest(cursor: at, operations: [op]);
    final result = ApplyResult(
      cursor: (serverEpoch: id(99), revision: 6),
      deviceHighWater: 1,
      results: [
        OperationReceipt(
          operationId: op.operationId,
          sequence: 1,
          revision: 6,
          disposition: ReceiptDisposition.partial,
          fields: [
            FieldOutcome(
              group: 'title',
              disposition: FieldDisposition.conflict,
              recoveryId: id(30),
            ),
            FieldOutcome(
              group: 'description',
              disposition: FieldDisposition.applied,
              accepted: AcceptedField(6, 'description'),
            ),
          ],
        ),
      ],
    );
    await store.retainApplyResult(request, result);
    await store.retainApplyResult(request, result);
    final proposal = (await store.projection(task)).proposals.single;
    expect(proposal.transportState, 'acknowledged');
    expect(proposal.outcomes, {'title': 'conflict', 'description': 'applied'});
    expect(await store.checkpoint(), at);
    expect(proposal.operation.payloadIdentity, op.payloadIdentity);
    final accepted =
        (await db
                .customSelect(
                  "SELECT accepted_json FROM account_field_outcomes WHERE field_group='description'",
                )
                .getSingle())
            .read<String>('accepted_json');
    expect(jsonDecode(accepted), {'revision': 6, 'value': 'description'});
    final compacted = manifest(
      token: 71,
      revision: 7,
      count: 1,
      waters: {device: 2},
    );
    await install(
      compacted,
      page(
        compacted,
        records: [],
        resolutions: [
          RecoveryResolution(
            conflictId: id(30),
            expectedConflictRevision: 6,
            revision: 7,
            operationId: id(41),
            deviceEpoch: device,
            sequence: 2,
            choice: RecoveryChoice.discard,
          ),
        ],
      ),
    );
    expect((await store.projection(task)).proposals.single.closedGroups, {
      'title',
    });
    expect(await count('account_recovery_archive'), 0);
  });

  test('lost receipt and epoch changes preserve originals and require reconciliation', () async {
    final m = manifest();
    await install(m, page(m));
    final op = operation();
    await store.retainOperation(jsonEncode(op.toJson()));
    await store.retainApplyResult(
      ApplyRequest(cursor: at, operations: [op]),
      ApplyResult(
        cursor: at,
        deviceHighWater: 1,
        results: [AlreadyProcessed(op.operationId, 1)],
      ),
    );
    expect(
      (await store.projection(task)).proposals.single.needsReconciliation,
      isTrue,
    );
    final restored = manifest(
      token: 71,
      epoch: 98,
      revision: 1,
      count: 0,
      waters: {device: 1},
    );
    await install(restored, page(restored, records: []));
    expect(
      (await store.projection(task)).proposals.single.operation.payloadIdentity,
      op.payloadIdentity,
    );
    await expectLater(
      store.retainApplyResult(
        ApplyRequest(cursor: at, operations: [op]),
        ApplyResult(
          cursor: at,
          deviceHighWater: 1,
          results: [AlreadyProcessed(op.operationId, 1)],
        ),
      ),
      throwsStateError,
    );
    expect(await count('account_operations'), 1);
  });

  test('snapshot retains hidden composite identities, held originals, history and closures', () async {
    final op = operation();
    final status = AcceptedField(3, {'status': 'todo', 'completed_at': null});
    final m = manifest(count: 6, waters: {device: 1});
    final p = page(
      m,
      records: [
        ShadowRecord(
          entity: task,
          fields: {'existence': AcceptedField(4, false)},
          deleteOperationId: id(60),
        ),
        ShadowRecord(
          entity: SyncEntity(SyncEntityKind.membership, [id(2), id(3)]),
          fields: {'membership': AcceptedField(4, false)},
        ),
        ShadowRecord(
          entity: SyncEntity(SyncEntityKind.membership, [id(3), id(2)]),
          fields: {'membership': AcceptedField(4, true)},
        ),
      ],
      recovery: [
        RecoveryRecord(
          id: id(30),
          revision: 3,
          operation: op,
          group: 'title',
          disposition: FieldDisposition.held,
          canonical: AcceptedField(2, 'server'),
        ),
      ],
      history: [
        StatusHistoryEvent(
          operationId: id(40),
          taskId: id(2),
          revision: 3,
          previousStatus: null,
          status: status,
          fields: {'status_group': status},
          provenance: {},
          recordedAtUtc: now,
          operation: null,
        ),
      ],
      resolutions: [
        RecoveryResolution(
          conflictId: id(31),
          expectedConflictRevision: 2,
          revision: 4,
          operationId: id(41),
          deviceEpoch: device,
          sequence: 2,
          choice: RecoveryChoice.discard,
        ),
      ],
    );
    await install(m, p);
    expect(await count('account_records'), 6);
    expect((await store.projection(task)).accepted!.deleteOperationId, id(60));
    final recovery = jsonDecode(
      (await db
              .customSelect(
                "SELECT record_json FROM account_records WHERE record_kind='recovery'",
              )
              .getSingle())
          .read<String>('record_json'),
    ) as Map;
    expect(recovery['operation'], op.toJson());
  });

  test('closure version mismatch cannot replace accepted state', () async {
    final m = manifest(count: 2);
    await store.beginSnapshot(m, now);
    await store.stagePage(
      page(
        m,
        records: [],
        recovery: [
          RecoveryRecord(
            id: id(30),
            revision: 3,
            operation: operation(),
            group: 'title',
            disposition: FieldDisposition.conflict,
          ),
        ],
        resolutions: [
          RecoveryResolution(
            conflictId: id(30),
            expectedConflictRevision: 2,
            revision: 4,
            operationId: id(41),
            deviceEpoch: device,
            sequence: 2,
            choice: RecoveryChoice.discard,
          ),
        ],
      ),
      now,
    );
    await expectLater(store.installSnapshot(now), throwsStateError);
    expect(await store.checkpoint(), isNull);
    expect(await count('account_snapshot_records'), 2);
  });

  test(
    'matching closure hides recovery without erasing original proposals',
    () async {
      final initial = manifest();
      await install(initial, page(initial));
      final op = operation();
      await store.retainOperation(jsonEncode(op.toJson()));
      final m = manifest(token: 71, count: 2, waters: {device: 2});
      await install(
        m,
        page(
          m,
          records: [],
          recovery: [
            RecoveryRecord(
              id: id(30),
              revision: 3,
              operation: op,
              group: 'title',
              disposition: FieldDisposition.conflict,
            ),
          ],
          resolutions: [
            RecoveryResolution(
              conflictId: id(30),
              expectedConflictRevision: 3,
              revision: 4,
              operationId: id(41),
              deviceEpoch: device,
              sequence: 2,
              choice: RecoveryChoice.discard,
            ),
          ],
        ),
      );
      final projection = await store.projection(task);
      expect(projection.unresolvedRecovery, isEmpty);
      await expectLater(
        store.beginSnapshot(manifest(token: 72, count: 0), now),
        throwsStateError,
      );
      expect(projection.proposals.single.closedGroups, {'title'});
      expect(
        projection.proposals.single.operation.payloadIdentity,
        op.payloadIdentity,
      );
      expect(await count('account_recovery_archive'), 1);
    },
  );

  test(
    'snapshot installation preserves new edits and historical recovery proofs',
    () async {
      final initial = manifest();
      await install(initial, page(initial));
      final op = operation();
      await store.retainOperation(jsonEncode(op.toJson()));
      final m = manifest(token: 71, count: 1, waters: {device: 1});
      await store.beginSnapshot(m, now);
      await store.stagePage(
        page(
          m,
          records: [],
          recovery: [
            RecoveryRecord(
              id: id(30),
              revision: 3,
              operation: op,
              group: 'title',
              disposition: FieldDisposition.held,
            ),
          ],
        ),
        now,
      );
      final successor = operation(
        sequence: 2,
        operationId: 11,
        base: PredecessorBase(op.operationId, 1, 'local'),
        title: 'successor',
      );
      await store.retainOperation(jsonEncode(successor.toJson()));
      await store.installSnapshot(now);
      expect(
        (await store.projection(task)).proposals
            .map((p) => p.operation.payloadIdentity),
        [op.payloadIdentity, successor.payloadIdentity],
      );
      expect(await count('account_recovery_archive'), 1);
      expect(
        (await store.projection(task))
            .unresolvedRecovery
            .single
            .operation
            .payloadIdentity,
        op.payloadIdentity,
      );
      final compacted = manifest(
        token: 72,
        count: 0,
        revision: 6,
        waters: {device: 1},
      );
      await install(compacted, page(compacted, records: []));
      expect(await count('account_records'), 0);
      expect(await count('account_recovery_archive'), 1);
      expect(await count('account_originals'), 2);
      final poisoned = manifest(
        token: 73,
        count: 1,
        revision: 7,
        waters: {device: 1},
      );
      await store.beginSnapshot(poisoned, now);
      await store.stagePage(
        page(
          poisoned,
          records: [],
          recovery: [
            RecoveryRecord(
              id: id(30),
              revision: 3,
              operation: operation(title: 'rewritten'),
              group: 'title',
              disposition: FieldDisposition.held,
            ),
          ],
        ),
        now,
      );
      await expectLater(store.installSnapshot(now), throwsStateError);
      expect(await store.checkpoint(), compacted.at);
      expect(await count('account_recovery_archive'), 1);
    },
  );

  test('server epoch replacement and lost local sequence require explicit recovery', () async {
    final initial = manifest();
    await install(initial, page(initial));
    final restored = manifest(token: 71, count: 0, epoch: 98, revision: 0);
    await install(restored, page(restored, records: []));
    await expectLater(
      store.retainOperation(jsonEncode(operation().toJson())),
      throwsStateError,
    );
    expect(await count('account_operations'), 0);
    final sameEpoch = manifest(
      token: 72,
      count: 0,
      epoch: 98,
      waters: {device: 4},
    );
    await install(sameEpoch, page(sameEpoch, records: []));
    expect(
      (await db
              .customSelect('SELECT next_sequence FROM profile_metadata')
              .getSingle())
          .read<int>('next_sequence'),
      1,
    );
    expect(
      (await db
              .customSelect('SELECT requires_recovery FROM account_state')
              .getSingle())
          .read<int>('requires_recovery'),
      1,
    );
  });

  test(
    'uninterpreted legacy rows prevent account initialization without deletion',
    () async {
      await db.customStatement('DELETE FROM account_state');
      await db.customStatement(
        "INSERT INTO sync_shadow VALUES('ambiguous','{}','{}',0)",
      );
      await expectLater(AccountStore.open(db, id(1)), throwsStateError);
      expect(await count('sync_shadow'), 1);
      expect(await count('account_state'), 0);
    },
  );

  test(
    'nested local transaction failure rolls back envelope and sequence',
    () async {
      final m = manifest();
      await install(m, page(m));
      await expectLater(
        db.transaction(() async {
          await store.retainOperation(jsonEncode(operation().toJson()));
          throw StateError('later local write failed');
        }),
        throwsStateError,
      );
      expect(await count('account_operations'), 0);
      await store.retainOperation(jsonEncode(operation().toJson()));
      expect(await count('account_operations'), 1);
    },
  );
}
