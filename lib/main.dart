import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'data/local/database.dart';
import 'data/local/task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppDatabase? database;
  try {
    final directory = await getApplicationSupportDirectory();
    final profileDirectory = Directory(
      path.join(directory.path, 'profiles', 'guest'),
    );
    await profileDirectory.create(recursive: true);
    database = AppDatabase.file(
      File(path.join(profileDirectory.path, 'tasks.sqlite')),
    );
    await database.initializeProfile('guest');
    runApp(DoUrStuffApp(repository: LocalTaskRepository(database)));
  } catch (_) {
    await database?.close();
    runApp(const StorageFailureApp());
  }
}
