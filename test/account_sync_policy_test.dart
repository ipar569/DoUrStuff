import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_policy.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:dourstuff/domain/query.dart';
import 'package:flutter_test/flutter_test.dart';

String id(int n) => '00000000-0000-0000-0000-${n.toString().padLeft(12, '0')}';

void main() {
  final task = SyncEntity(SyncEntityKind.task, [id(20)]);
  final parent = AccountOperation(
    operationId: id(1),
    deviceEpoch: id(10),
    sequence: 1,
    entity: task,
    command: 'task.create',
    patches: {'existence': FieldPatch(const AbsentBase(), true)},
  );
  final dependency = OperationDependency(
    entity: task,
    operationId: id(1),
    sequence: 1,
  );
  final child = AccountOperation(
    operationId: id(2),
    deviceEpoch: id(10),
    sequence: 2,
    entity: SyncEntity(SyncEntityKind.membership, [id(20), id(30)]),
    command: 'task.tag',
    patches: {'membership': FieldPatch(const AbsentBase(), true)},
    dependencies: [dependency],
  );
  OperationReceipt receipt(FieldDisposition disposition) => OperationReceipt(
    operationId: id(1),
    sequence: 1,
    revision: 1,
    disposition: disposition == FieldDisposition.conflict
        ? ReceiptDisposition.conflict
        : ReceiptDisposition.applied,
    fields: [
      FieldOutcome(
        group: 'existence',
        disposition: disposition,
        accepted: disposition == FieldDisposition.applied
            ? AcceptedField(1, true)
            : null,
        recoveryId: disposition == FieldDisposition.applied ? null : id(60),
      ),
    ],
  );

  test('parent acceptance permits only exact same-owner causal references', () {
    ParentDisposition check({
      String? owner = 'X',
      AccountOperation? source,
      OperationReceipt? accepted,
      bool visible = true,
    }) => checkParentDependency(
      authenticatedOwner: 'X',
      parentOwner: owner,
      child: child,
      dependency: dependency,
      predecessor: source ?? parent,
      receipt: accepted ?? receipt(FieldDisposition.applied),
      parentVisible: visible,
    );
    expect(check(), ParentDisposition.ready);
    expect(check(owner: 'Y'), ParentDisposition.rejected);
    expect(check(owner: null), ParentDisposition.recovery);
    expect(check(visible: false), ParentDisposition.recovery);
    expect(
      check(accepted: receipt(FieldDisposition.conflict), visible: false),
      ParentDisposition.held,
    );
    final wrongParent = AccountOperation(
      operationId: id(1),
      deviceEpoch: id(11),
      sequence: 1,
      entity: task,
      command: 'task.create',
      patches: parent.patches,
    );
    expect(check(source: wrongParent), ParentDisposition.recovery);
    expect(
      checkParentDependency(
        authenticatedOwner: 'X',
        parentOwner: 'X',
        child: child,
        dependency: dependency,
        predecessor: parent,
        receipt: null,
        parentVisible: true,
      ),
      ParentDisposition.recovery,
    );
  });

  test('delete/edit in either arrival order keeps deleted visibility and recoverable content', () {
    for (final deleteFirst in [true, false]) {
      var deleted = false;
      var canonical = AcceptedField(1, 'Original');
      final edit = FieldPatch(ObservedBase(1, 'Original'), 'Edited offline');
      final candidates = <FieldPatch>[];
      if (deleteFirst) deleted = true;
      final decision = compareVisibleField(edit, canonical, isDeleted: deleted);
      if (decision == FieldDisposition.applied) {
        canonical = AcceptedField(2, edit.value);
      } else {
        candidates.add(edit);
      }
      deleted =
          true; // Delete never clears content; expiry is a separate policy.
      expect(deleted, isTrue);
      if (deleteFirst) {
        expect(decision, FieldDisposition.recovery);
        expect(candidates.single.value, 'Edited offline');
        expect((candidates.single.base as ObservedBase).value, 'Original');
      } else {
        expect(canonical.value, 'Edited offline');
      }
    }
  });

  test('restore wire requires exact deletion identity and cannot carry unrelated edits', () {
    final operation = AccountOperation(
      operationId: id(5),
      deviceEpoch: id(10),
      sequence: 5,
      entity: task,
      command: 'task.restore',
      restore: RestorePrecondition(id(4), 4),
      patches: {'existence': FieldPatch(ObservedBase(4, false), true)},
    );
    expect(
      decodeAccountOperation(operation.toJson()).payloadIdentity,
      operation.payloadIdentity,
    );
    expect(operation.toJson()['restore'], {
      'delete_operation_id': id(4),
      'revision': 4,
    });
    final deletedAt = DateTime.utc(2026, 9, 13);
    RestoreDisposition check({
      bool deleted = true,
      String? deletionId,
      int revision = 4,
      bool retained = true,
      DateTime? now,
    }) => checkRestore(
      operation: operation,
      isDeleted: deleted,
      deleteOperationId: deletionId ?? id(4),
      deletionRevision: revision,
      deletedAtUtc: deletedAt,
      serverNowUtc: now ?? deletedAt.add(const Duration(days: 29)),
      contentRetained: retained,
    );
    expect(check(), RestoreDisposition.allowed);
    expect(check(deleted: false), RestoreDisposition.staleDeletion);
    expect(check(deletionId: id(6)), RestoreDisposition.staleDeletion);
    expect(check(revision: 6), RestoreDisposition.staleDeletion);
    expect(check(retained: false), RestoreDisposition.contentExpired);
    expect(
      check(now: deletedAt.add(const Duration(days: 30))),
      RestoreDisposition.contentExpired,
    );
    final malformed = operation.toJson()..remove('restore');
    expect(() => decodeAccountOperation(malformed), throwsFormatException);
    final extra = AccountOperation(
      operationId: id(5),
      deviceEpoch: id(10),
      sequence: 5,
      entity: task,
      command: 'task.restore',
      restore: operation.restore,
      patches: {
        ...operation.patches,
        'title': FieldPatch(ObservedBase(1, 'Old'), 'New'),
      },
    );
    expect(
      checkRestore(
        operation: extra,
        isDeleted: true,
        deleteOperationId: id(4),
        deletionRevision: 4,
        deletedAtUtc: deletedAt,
        serverNowUtc: deletedAt,
        contentRetained: true,
      ),
      RestoreDisposition.invalidCommand,
    );
  });

  test('view deletion conditionally clears default and rejects stale/cross-owner selection', () {
    expect(defaultAfterViewDeletion(id(20), id(20)), isNull);
    expect(defaultAfterViewDeletion(id(30), id(20)), id(30));
    expect(defaultAfterViewDeletion(null, id(20)), isNull);
    expect(
      canSelectDefaultView(
        authenticatedOwner: 'X',
        requestedView: id(20),
        viewOwner: 'X',
        viewVisible: false,
      ),
      isFalse,
    );
    expect(
      canSelectDefaultView(
        authenticatedOwner: 'X',
        requestedView: id(20),
        viewOwner: 'Y',
        viewVisible: true,
      ),
      isFalse,
    );
    expect(
      canSelectDefaultView(
        authenticatedOwner: 'X',
        requestedView: null,
        viewOwner: null,
        viewVisible: false,
      ),
      isTrue,
    );
    expect(
      canSelectDefaultView(
        authenticatedOwner: 'X',
        requestedView: id(30),
        viewOwner: 'X',
        viewVisible: true,
      ),
      isTrue,
    );
  });

  test('normalized tag collisions preserve UUIDs and distinguish canonical Unicode forms', () {
    final tags = {id(20): 'Work', id(30): 'Café'};
    expect(
      hasTagNameCollision(
        tagId: id(40),
        proposedName: '  WORK\t',
        activeAccountTags: tags,
      ),
      isTrue,
    );
    expect(
      hasTagNameCollision(
        tagId: id(20),
        proposedName: 'work',
        activeAccountTags: tags,
      ),
      isFalse,
    );
    expect(
      hasTagNameCollision(
        tagId: id(40),
        proposedName: 'CAFÉ',
        activeAccountTags: tags,
      ),
      isTrue,
    );
    expect(
      hasTagNameCollision(
        tagId: id(40),
        proposedName: 'Cafe\u0301',
        activeAccountTags: tags,
      ),
      isFalse,
    );
    expect(normalized('  A\t B\n'), 'a b');
    expect(normalized('İ'), 'i');
    expect(tags, {id(20): 'Work', id(30): 'Café'});
  });

  test(
    'resolution races recheck recovery and current field without rebasing',
    () {
      final fixtures = jsonDecode(
        File('test/fixtures/account-protocol-v2-rpc.json').readAsStringSync(),
      );
      final page = (snapshotPageCodec.decodeReply(
        fixtures['snapshot_page']['reply'],
      ) as SyncSuccess<SnapshotPage>).value;
      final recovery = page.recovery.single;
      final request = resolveConflictCodec.decodeRequest(
        fixtures['resolve']['request'],
      );
      final identity = request.replacement.payloadIdentity;
      validateResolutionReply(
        request,
        (resolveConflictCodec.decodeReply(
          fixtures['resolve']['reply'],
        ) as SyncSuccess<ApplyResult>).value,
      );
      expect(
        checkResolution(
          currentRecovery: recovery,
          request: request,
          canonical: AcceptedField(2, 'Z'),
        ),
        ResolutionDisposition.allowed,
      );
      expect(
        checkResolution(
          currentRecovery: recovery,
          request: request,
          canonical: AcceptedField(6, 'New remote'),
        ),
        ResolutionDisposition.fieldChanged,
      );
      final resolved = RecoveryRecord(
        id: recovery.id,
        revision: 6,
        operation: recovery.operation,
        group: recovery.group,
        disposition: recovery.disposition,
        canonical: recovery.canonical,
      );
      expect(
        checkResolution(
          currentRecovery: resolved,
          request: request,
          canonical: AcceptedField(2, 'Z'),
        ),
        ResolutionDisposition.staleRecovery,
      );
      expect(request.replacement.payloadIdentity, identity);
      expect(
        (recovery.operation.patches['title']!.base as ObservedBase).value,
        'X',
      );
    },
  );
}
