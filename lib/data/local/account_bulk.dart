import '../../domain/account_sync.dart';
import '../../domain/account_task_validation.dart';

/// One task as observed at selection time. The values in a FieldPatch are frozen.
final class BulkTaskTarget {
  BulkTaskTarget._(
    this.taskId,
    this.command,
    this.group,
    this.patch,
    this.restore,
  );

  factory BulkTaskTarget.delete(String taskId, FieldBase existence) =>
      BulkTaskTarget._(
        taskId,
        'task.delete',
        'existence',
        FieldPatch(existence, false),
        null,
      );

  factory BulkTaskTarget.status(
    String taskId,
    FieldBase before,
    Object? after,
  ) {
    if (!validAccountStatusGroup(baseValue(before)) ||
        !validAccountStatusGroup(after)) {
      throw const FormatException(
        'Bulk status needs both complete status groups.',
      );
    }
    return BulkTaskTarget._(
      taskId,
      'task.status',
      'status_group',
      FieldPatch(before, after),
      null,
    );
  }

  factory BulkTaskTarget.restore(String taskId, RestorePrecondition proof) =>
      BulkTaskTarget._(
        taskId,
        'task.restore',
        'existence',
        FieldPatch(ObservedBase(proof.revision, false), true),
        proof,
      );

  final String taskId, command, group;
  final FieldPatch patch;
  final RestorePrecondition? restore;

  static Object? baseValue(FieldBase base) => switch (base) {
    ObservedBase() => base.value,
    PredecessorBase() => base.value,
    AbsentBase() => null,
  };
}
