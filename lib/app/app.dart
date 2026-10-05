import 'package:flutter/material.dart';

import 'task_home.dart';
export 'task_home.dart';

import '../domain/task.dart';

ThemeData buildDarkTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xffb5ceff),
    brightness: Brightness.dark,
    surface: const Color(0xff10141c),
  ),
  scaffoldBackgroundColor: const Color(0xff10141c),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(),
  ),
);

class DoUrStuffApp extends StatelessWidget {
  const DoUrStuffApp({super.key, required this.repository});
  final TaskRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DoUrStuff',
    debugShowCheckedModeBanner: false,
    theme: buildDarkTheme(),
    home: TaskHome(repository: repository),
  );
}

class StorageFailureApp extends StatelessWidget {
  const StorageFailureApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildDarkTheme(),
    home: const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storage_outlined, size: 40),
                SizedBox(height: 16),
                Text('Your task storage could not be opened.'),
                SizedBox(height: 8),
                Text(
                  'Your existing data has been kept. Check available disk space '
                  'and reopen the app. If you recently updated, use the newest '
                  'DoUrStuff version. Do not clear app data.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
