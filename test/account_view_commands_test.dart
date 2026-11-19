import 'dart:io';

import 'package:dourstuff/data/local/account_store.dart';
import 'package:dourstuff/data/local/database.dart' hide AccountOperation;
import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/query.dart';
import 'package:flutter_test/flutter_test.dart';

import 'account_store_test.dart' show id, now, manifest, page;

void main() {
  late Directory directory;
  late File file;
  late AppDatabase db;
  late AccountStore store;
  final view = SyncEntity(SyncEntityKind.view, [id(2)]);
  final pref = SyncEntity(SyncEntityKind.preference, ['default_view']);
  FieldPatch absent(Object? value) => FieldPatch(const AbsentBase(), value);
  final create = {
    'existence': absent(true),
    'name': absent('Work'),
    'query': absent(TaskQuery(search: 'Review').toJson()),
  };
  Future<AccountOperation> commit(
    int n,
    String command,
    SyncEntity entity,
    Map<String, FieldPatch> patches, [
    List<OperationDependency> deps = const [],
  ]) => store.commitCommand(
    operationId: id(n),
    command: command,
    entity: entity,
    patches: patches,
    dependencies: deps,
    occurredAtUtc: now,
  );
  OperationDependency dep(AccountOperation source) => OperationDependency(
    entity: source.entity,
    operationId: source.operationId,
    sequence: source.sequence,
  );
  Future<String> durable() async => canonicalSyncJson({
    for (final table in [
      'profile_metadata',
      'account_originals',
      'account_operations',
      'account_command_history',
      'account_notification_dirty',
    ])
      table: (await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
          .map((row) => row.data)
          .toList(),
  }, maxDepth: 32);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('account-views-');
    file = File('${directory.path}/profile.sqlite');
    db = AppDatabase.file(file);
    await db.initializeProfile('account-${id(1)}');
    store = await AccountStore.open(db, id(1));
    final m = manifest(count: 0);
    await store.beginSnapshot(m, now);
    await store.stagePage(page(m, records: []), now);
    await store.installSnapshot(now);
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  test(
    'invalid view and default commands preserve every durable write',
    () async {
      final source = await commit(10, 'view.create', view, create);
      final before = await durable();
      for (final patches in [
        {...create}..remove('query'),
        {...create, 'name': absent(' Work ')},
        {
          ...create,
          'query': absent({'search': 'Partial'}),
        },
        {...create, 'name': FieldPatch(ObservedBase(1, 'Old'), 'New')},
      ]) {
        await expectLater(
          commit(11, 'view.create', view, patches),
          throwsFormatException,
        );
      }
      for (final (command, patches) in [
        ('view.edit', {'existence': absent(true)}),
        ('view.delete', {'existence': absent(false)}),
        ('view.edit', {'name': absent('a\u0000b')}),
      ]) {
        await expectLater(
          commit(11, command, view, patches),
          throwsFormatException,
        );
      }
      for (final (value, deps) in [
        (null, [dep(source)]),
        (id(3), [dep(source)]),
        (id(2), [dep(source), dep(source)]),
        ('bad-id', <OperationDependency>[]),
      ]) {
        await expectLater(
          commit(11, 'preference.set', pref, {'value': absent(value)}, deps),
          throwsFormatException,
        );
      }
      expect(await durable(), before);
    },
  );

  test('selected view and implicit default clear roll back and retry together after reopen', () async {
    final source = await commit(10, 'view.create', view, create);
    await commit(
      11,
      'preference.set',
      pref,
      {'value': absent(view.key.single)},
      [dep(source)],
    );
    final deletion = {
      'existence': FieldPatch(
        PredecessorBase(source.operationId, 1, true),
        false,
      ),
    };
    final before = await durable();
    await db.customStatement(
      "CREATE TRIGGER fail_default BEFORE UPDATE ON account_notification_dirty "
      "WHEN json_extract(NEW.entity_key,'\$.kind')='preference' BEGIN SELECT RAISE(ABORT,'injected'); END",
    );
    await expectLater(
      commit(12, 'view.delete', view, deletion),
      throwsA(anything),
    );
    expect(await durable(), before);
    expect((await store.projection(pref)).values, {'value': id(2)});
    await db.customStatement('DROP TRIGGER fail_default');
    final removed = await commit(12, 'view.delete', view, deletion);
    final committed = await durable();
    await db.close();
    db = AppDatabase.file(file);
    store = await AccountStore.open(db, id(1));
    expect(
      (await commit(12, 'view.delete', view, deletion)).payloadIdentity,
      removed.payloadIdentity,
    );
    expect(await durable(), committed);
    final result = await store.projection(pref);
    expect(result.values, {'value': null});
    expect(result.proposals.single.operation.patches['value']!.value, id(2));
    expect(result.accepted, isNull);
    expect(result.pendingSources['value'], removed.operationId);
    expect((await store.projection(view)).visible, isFalse);
  });
}
