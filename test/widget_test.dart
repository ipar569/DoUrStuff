import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/app/app.dart';
import 'package:dourstuff/data/local/database.dart';
import 'package:dourstuff/data/local/task_repository.dart';

void main() {
  testWidgets('capture and completion use real local SQLite with no account', (
    tester,
  ) async {
    final db = AppDatabase(
      NativeDatabase.memory(setup: (db) => prepareSqlite(db, null)),
    );
    await db.initializeProfile('guest');
    addTearDown(db.close);
    await tester.pumpWidget(DoUrStuffApp(repository: LocalTaskRepository(db)));
    await tester.pumpAndSettle();
    expect(find.text('Room for your next step.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Water the plants');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(find.text('Water the plants'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Completed · select to reopen'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('To do'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('narrow touch layout supports enlarged text and validation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase(NativeDatabase.memory());
    await db.initializeProfile('guest');
    addTearDown(db.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: TaskHome(repository: LocalTaskRepository(db)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a title between 1 and 500 characters.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('failed save retains draft and reports local failure', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.initializeProfile('guest');
    await db.customStatement(
      "CREATE TRIGGER fail BEFORE INSERT ON outbox "
      "BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );
    addTearDown(db.close);
    await tester.pumpWidget(DoUrStuffApp(repository: LocalTaskRepository(db)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Keep this draft');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save. Your draft is kept. Try again.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Keep this draft',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
