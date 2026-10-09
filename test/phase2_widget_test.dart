import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/app/app.dart';
import 'package:dourstuff/app/task_editor.dart';
import 'package:dourstuff/app/query_editor.dart';
import 'package:dourstuff/data/local/database.dart' show AppDatabase;
import 'package:dourstuff/data/local/task_repository.dart';
import 'package:dourstuff/domain/task.dart';
import 'package:dourstuff/domain/query.dart';

void main() {
  late AppDatabase db;
  late LocalTaskRepository repo;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.initializeProfile('guest');
    repo = LocalTaskRepository(db);
  });
  tearDown(() async {
    await db.close();
  });
  Finder field(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  );
  Future<void> reveal(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 50,
      );
    }
    await t.ensureVisible(f);
    await t.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  }

  testWidgets('capture commits title and due date together and clears both', (
    t,
  ) async {
    await t.pumpWidget(DoUrStuffApp(repository: repo));
    await t.pumpAndSettle();
    expect(find.text('Add with details'), findsNothing);
    await t.enterText(find.byKey(const ValueKey('capture')), 'Finish report');
    await t.tap(find.text('Due date'));
    await t.pumpAndSettle();
    await t.tap(find.text('Tomorrow'));
    await t.pumpAndSettle();
    final now = DateTime.now();
    final tomorrow = CivilDate.of(DateTime(now.year, now.month, now.day + 1));
    await t.tap(find.text('Add task'));
    await t.pumpAndSettle();
    final task = (await repo.watchTasks().first).single;
    expect(task.title, 'Finish report');
    expect(task.due.date.toString(), tomorrow.toString());
    expect(find.text('Due date'), findsOneWidget);
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('capture')))
          .controller!
          .text,
      isEmpty,
    );
    final operations = await db
        .customSelect('SELECT envelope_json FROM outbox')
        .get();
    expect(operations, hasLength(1));
    expect(
      operations.single.read<String>('envelope_json'),
      contains(tomorrow.toString()),
    );
    await dispose(t);
  });

  testWidgets('capture failure retains title and date, retry creates once', (
    t,
  ) async {
    await t.pumpWidget(DoUrStuffApp(repository: repo));
    await t.pumpAndSettle();
    await t.enterText(
      find.byKey(const ValueKey('capture')),
      'Keep both inputs',
    );
    await t.tap(find.text('Due date'));
    await t.pumpAndSettle();
    await t.tap(find.text('Today'));
    await t.pumpAndSettle();
    await db.customStatement(
      "CREATE TRIGGER fail BEFORE INSERT ON outbox BEGIN SELECT RAISE(ABORT,'injected'); END",
    );
    await t.tap(find.text('Add task'));
    await t.pumpAndSettle();
    expect(
      find.text('Could not save. Your draft is kept. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Due date'), findsNothing);
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('capture')))
          .controller!
          .text,
      'Keep both inputs',
    );
    expect(await repo.watchTasks().first, isEmpty);
    await db.customStatement('DROP TRIGGER fail');
    await t.tap(find.text('Add task'));
    await t.pumpAndSettle();
    expect(
      (await repo.watchTasks().first).single.due.date.toString(),
      CivilDate.of(DateTime.now()).toString(),
    );
    await dispose(t);
  });

  testWidgets('custom capture date can be cancelled, entered and removed', (
    t,
  ) async {
    await t.pumpWidget(DoUrStuffApp(repository: repo));
    await t.pumpAndSettle();
    await t.tap(find.text('Due date'));
    await t.pumpAndSettle();
    await t.tap(find.text('Choose date…'));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.text('Due date'), findsOneWidget);
    await t.tap(find.text('Due date'));
    await t.pumpAndSettle();
    await t.tap(find.text('Choose date…'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Switch to input'));
    await t.pumpAndSettle();
    await t.enterText(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextField),
      ),
      '10/15/2026',
    );
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('capture')), 'Custom date');
    await t.tap(find.text('Add task'));
    await t.pumpAndSettle();
    expect(
      (await repo.watchTasks().first).single.due.date.toString(),
      '2026-10-15',
    );
    await t.tap(find.text('Due date'));
    await t.pumpAndSettle();
    await t.tap(find.text('Today'));
    await t.pumpAndSettle();
    await t.tap(find.byType(OutlinedButton).first);
    await t.pumpAndSettle();
    await t.tap(find.text('No due date'));
    await t.pumpAndSettle();
    expect(find.text('Due date'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('capture')), 'Undated');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(
      (await repo.watchTasks().first)
          .singleWhere((task) => task.title == 'Undated')
          .due
          .kind,
      'none',
    );
    await dispose(t);
  });

  testWidgets('collapsed editor retains optional details on title-only save', (
    t,
  ) async {
    final tag = await repo.saveTag('Work');
    final task = await repo.saveTask(
      TaskDraft(
        title: 'Original',
        description: 'Keep notes',
        priority: TaskPriority.high,
        estimateMinutes: 20,
        tagIds: [tag],
        due: Due.date(CivilDate(2026, 10, 15)),
        milestones: [const Milestone(title: 'Keep step')],
      ),
    );
    await t.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: TaskEditor(repository: repo, task: task),
      ),
    );
    await t.pumpAndSettle();
    expect(field('Description'), findsNothing);
    expect(find.text('Add milestone'), findsNothing);
    expect(find.text('Save task').hitTestable(), findsOneWidget);
    await t.enterText(field('Title'), 'Renamed');
    await t.tap(find.text('Save task'));
    await t.pumpAndSettle();
    final saved = (await repo.watchTasks().first).single;
    expect(saved.title, 'Renamed');
    expect(saved.description, 'Keep notes');
    expect(saved.priority, TaskPriority.high);
    expect(saved.estimateMinutes, 20);
    expect(saved.tags.single.id, tag);
    expect(saved.due.date.toString(), '2026-10-15');
    expect(saved.milestones.single.title, 'Keep step');
    await dispose(t);
  });

  testWidgets(
    'editor supports optional time, date-only conversion and clearing',
    (t) async {
      await repo.createTask('Schedule me');
      await t.pumpWidget(DoUrStuffApp(repository: repo));
      await t.pumpAndSettle();
      Future<void> open() async {
        await reveal(t, find.text('Schedule me'));
        await t.tap(find.text('Schedule me'));
        await t.pumpAndSettle();
      }

      Future<void> save() async {
        await reveal(t, find.text('Save task'));
        await t.tap(find.text('Save task'));
        await t.pumpAndSettle();
      }

      await open();
      await t.tap(find.text('Due date'));
      await t.pumpAndSettle();
      await t.tap(find.text('Tomorrow'));
      await t.pumpAndSettle();
      await t.tap(find.text('Add time'));
      await t.pumpAndSettle();
      await t.enterText(field('Time (24-hour)'), '10:45');
      await save();
      final timed = (await repo.watchTasks().first).single;
      expect(timed.due.kind, 'timed');
      expect(timed.due.zone, 'UTC');
      expect(timed.due.wallTime, endsWith('T10:45'));
      await open();
      expect(
        t.widget<TextField>(field('Time (24-hour)')).controller!.text,
        '10:45',
      );
      await t.tap(find.text('Remove time'));
      await t.pumpAndSettle();
      expect(field('Time (24-hour)'), findsNothing);
      await save();
      final dated = (await repo.watchTasks().first).single;
      expect(dated.due.kind, 'date');
      expect(dated.due.date.toString(), timed.due.wallTime!.substring(0, 10));
      await open();
      await t.tap(find.byType(OutlinedButton));
      await t.pumpAndSettle();
      await t.tap(find.text('No due date'));
      await t.pumpAndSettle();
      await save();
      expect((await repo.watchTasks().first).single.due.kind, 'none');
      await dispose(t);
    },
  );

  testWidgets(
    'open details, edit description, estimate, priority, save and reopen SQLite values',
    (t) async {
      await repo.createTask('Read a book');
      await t.pumpWidget(DoUrStuffApp(repository: repo));
      await t.pumpAndSettle();
      await reveal(t, find.text('Read a book'));
      await t.tap(find.text('Read a book'));
      await t.pumpAndSettle();
      await t.enterText(field('Title'), 'Read two chapters');
      await t.tap(find.text('More details'));
      await t.pumpAndSettle();
      await t.enterText(field('Description'), 'Notes kept offline');
      await t.tap(find.byType(DropdownButtonFormField<TaskPriority>));
      await t.pumpAndSettle();
      await t.tap(find.text('high priority').last);
      await t.pumpAndSettle();
      await reveal(t, field('Estimated minutes (optional)'));
      await t.enterText(field('Estimated minutes (optional)'), '25');
      await reveal(t, find.text('Save task'));
      await t.tap(find.text('Save task'));
      await t.pumpAndSettle();
      final saved = (await repo.watchTasks().first).single;
      expect(saved.title, 'Read two chapters');
      expect(saved.description, 'Notes kept offline');
      expect(saved.estimateMinutes, 25);
      expect(saved.priority, TaskPriority.high);
      expect(find.text('Task saved on this device.'), findsOneWidget);
      await dispose(t);
    },
  );
  testWidgets(
    'failed detail save keeps draft and retries without duplicate milestones',
    (t) async {
      final task = await repo.saveTask(TaskDraft(title: 'Original'));
      await db.customStatement(
        "CREATE TRIGGER fail BEFORE INSERT ON outbox BEGIN SELECT RAISE(ABORT,'injected'); END",
      );
      await t.pumpWidget(
        MaterialApp(
          theme: buildDarkTheme(),
          home: TaskEditor(repository: repo, task: task),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(field('Title'), 'Retained edit');
      await t.tap(find.text('More details'));
      await t.pumpAndSettle();
      await reveal(t, find.text('Add milestone'));
      await t.tap(find.text('Add milestone'));
      await t.pumpAndSettle();
      await reveal(t, field('Milestone 1'));
      await t.enterText(field('Milestone 1'), 'One step');
      await reveal(t, find.text('Save task'));
      await t.tap(find.text('Save task'));
      await t.pumpAndSettle();
      expect(
        find.text('Could not save. Your draft is kept. Try again.'),
        findsOneWidget,
      );
      await t.scrollUntilVisible(
        field('Title'),
        -300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 50,
      );
      expect(
        t.widget<TextField>(field('Title')).controller!.text,
        'Retained edit',
      );
      expect((await repo.watchTasks().first).single.title, 'Original');
      await db.customStatement('DROP TRIGGER fail');
      await reveal(t, find.text('Save task'));
      await t.tap(find.text('Save task'));
      await t.pumpAndSettle();
      expect(
        (await repo.watchTasks().first).single.milestones.single.title,
        'One step',
      );
      await dispose(t);
    },
  );
  testWidgets(
    'narrow editor and query controls support 200 percent text without overflow',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final task = await repo.saveTask(
        TaskDraft(
          title: 'A longer accessible title',
          milestones: [
            const Milestone(title: 'First'),
            const Milestone(title: 'Second'),
          ],
        ),
      );
      Widget shell(Widget child) => MaterialApp(
        theme: buildDarkTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: child,
        ),
      );
      await t.pumpWidget(shell(TaskEditor(repository: repo, task: task)));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.tap(find.text('More details'));
      await t.pumpAndSettle();
      await reveal(t, find.text('Add milestone'));
      await t.tap(find.byTooltip('Move milestone 2 up'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await reveal(t, find.text('Save task'));
      expect(t.takeException(), isNull);
      await t.pumpWidget(
        shell(
          QueryEditor(
            query: TaskQuery(),
            tags: const [Tag('t', 'A reusable tag label')],
          ),
        ),
      );
      await t.pumpAndSettle();
      await reveal(t, find.text('Apply filters'));
      expect(t.takeException(), isNull);
      await dispose(t);
    },
  );
  testWidgets('invalid date and filter combinations retain editable inputs', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: QueryEditor(query: TaskQuery(undated: true), tags: const []),
      ),
    );
    await t.pumpAndSettle();
    await reveal(t, field('Due from (inclusive)'));
    await t.enterText(field('Due from (inclusive)'), '2026-10-03');
    await reveal(t, find.text('Apply filters'));
    await t.tap(find.text('Apply filters'));
    await t.pumpAndSettle();
    expect(find.textContaining('Check the dates:'), findsOneWidget);
    expect(
      t.widget<TextField>(field('Due from (inclusive)')).controller!.text,
      '2026-10-03',
    );
    await dispose(t);
  });
  testWidgets(
    'saved view selection, update/default, reload and delete fallback',
    (t) async {
      await repo.createTask('Visible');
      final id = await repo.saveView('Focus', TaskQuery(search: 'Visible'));
      await repo.setDefaultView(id);
      t.view.physicalSize = const Size(1100, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(DoUrStuffApp(repository: repo));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('search')), findsNothing);
      await t.tap(find.text('Search (active)'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('search')))
            .controller!
            .text,
        'Visible',
      );
      await t.tap(find.byTooltip('Saved view options'));
      await t.pumpAndSettle();
      await t.tap(find.text('Update name and current settings'));
      await t.pumpAndSettle();
      await t.enterText(field('Name'), 'My focus');
      await t.tap(find.text('Save'));
      await t.pumpAndSettle();
      expect((await repo.watchWorkspace().first).views.single.name, 'My focus');
      await t.tap(find.byTooltip('Saved view options'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete saved view'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete').last);
      await t.pumpAndSettle();
      expect((await repo.watchWorkspace().first).defaultViewId, isNull);
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('search')))
            .controller!
            .text,
        '',
      );
      await dispose(t);
    },
  );
  testWidgets(
    'bulk delete requires confirmation, deduplicates grouped tasks and offers undo',
    (t) async {
      final a = await repo.saveTag('Home'), b = await repo.saveTag('Work');
      await repo.saveTask(TaskDraft(title: 'Shared task', tagIds: [a, b]));
      final view = await repo.saveView(
        'By tag',
        TaskQuery(group: TaskGrouping.tag),
      );
      await repo.setDefaultView(view);
      t.view.physicalSize = const Size(1100, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(DoUrStuffApp(repository: repo));
      await t.pumpAndSettle();
      expect(find.text('Shared task'), findsNWidgets(2));
      await t.tap(find.text('Select tasks'));
      await t.pumpAndSettle();
      await t.tap(find.text('Select all results'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete 1 selected'));
      await t.pumpAndSettle();
      expect((await repo.watchTasks().first).length, 1);
      await t.tap(find.text('Cancel').last);
      await t.pumpAndSettle();
      expect((await repo.watchTasks().first).length, 1);
      await t.tap(find.text('Delete 1 selected'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete').last);
      await t.pumpAndSettle();
      expect((await repo.watchTasks().first), isEmpty);
      await t.tap(find.text('Undo'));
      await t.pumpAndSettle();
      expect((await repo.watchTasks().first).length, 1);
      await dispose(t);
    },
  );
  testWidgets('keyboard capture shortcut and search empty state', (t) async {
    await repo.createTask('One task');
    await t.pumpWidget(DoUrStuffApp(repository: repo));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('search')), findsNothing);
    await t.tap(find.text('Search'));
    await t.pumpAndSettle();
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('search')))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    await t.enterText(find.byKey(const ValueKey('search')), 'No match');
    await t.pumpAndSettle();
    await reveal(t, find.text('No tasks match these filters.'));
    expect(find.text('No tasks match these filters.'), findsOneWidget);
    await reveal(t, find.byTooltip('Collapse search'));
    await t.tap(find.byTooltip('Collapse search'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('search')), findsNothing);
    expect(find.text('No tasks match these filters.'), findsOneWidget);
    await t.tap(find.text('Search (active)'));
    await t.pumpAndSettle();
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('search')))
          .controller!
          .text,
      'No match',
    );
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyN);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('capture')))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    await dispose(t);
  });
  testWidgets('failed saved view write retains its name for retry', (t) async {
    await t.pumpWidget(DoUrStuffApp(repository: repo));
    await t.pumpAndSettle();
    await db.customStatement(
      "CREATE TRIGGER fail BEFORE INSERT ON outbox BEGIN SELECT RAISE(ABORT,'injected'); END",
    );
    await t.tap(find.text('Save view'));
    await t.pumpAndSettle();
    await t.enterText(field('Name'), 'Keep this view');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(
      find.text('Could not save. Your draft is kept. Try again.'),
      findsOneWidget,
    );
    expect(
      t.widget<TextField>(field('Name')).controller!.text,
      'Keep this view',
    );
    expect((await repo.watchWorkspace().first).views, isEmpty);
    await db.customStatement('DROP TRIGGER fail');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(
      (await repo.watchWorkspace().first).views.single.name,
      'Keep this view',
    );
    await dispose(t);
  });
}
