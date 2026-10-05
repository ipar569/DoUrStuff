// Render actual Flutter widgets with synthetic SQLite data; no native-device claim.
// Run: flutter test tool/render_preview.dart
// Set FLUTTER_ROOT if the SDK is not in the local .tools/flutter directory.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/app/app.dart';
import 'package:dourstuff/app/task_editor.dart';
import 'package:dourstuff/data/local/database.dart' show AppDatabase;
import 'package:dourstuff/domain/task.dart';
import 'package:dourstuff/domain/query.dart';
import 'package:dourstuff/data/local/task_repository.dart';

void main() {
  for (final size in [
    const Size(1100, 760),
    const Size(390, 844),
    const Size(800, 1200),
  ]) {
    final details = size.width == 800;
    testWidgets('render phase 2 at ${size.width.toInt()} pixels', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sdk = Platform.environment['FLUTTER_ROOT'] ?? '.tools/flutter';
      final font = File(
        '$sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
      );
      final loader = FontLoader('PreviewRoboto')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File(
                '$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
              ).readAsBytesSync(),
            ),
          ),
        );
      await icons.load();
      final db = AppDatabase(NativeDatabase.memory());
      await db.initializeProfile('guest');
      addTearDown(db.close);
      final repository = LocalTaskRepository(db);
      final home = await repository.saveTag('Home');
      final learning = await repository.saveTag('Learning');
      final detailTask = await repository.saveTask(
        TaskDraft(
          title: 'Plan meals for the week',
          description: 'Choose three easy recipes and write a shopping list.',
          priority: TaskPriority.high,
          due: Due.date(CivilDate(2026, 10, 4)),
          estimateMinutes: 30,
          tagIds: [home],
          milestones: [
            const Milestone(title: 'Choose recipes'),
            const Milestone(title: 'Shopping list'),
          ],
        ),
      );
      await repository.saveTask(
        TaskDraft(
          title: 'Read a chapter',
          priority: TaskPriority.medium,
          estimateMinutes: 20,
          tagIds: [learning],
          status: TaskStatus.inProgress,
        ),
      );
      await repository.saveTask(
        TaskDraft(
          title: 'Water the plants',
          tagIds: [home],
          status: TaskStatus.completed,
        ),
      );
      await repository.saveTask(
        TaskDraft(
          title: 'Take a walk outside',
          priority: TaskPriority.low,
          estimateMinutes: 30,
        ),
      );
      await repository.saveView('Home & everyday', TaskQuery(tags: {home}));
      await repository.saveView(
        'Small steps',
        TaskQuery(sort: TaskSort.duration),
      );
      final boundaryKey = GlobalKey();
      final theme = buildDarkTheme();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme.copyWith(
              textTheme: theme.textTheme.apply(fontFamily: 'PreviewRoboto'),
            ),
            home: details
                ? TaskEditor(repository: repository, task: detailTask)
                : TaskHome(repository: repository),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('docs/screenshots/phase-2-${size.width.toInt()}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }
}
