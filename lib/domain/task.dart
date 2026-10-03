enum TaskPriority { none, low, medium, high }

enum TaskStatus { todo, inProgress, completed, cancelled }

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
      throw FormatException('Expected YYYY-MM-DD');
    }
    final parts = input.split('-').map(int.parse).toList();
    return CivilDate(parts[0], parts[1], parts[2]);
  }

  final int year;
  final int month;
  final int day;

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
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
  });

  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
}

abstract interface class TaskRepository {
  Stream<List<Task>> watchTasks();
  Future<void> createTask(String title);
  Future<void> setCompleted(String id, {required bool completed});
}
