import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class TaskHome extends StatefulWidget {
  const TaskHome({super.key, required this.repository});
  final TaskRepository repository;
  @override
  State<TaskHome> createState() => _TaskHomeState();
}

class _TaskHomeState extends State<TaskHome> {
  final _title = TextEditingController();
  final _captureFocus = FocusNode();
  final _busyTasks = <String>{};
  late Stream<List<Task>> _tasks;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tasks = widget.repository.watchTasks();
  }

  @override
  void dispose() {
    _title.dispose();
    _captureFocus.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_saving) return;
    final title = _title.text.trim();
    if (title.isEmpty || title.length > 500) {
      setState(() => _error = 'Enter a title between 1 and 500 characters.');
      _captureFocus.requestFocus();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.createTask(title);
      if (!mounted) return;
      _title.clear();
      _captureFocus.requestFocus();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not save. Your draft is kept. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggle(Task task) async {
    if (!_busyTasks.add(task.id)) return;
    setState(() {});
    try {
      await widget.repository.setCompleted(
        task.id,
        completed: task.status != TaskStatus.completed,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Change could not be saved. Please try again.'),
          ),
        );
      }
    } finally {
      _busyTasks.remove(task.id);
      if (mounted) setState(() {});
    }
  }

  Widget _captureInput(BuildContext context, BoxConstraints constraints) {
    final field = TextField(
      controller: _title,
      focusNode: _captureFocus,
      readOnly: _saving,
      maxLength: 500,
      onSubmitted: (_) => _capture(),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'What needs doing?',
        hintText: 'Add a task',
        errorText: _error,
        errorMaxLines: 3,
        counterText: '',
        helperText: _saving ? 'Saving to this device…' : null,
      ),
    );
    final button = FilledButton.icon(
      onPressed: _saving ? null : _capture,
      icon: const Icon(Icons.add),
      label: const Text('Add task'),
    );
    if (constraints.maxWidth < 440 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.5) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [field, const SizedBox(height: 12), button],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        const SizedBox(width: 12),
        SizedBox(height: 56, child: button),
      ],
    );
  }

  Widget _taskSliver(BuildContext context, AsyncSnapshot<List<Task>> snapshot) {
    if (snapshot.hasError) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Text(
            'Tasks could not be loaded. Reopen the app to try again.',
          ),
        ),
      );
    }
    if (!snapshot.hasData) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final tasks = snapshot.data!;
    if (tasks.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.checklist_rounded, size: 52),
              SizedBox(height: 16),
              Text('Room for your next step.', textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text(
                'Add your first task above. No sign-up needed.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return SliverList.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final done = task.status == TaskStatus.completed;
        return Column(
          children: [
            CheckboxListTile(
              key: ValueKey(task.id),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 4,
              ),
              value: done,
              onChanged: _busyTasks.contains(task.id)
                  ? null
                  : (_) => _toggle(task),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(done ? 'Completed · select to reopen' : 'To do'),
            ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyN, control: true):
          _captureFocus.requestFocus,
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('DoUrStuff'),
        actions: [
          IconButton(
            tooltip: 'Storage and sync',
            icon: const Icon(Icons.cloud_off_outlined),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Saved on this device'),
                content: const Text(
                  'Your tasks work without an account or internet. '
                  'Cloud sync and reminders will be available in later phases.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: StreamBuilder<List<Task>>(
              stream: _tasks,
              builder: (context, snapshot) => CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A little progress, every day.',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Capture a task. Take the next step.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(builder: _captureInput),
                          const SizedBox(height: 16),
                          Text(
                            'Stored locally · Foundation preview',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: _taskSliver(context, snapshot),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
