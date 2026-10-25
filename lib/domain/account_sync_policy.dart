import 'account_sync.dart';
import 'account_sync_rpc.dart';
import 'account_task_validation.dart';
import 'tag_normalization.dart';

/// These pure decisions specify policy, not transactional server enforcement.
/// Owners, canonical state and server time must come from trusted server reads.
enum ParentDisposition { ready, held, recovery, rejected }

/// Reference policy for future account projection. The caller supplies only
/// visible same-parent children. Never rewrite the accepted order or its base.
List<String> projectMilestoneOrder(
  Object? acceptedOrder,
  Set<String> visibleChildIds,
) {
  if (acceptedOrder != null && !validAccountMilestoneOrder(acceptedOrder)) {
    throw const FormatException('Invalid milestone order.');
  }
  final ordered = acceptedOrder == null
      ? <String>[]
      : ((acceptedOrder as Map)['ordered_ids'] as List).cast<String>();
  final listed = ordered.toSet();
  return [
    ...ordered.where(visibleChildIds.contains),
    ...(visibleChildIds.difference(listed).toList()..sort()),
  ];
}

ParentDisposition checkParentDependency({
  required String authenticatedOwner,
  required String? parentOwner,
  required AccountOperation child,
  required OperationDependency dependency,
  required AccountOperation? predecessor,
  required OperationReceipt? receipt,
  required bool parentVisible,
}) {
  if (parentOwner != null && parentOwner != authenticatedOwner) {
    return ParentDisposition.rejected;
  }
  final parent = dependency.entity;
  final isParent = switch (child.entity.kind) {
    SyncEntityKind.membership =>
      (parent.kind == SyncEntityKind.task &&
              parent.key.single == child.entity.key[0]) ||
          (parent.kind == SyncEntityKind.tag &&
              parent.key.single == child.entity.key[1]),
    SyncEntityKind.milestone =>
      parent.kind == SyncEntityKind.task &&
          child.patches['parent']?.value == parent.key.single,
    _ => false,
  };
  if (!isParent) return ParentDisposition.recovery;
  if (predecessor == null ||
      receipt == null ||
      predecessor.deviceEpoch != child.deviceEpoch ||
      predecessor.operationId != dependency.operationId ||
      predecessor.sequence != dependency.sequence ||
      predecessor.sequence >= child.sequence ||
      predecessor.entity.identity != dependency.entity.identity ||
      receipt.operationId != predecessor.operationId ||
      receipt.sequence != predecessor.sequence) {
    return ParentDisposition.recovery;
  }
  final existence = receipt.fields
      .where((f) => f.group == 'existence')
      .toList();
  if (receipt.disposition == ReceiptDisposition.rejected ||
      existence.length != 1) {
    return ParentDisposition.recovery;
  }
  final result = existence.single;
  if (result.disposition == FieldDisposition.conflict ||
      result.disposition == FieldDisposition.held) {
    return ParentDisposition.held;
  }
  if ((result.disposition != FieldDisposition.applied &&
          result.disposition != FieldDisposition.equivalent) ||
      result.accepted?.value != true ||
      result.recoveryId != null ||
      parentOwner == null ||
      (!parentVisible &&
          !(child.command == 'task.tag' &&
              child.patches['membership']?.value == false))) {
    return ParentDisposition.recovery;
  }
  return ParentDisposition.ready;
}

/// Deletion dominates visibility even when a stale edit would otherwise merge.
/// Caller retains the entire immutable operation as a recovery candidate.
FieldDisposition compareVisibleField(
  FieldPatch patch,
  AcceptedField? current, {
  required bool isDeleted,
  AcceptedField? acceptedPredecessor,
  bool predecessorNeedsRecovery = false,
}) => isDeleted
    ? FieldDisposition.recovery
    : compareField(
        patch,
        current,
        acceptedPredecessor: acceptedPredecessor,
        predecessorNeedsRecovery: predecessorNeedsRecovery,
      );

