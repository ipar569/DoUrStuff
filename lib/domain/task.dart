import 'query.dart';

enum TaskPriority { none, low, medium, high }

enum TaskStatus { todo, inProgress, completed, cancelled }

extension TaskStatusLabel on TaskStatus {
  String get label => switch (this) {
    TaskStatus.todo => 'To do',
    TaskStatus.inProgress => 'In progress',
    TaskStatus.completed => 'Completed',
    TaskStatus.cancelled => 'Cancelled',
  };
  String get wire => this == TaskStatus.inProgress ? 'in_progress' : name;
  bool get isOpen => this == TaskStatus.todo || this == TaskStatus.inProgress;
}

/// A civil day, deliberately independent of UTC and the current device zone.
final class CivilDate {
  CivilDate(this.year, this.month, this.day) {
    final value = DateTime.utc(year, month, day);
    if (year < 1 ||
        year > 9999 ||
        value.year != year ||
        value.month != month ||
        value.day != day) {
      throw ArgumentError('Invalid calendar date');
    }
  }
  factory CivilDate.parse(String input) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) {
      throw const FormatException('Expected YYYY-MM-DD');
    }
    final p = input.split('-').map(int.parse).toList();
    return CivilDate(p[0], p[1], p[2]);
  }
  factory CivilDate.of(DateTime value) =>
      CivilDate(value.year, value.month, value.day);
  final int year, month, day;
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

final class Due {
  const Due.none() : date = null, instant = null, zone = null, wallTime = null;
  const Due.date(this.date) : instant = null, zone = null, wallTime = null;
  const Due.timed({
    required DateTime this.instant,
    required String this.zone,
    required String this.wallTime,
  }) : date = null;
  final CivilDate? date;
  final DateTime? instant;
  final String? zone, wallTime;
  String get kind => date != null
      ? 'date'
      : instant != null
      ? 'timed'
      : 'none';
  String? day(DateTime Function(DateTime) display) =>
      date?.toString() ??
      (instant == null ? null : CivilDate.of(display(instant!)).toString());
  Map<String, Object?> toJson() => {
    'kind': kind,
    if (date != null) 'date': date.toString(),
    if (instant != null) ...{
      'instant': instant!.millisecondsSinceEpoch,
      'zone': zone,
      'wall_time': wallTime,
    },
  };
}

final class Tag {
  const Tag(this.id, this.name);
  final String id, name;
}

final class Milestone {
  const Milestone({this.id, required this.title, this.completedAt});
  final String? id;
  final String title;
  final DateTime? completedAt;
}

final class Task {
  const Task({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.completedAt,
    this.due = const Due.none(),
    this.estimateMinutes,
    this.tags = const [],
    this.milestones = const [],
  });
  final String id, title, description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt, updatedAt;
  final DateTime? completedAt;
  final Due due;
  final int? estimateMinutes;
  final List<Tag> tags;
  final List<Milestone> milestones;
  bool overdue(DateTime now, DateTime Function(DateTime) display) =>
      status.isOpen &&
      (due.date != null
          ? due.date.toString().compareTo(
                  CivilDate.of(display(now)).toString(),
                ) <
                0
          : due.instant != null && due.instant!.isBefore(now));
}

/// Mutable editor draft; never exposed as committed state.
class TaskDraft {
  TaskDraft({
    this.title = '',
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.none,
    this.due = const Due.none(),
    this.estimateMinutes,
    List<String>? tagIds,
    List<Milestone>? milestones,
  }) : tagIds = [...?tagIds],
       milestones = [...?milestones];
  factory TaskDraft.from(Task task) => TaskDraft(
    title: task.title,
    description: task.description,
    status: task.status,
    priority: task.priority,
    due: task.due,
    estimateMinutes: task.estimateMinutes,
    tagIds: task.tags.map((t) => t.id).toList(),
    milestones: task.milestones,
  );
  String title, description;
  TaskStatus status;
  TaskPriority priority;
  Due due;
  int? estimateMinutes;
  List<String> tagIds;
  List<Milestone> milestones;
  void validate() {
    if (title.trim().isEmpty || title.trim().length > 500) {
      throw ArgumentError('Use a title between 1 and 500 characters.');
    }
    if (description.length > 100000) {
      throw ArgumentError(
        'Description is too long (100,000 characters maximum).',
      );
    }
    if (estimateMinutes != null &&
        (estimateMinutes! < 1 || estimateMinutes! > 5256000)) {
      throw ArgumentError('Estimate must be 1–5,256,000 minutes.');
    }
    if (tagIds.toSet().length != tagIds.length) {
      throw ArgumentError('Duplicate tags.');
    }
    final ids = <String>{};
    for (final step in milestones) {
      if (step.title.trim().isEmpty || step.title.trim().length > 500) {
        throw ArgumentError('Milestone titles need 1–500 characters.');
      }
      if (step.id != null && !ids.add(step.id!)) {
        throw ArgumentError('Duplicate milestone.');
      }
    }
  }
}

final class SavedView {
  const SavedView(this.id, this.name, this.query);
  final String id, name;
  final TaskQuery query;
}

final class Workspace {
  const Workspace(
    this.tasks,
    this.tags,
    this.views,
    this.defaultViewId, {
    this.invalidViews = const {},
  });
  final List<Task> tasks;
  final List<Tag> tags;
  final List<SavedView> views;
  final String? defaultViewId;
  final Map<String, String> invalidViews;
}

final class DeleteReceipt {
  const DeleteReceipt(this.operations);

  /// Expected deletion operation per entity; restore rejects a newer deletion.
  final Map<String, String> operations;
}

abstract interface class TaskRepository {
  Stream<List<Task>> watchTasks();
  Stream<Workspace> watchWorkspace();
  Future<void> createTask(String title);
  Future<Task> saveTask(TaskDraft draft, {Task? base});
  Future<void> setCompleted(String id, {required bool completed});
  Future<DeleteReceipt> deleteTasks(Iterable<String> ids);
  Future<void> restoreTasks(DeleteReceipt receipt);
  Future<String> saveTag(String name, {String? id});
  Future<void> deleteTag(String id);
  Future<String> saveView(String name, TaskQuery query, {String? id});
  Future<void> deleteView(String id);
  Future<void> setDefaultView(String? id);
}
