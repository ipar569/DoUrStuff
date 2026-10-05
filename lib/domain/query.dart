import 'dart:convert';

import 'task.dart';

String normalized(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

enum BuiltInView { all, today, upcoming, overdue }

enum TaskGrouping { none, status, dueDay, tag, priority }

enum TaskSort { due, priority, created, title, duration }

class TaskQuery {
  TaskQuery({
    this.search = '',
    this.builtIn = BuiltInView.all,
    Set<TaskStatus>? statuses,
    Set<TaskPriority>? priorities,
    Set<String>? tags,
    this.allTags = false,
    this.from,
    this.to,
    this.undated = false,
    this.overdue = false,
    this.group = TaskGrouping.none,
    this.sort = TaskSort.due,
    this.descending = false,
  }) : statuses = {...?statuses},
       priorities = {...?priorities},
       tags = {...?tags};
  String search;
  BuiltInView builtIn;
  Set<TaskStatus> statuses;
  Set<TaskPriority> priorities;
  Set<String> tags;
  bool allTags, undated, overdue, descending;
  CivilDate? from, to;
  TaskGrouping group;
  TaskSort sort;
  TaskQuery copy() => TaskQuery.fromJson(toJson());
  void validate() {
    if (search.length > 2000) {
      throw const FormatException('Search is too long.');
    }
    if (undated &&
        (from != null || to != null || overdue || builtIn != BuiltInView.all)) {
      throw const FormatException(
        'Undated cannot be combined with a due range, overdue or a dated view.',
      );
    }
    if (from != null &&
        to != null &&
        from.toString().compareTo(to.toString()) > 0) {
      throw const FormatException('Start date must be on or before end date.');
    }
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'search': search,
    'builtIn': builtIn.name,
    'statuses': statuses.map((s) => s.name).toList()..sort(),
    'priorities': priorities.map((p) => p.name).toList()..sort(),
    'tags': tags.toList()..sort(),
    'allTags': allTags,
    'from': from?.toString(),
    'to': to?.toString(),
    'undated': undated,
    'overdue': overdue,
    'group': group.name,
    'sort': sort.name,
    'descending': descending,
  };
  factory TaskQuery.fromJson(Object? value) {
    try {
      final j = (value as Map).cast<String, Object?>();
      if (j['version'] != 1 ||
          j.keys.any((k) => !TaskQuery().toJson().containsKey(k))) {
        throw const FormatException('Unsupported saved view.');
      }
      final result = TaskQuery(
        search: j['search'] as String,
        builtIn: BuiltInView.values.byName(j['builtIn'] as String),
        statuses: (j['statuses'] as List)
            .map((e) => TaskStatus.values.byName(e as String))
            .toSet(),
        priorities: (j['priorities'] as List)
            .map((e) => TaskPriority.values.byName(e as String))
            .toSet(),
        tags: (j['tags'] as List).cast<String>().toSet(),
        allTags: j['allTags'] as bool,
        from: j['from'] == null ? null : CivilDate.parse(j['from'] as String),
        to: j['to'] == null ? null : CivilDate.parse(j['to'] as String),
        undated: j['undated'] as bool,
        overdue: j['overdue'] as bool,
        group: TaskGrouping.values.byName(j['group'] as String),
        sort: TaskSort.values.byName(j['sort'] as String),
        descending: j['descending'] as bool,
      );
      result.validate();
      return result;
    } catch (_) {
      throw const FormatException(
        'Invalid or unsupported saved view. Check dates and filter combinations.',
      );
    }
  }
  String encode() {
    validate();
    return jsonEncode(toJson());
  }

  List<Task> apply(
    List<Task> tasks, {
    required DateTime now,
    DateTime Function(DateTime)? display,
  }) {
    validate();
    final local = display ?? (d) => d.toLocal();
    final today = CivilDate.of(local(now)).toString();
    final tokens = normalized(search).split(' ').where((s) => s.isNotEmpty);
    final result = tasks.where((task) {
      final day = task.due.day(local);
      final ids = task.tags.map((t) => t.id).toSet();
      final haystack = normalized(
        '${task.title} ${task.description} ${task.tags.map((t) => t.name).join(' ')}',
      );
      return (statuses.isEmpty || statuses.contains(task.status)) &&
          (priorities.isEmpty || priorities.contains(task.priority)) &&
          (tags.isEmpty ||
              (allTags ? tags.every(ids.contains) : tags.any(ids.contains))) &&
          tokens.every(haystack.contains) &&
          (!undated || day == null) &&
          (from == null ||
              day != null && day.compareTo(from.toString()) >= 0) &&
          (to == null || day != null && day.compareTo(to.toString()) <= 0) &&
          (!overdue || task.overdue(now, local)) &&
          switch (builtIn) {
            BuiltInView.all => true,
            BuiltInView.today => task.status.isOpen && day == today,
            BuiltInView.upcoming =>
              task.status.isOpen && day != null && day.compareTo(today) > 0,
            BuiltInView.overdue => task.overdue(now, local),
          };
    }).toList();
    int nullable<T>(T? a, T? b, int Function(T, T) compare) {
      if (a == null) return b == null ? 0 : 1;
      if (b == null) return -1;
      return compare(a, b) * (descending ? -1 : 1);
    }

    result.sort((a, b) {
      var order = switch (sort) {
        TaskSort.due => nullable(
          a.due.day(local),
          b.due.day(local),
          (x, y) => x.compareTo(y),
        ),
        TaskSort.priority =>
          (b.priority.index - a.priority.index) * (descending ? -1 : 1),
        TaskSort.created =>
          a.createdAt.compareTo(b.createdAt) * (descending ? -1 : 1),
        TaskSort.title =>
          normalized(a.title).compareTo(normalized(b.title)) *
              (descending ? -1 : 1),
        TaskSort.duration => nullable(
          a.estimateMinutes,
          b.estimateMinutes,
          (x, y) => x.compareTo(y),
        ),
      };
      if (order == 0 && sort == TaskSort.due) {
        // Date-only deadlines precede timed entries on the same displayed day.
        if (a.due.kind != b.due.kind) order = a.due.kind == 'date' ? -1 : 1;
        if (order == 0 && a.due.instant != null && b.due.instant != null) {
          order =
              a.due.instant!.compareTo(b.due.instant!) * (descending ? -1 : 1);
        }
        if (order == 0) order = b.priority.index - a.priority.index;
      }
      if (order == 0) order = a.createdAt.compareTo(b.createdAt);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return result;
  }

  Map<String, List<Task>> groups(
    List<Task> tasks, {
    DateTime Function(DateTime)? display,
  }) {
    final local = display ?? (d) => d.toLocal();
    final result = <String, List<Task>>{};
    for (final task in tasks) {
      final keys = switch (group) {
        TaskGrouping.none => ['Tasks'],
        TaskGrouping.status => [task.status.label],
        TaskGrouping.priority => ['${task.priority.name} priority'],
        TaskGrouping.dueDay => [task.due.day(local) ?? 'No due date'],
        TaskGrouping.tag =>
          task.tags.isEmpty
              ? ['Untagged']
              : task.tags.map((t) => '#${t.name}').toList(),
      };
      for (final key in keys) {
        result.putIfAbsent(key, () => []).add(task);
      }
    }
    final keys = result.keys.toList();
    final fixed = switch (group) {
      TaskGrouping.status => TaskStatus.values.map((s) => s.label).toList(),
      TaskGrouping.priority =>
        TaskPriority.values.reversed.map((p) => '${p.name} priority').toList(),
      _ => <String>[],
    };
    keys.sort((a, b) {
      if (a == b) return 0;
      if (fixed.isNotEmpty) return fixed.indexOf(a).compareTo(fixed.indexOf(b));
      if (a == 'No due date' || a == 'Untagged') return 1;
      if (b == 'No due date' || b == 'Untagged') return -1;
      return normalized(a).compareTo(normalized(b));
    });
    return {for (final key in keys) key: result[key]!};
  }
}