enum RestoreDisposition {
  allowed,
  staleDeletion,
  contentExpired,
  invalidCommand,
}

RestoreDisposition checkRestore({
  required AccountOperation operation,
  required bool isDeleted,
  required String deleteOperationId,
  required int deletionRevision,
  required DateTime deletedAtUtc,
  required DateTime serverNowUtc,
  required bool contentRetained,
}) {
  if (!deletedAtUtc.isUtc ||
      !serverNowUtc.isUtc ||
      serverNowUtc.isBefore(deletedAtUtc)) {
    throw const FormatException('Expected valid server deletion time.');
  }
  final expected = operation.restore;
  final existence = operation.patches['existence'];
  if (operation.command != 'task.restore' ||
      expected == null ||
      operation.patches.length != 1 ||
      existence == null ||
      existence.value != true ||
      existence.base is! ObservedBase) {
    return RestoreDisposition.invalidCommand;
  }
  final base = existence.base as ObservedBase;
  if (base.value != false || base.revision != expected.revision) {
    return RestoreDisposition.invalidCommand;
  }
  if (!isDeleted ||
      expected.deleteOperationId != deleteOperationId ||
      expected.revision != deletionRevision) {
    return RestoreDisposition.staleDeletion;
  }
  if (!contentRetained ||
      !serverNowUtc.isBefore(deletedAtUtc.add(const Duration(days: 30)))) {
    return RestoreDisposition.contentExpired;
  }
  return RestoreDisposition.allowed;
}

/// Call inside the same revision/transaction as the view deletion.
String? defaultAfterViewDeletion(String? currentDefault, String deletedView) =>
    currentDefault == deletedView ? null : currentDefault;

bool canSelectDefaultView({
  required String authenticatedOwner,
  required String? requestedView,
  required String? viewOwner,
  required bool viewVisible,
}) => requestedView == null || (viewOwner == authenticatedOwner && viewVisible);

/// Compare frozen name keys without aliasing distinct tag identities.
bool hasTagNameCollision({
  required String tagId,
  required String proposedName,
  required Map<String, String> activeAccountTags,
}) {
  final key = normalizedTagName(proposedName);
  return activeAccountTags.entries.any(
    (e) => e.key != tagId && normalizedTagName(e.value) == key,
  );
}

enum ResolutionDisposition {
  allowed,
  staleRecovery,
  invalidReplacement,
  fieldChanged,
}

ResolutionDisposition checkResolution({
  required RecoveryRecord currentRecovery,
  required ResolveConflictRequest request,
  required AcceptedField? canonical,
}) {
  if (request.conflictId != currentRecovery.id ||
      request.expectedConflictRevision != currentRecovery.revision) {
    return ResolutionDisposition.staleRecovery;
  }
  final replacement = request.replacement;
  final original = currentRecovery.operation;
  final patch = replacement.patches[currentRecovery.group];
  if (replacement.operationId == original.operationId ||
      replacement.entity.identity != original.entity.identity ||
      replacement.patches.length != 1 ||
      patch == null ||
      patch.base is PredecessorBase ||
      replacement.dependencies.isNotEmpty ||
      (replacement.deviceEpoch == original.deviceEpoch &&
          replacement.sequence <= original.sequence)) {
    return ResolutionDisposition.invalidReplacement;
  }
  // Resolution requires an explicitly observed current value, including when
  // its proposed value happens to equal the current value. No implicit rebase.
  final base = patch.base;
  if (canonical == null) {
    return base is AbsentBase
        ? ResolutionDisposition.allowed
        : ResolutionDisposition.fieldChanged;
  }
  if (base is! ObservedBase ||
      base.revision != canonical.revision ||
      canonicalSyncJson(base.value) != canonicalSyncJson(canonical.value)) {
    return ResolutionDisposition.fieldChanged;
  }
  return ResolutionDisposition.allowed;
}
