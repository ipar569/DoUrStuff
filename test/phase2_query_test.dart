import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:dourstuff/domain/task.dart';
import 'package:dourstuff/domain/query.dart';
import 'package:dourstuff/data/time_policy.dart';

void main() {
  final now = DateTime.utc(2026, 10, 3, 12);
  DateTime utc(DateTime d) => d.toUtc();
  Task task(
    String id, {
    String? title,
    String description = '',
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.none,
    Due due = const Due.none(),
    int? minutes,
    List<Tag> tags = const [],
  }) => Task(
    id: id,
    title: title ?? id,
    description: description,
    status: status,
    priority: priority,
    createdAt: now,
    updatedAt: now,
    due: due,
    estimateMinutes: minutes,
    tags: tags,
  );
  List<String> ids(List<Task> ts) => ts.map((t) => t.id).toList();
  test('AND tokens/dimensions, OR status/priority, any/all tags', () {
    final tasks = [
      task(
        'a',
        title: '  ALPHA  project',
        description: 'Write draft',
        priority: TaskPriority.high,
        tags: [const Tag('home', 'Home'), const Tag('work', 'Work')],
      ),
      task(
        'b',
        title: 'Alpha',
        description: 'Draft',
        priority: TaskPriority.low,
        tags: [const Tag('work', 'Work')],
      ),
      task(
        'c',
        title: 'Alpha project',
        status: TaskStatus.completed,
        priority: TaskPriority.high,
        tags: [const Tag('home', 'Home')],
      ),
    ];
    final q = TaskQuery(
      search: ' ALPHA   work draft ',
      statuses: {TaskStatus.todo, TaskStatus.inProgress},
      priorities: {TaskPriority.high, TaskPriority.medium},
      tags: {'work', 'home'},
    );
    expect(ids(q.apply(tasks, now: now, display: utc)), ['a']);
    q.search = 'alpha';
    q.statuses = {};
    q.priorities = {};
    expect(ids(q.apply(tasks, now: now, display: utc)), ['a', 'c', 'b']);
    q.allTags = true;
    expect(ids(q.apply(tasks, now: now, display: utc)), ['a']);
    q.tags = {'missing'};
    expect(q.apply(tasks, now: now), isEmpty);
  });
  test(
    'built-ins and inclusive ranges use displayed civil day and open statuses',
    () {
      final tasks = [
        task('yesterday', due: Due.date(CivilDate(2026, 10, 2))),
        task('today', due: Due.date(CivilDate(2026, 10, 3))),
        task('earlier', due: TimePolicy.resolve('2026-10-03', '11:00', 'UTC')),
        task('tomorrow', due: Due.date(CivilDate(2026, 10, 4))),
        task(
          'done',
          status: TaskStatus.completed,
          due: Due.date(CivilDate(2026, 10, 2)),
        ),
        task(
          'cancel',
          status: TaskStatus.cancelled,
          due: Due.date(CivilDate(2026, 10, 2)),
        ),
        task('undated'),
      ];
      expect(
        ids(
          TaskQuery(builtIn: BuiltInView.today)
              .apply(tasks, now: now, display: utc),
        ),
        ['today', 'earlier'],
      );
      expect(
        ids(
          TaskQuery(builtIn: BuiltInView.overdue)
              .apply(tasks, now: now, display: utc),
        ),
        ['yesterday', 'earlier'],
      );
      expect(
        ids(
          TaskQuery(builtIn: BuiltInView.upcoming)
              .apply(tasks, now: now, display: utc),
        ),
        ['tomorrow'],
      );
      expect(TaskQuery().apply(tasks, now: now, display: utc).length, 7);
      expect(
        ids(
          TaskQuery(
            from: CivilDate(2026, 10, 3),
            to: CivilDate(2026, 10, 3),
          ).apply(tasks, now: now, display: utc),
        ),
        ['today', 'earlier'],
      );
      expect(
        ids(TaskQuery(undated: true).apply(tasks, now: now, display: utc)),
        ['undated'],
      );
    },
  );
  test('sort is stable, date-only first, priority tie-breaks and nulls last both directions', () {
    final tasks = [
      task('z'),
      task(
        'b',
        due: Due.date(CivilDate(2026, 10, 3)),
        priority: TaskPriority.high,
        minutes: 10,
      ),
      task(
        'a',
        due: Due.date(CivilDate(2026, 10, 3)),
        priority: TaskPriority.high,
        minutes: 10,
      ),
      task(
        't',
        due: TimePolicy.resolve('2026-10-03', '00:01', 'UTC'),
        minutes: 5,
      ),
    ];
    final q = TaskQuery();
    expect(ids(q.apply(tasks, now: now, display: utc)), ['a', 'b', 't', 'z']);
    q.descending = true;
    expect(ids(q.apply(tasks.reversed.toList(), now: now, display: utc)), [
      'a',
      'b',
      't',
      'z',
    ]);
    q.sort = TaskSort.duration;
    expect(ids(q.apply(tasks, now: now)), ['a', 'b', 't', 'z']);
    q.descending = false;
    expect(ids(q.apply(tasks, now: now)), ['t', 'a', 'b', 'z']);
    q.sort = TaskSort.title;
    expect(
      ids(
        q.apply([task('2', title: ' Z'), task('1', title: 'alpha')], now: now),
      ),
      ['1', '2'],
    );
  });
  test('grouping preserves membership; tag duplicates deduplicate counts and fixed group order', () {
    final tasks = [
      task('a', tags: [const Tag('1', 'Home'), const Tag('2', 'Work')]),
      task('b'),
    ];
    final q = TaskQuery(group: TaskGrouping.tag);
    final groups = q.groups(q.apply(tasks, now: now));
    expect(groups.keys, ['#Home', '#Work', 'Untagged']);
    expect(groups.values.expand((v) => v).length, 3);
    expect(groups.values.expand((v) => v).map((t) => t.id).toSet().length, 2);
    q.group = TaskGrouping.priority;
    expect(q.groups([task('a'), task('b', priority: TaskPriority.high)]).keys, [
      'high priority',
      'none priority',
    ]);
    q.group = TaskGrouping.dueDay;
    expect(
      q.groups([
        task('b'),
        task('a', due: Due.date(CivilDate(2026, 1, 1))),
      ]).keys,
      ['2026-01-01', 'No due date'],
    );
  });
  test('malformed saved specifications fail closed', () {
    for (final j in [
      null,
      {},
      TaskQuery().toJson()..['version'] = 2,
      TaskQuery().toJson()..['sort'] = 'bogus',
      TaskQuery().toJson()..['descending'] = 'yes',
      TaskQuery().toJson()..['from'] = '2026-02-30',
      TaskQuery().toJson()
        ..['undated'] = true
        ..['from'] = '2026-01-01',
    ]) {
      expect(() => TaskQuery.fromJson(j), throwsFormatException);
    }
    expect(
      () => TaskQuery(
        from: CivilDate(2026, 2, 1),
        to: CivilDate(2026, 1, 1),
      ).validate(),
      throwsFormatException,
    );
  });
  test(
    'DST gaps advance and folds choose earlier or explicit later in two zones',
    () {
      expect(
        TimePolicy.resolve('2026-03-08', '02:30', 'America/New_York').instant,
        DateTime.utc(2026, 3, 8, 7, 30),
      );
      expect(
        TimePolicy.resolve('2026-11-01', '01:30', 'America/New_York').instant,
        DateTime.utc(2026, 11, 1, 5, 30),
      );
      expect(
        TimePolicy.resolve(
          '2026-11-01',
          '01:30',
          'America/New_York',
          later: true,
        ).instant,
        DateTime.utc(2026, 11, 1, 6, 30),
      );
      expect(
        TimePolicy.resolve('2026-09-27', '02:30', 'Pacific/Auckland').instant,
        DateTime.utc(2026, 9, 26, 14, 30),
      );
      expect(
        TimePolicy.resolve('2026-04-05', '02:30', 'Pacific/Auckland').instant,
        DateTime.utc(2026, 4, 4, 13, 30),
      );
      expect(
        TimePolicy.resolve(
          '2026-04-05',
          '02:30',
          'Pacific/Auckland',
          later: true,
        ).instant,
        DateTime.utc(2026, 4, 4, 14, 30),
      );
      expect(
        TimePolicy.resolve(
          '2026-10-04',
          '02:15',
          'Australia/Lord_Howe',
        ).instant,
        DateTime.utc(2026, 10, 3, 15, 45),
      );
      expect(
        () => TimePolicy.resolve('2026-02-30', '09:00', 'UTC'),
        throwsArgumentError,
      );
      expect(
        () => TimePolicy.resolve('2026-10-03', '25:00', 'UTC'),
        throwsFormatException,
      );
    },
  );
  test(
    'civil day survives travel while timed tasks display on the device day',
    () {
      TimePolicy.initialize();
      DateTime auckland(DateTime d) =>
          tz.TZDateTime.from(d, tz.getLocation('Pacific/Auckland'));
      DateTime la(DateTime d) =>
          tz.TZDateTime.from(d, tz.getLocation('America/Los_Angeles'));
      final civil = task('civil', due: Due.date(CivilDate(2026, 10, 3)));
      final timed = task(
        'timed',
        due: TimePolicy.resolve('2026-10-03', '12:00', 'UTC'),
      );
      expect(civil.due.day(auckland), civil.due.day(la));
      expect(civil.overdue(now, auckland), isTrue);
      expect(civil.overdue(now, la), isFalse);
      expect(timed.due.day(auckland), '2026-10-04');
      expect(timed.due.day(la), '2026-10-03');
      expect(timed.due.instant, now);
    },
  );
}
