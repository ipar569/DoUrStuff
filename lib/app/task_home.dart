import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/task.dart';
import '../domain/query.dart';
import 'task_editor.dart';
import 'query_editor.dart';
import 'due_date_button.dart';

class TaskHome extends StatefulWidget {
  const TaskHome({super.key, required this.repository});
  final TaskRepository repository;
  @override
  State<TaskHome> createState() => _TaskHomeState();
}

class _TaskHomeState extends State<TaskHome> with WidgetsBindingObserver {
  final title = TextEditingController(), search = TextEditingController();
  final captureFocus = FocusNode();
  final searchFocus = FocusNode(), searchButtonFocus = FocusNode();
  bool searchExpanded = false;
  final selected = <String>{}, busyTasks = <String>{};
  late StreamSubscription<Workspace> subscription;
  late Timer timer;
  Workspace? workspace;
  TaskQuery query = TaskQuery();
  String? activeView, error, loadError;
  CivilDate? captureDate;
  bool saving = false, initialized = false, selecting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listen();
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _listen() {
    subscription = widget.repository.watchWorkspace().listen(
      (w) {
        if (!mounted) return;
        setState(() {
          workspace = w;
          loadError = null;
          if (!initialized) {
            initialized = true;
            activeView = w.defaultViewId;
            query =
                w.views
                    .where((v) => v.id == activeView)
                    .firstOrNull
                    ?.query
                    .copy() ??
                TaskQuery();
            search.text = query.search;
          }
          if (activeView != null && !w.views.any((v) => v.id == activeView)) {
            activeView = null;
            query = TaskQuery();
            search.clear();
          }
          selected.removeWhere((id) => !w.tasks.any((t) => t.id == id));
        });
      },
      onError: (_) {
        if (mounted) {
          setState(
            () => loadError = 'Local data could not be loaded. Your data is kept. Retry or reopen the app.',
          );
        }
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription.cancel();
    timer.cancel();
    title.dispose();
    search.dispose();
    captureFocus.dispose();
    searchFocus.dispose();
    searchButtonFocus.dispose();
    super.dispose();
  }

  void message(String text, {VoidCallback? undo}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        action: undo == null
            ? null
            : SnackBarAction(label: 'Undo', onPressed: undo),
      ),
    );
  }

  Future<void> run(
    Future<void> Function() action, {
    String success = 'Saved on this device.',
  }) async {
    try {
      await action();
      message(success);
    } catch (_) {
      message('Change could not be saved. Please try again.');
    }
  }

  Future<void> capture() async {
    if (saving) return;
    if (title.text.trim().isEmpty || title.text.trim().length > 500) {
      setState(() => error = 'Enter a title between 1 and 500 characters.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.repository.saveTask(
        TaskDraft(
          title: title.text,
          due: captureDate == null ? const Due.none() : Due.date(captureDate),
        ),
      );
      if (mounted) {
        title.clear();
        captureDate = null;
        captureFocus.requestFocus();
        message('Task saved on this device.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Could not save. Your draft is kept. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget captureForm() => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 680 ||
          MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final input = TextField(
        key: const ValueKey('capture'),
        controller: title,
        focusNode: captureFocus,
        readOnly: saving,
        maxLength: 500,
        onSubmitted: (_) => capture(),
        decoration: InputDecoration(
          labelText: 'What needs doing?',
          counterText: '',
          errorText: error,
          errorMaxLines: 4,
        ),
      );
      final actions = Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DueDateButton(
            date: captureDate,
            enabled: !saving,
            onChanged: (date) => setState(() => captureDate = date),
          ),
          FilledButton.icon(
            onPressed: saving ? null : capture,
            icon: const Icon(Icons.add),
            label: Text(saving ? 'Adding…' : 'Add task'),
          ),
        ],
      );
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [input, const SizedBox(height: 12), actions],
                )
              : Row(
                  children: [
                    Expanded(child: input),
                    const SizedBox(width: 16),
                    actions,
                  ],
                ),
        ),
      );
    },
  );

  Future<void> edit(Task? task) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditor(repository: widget.repository, task: task),
      ),
    );
    if (saved == true) message('Task saved on this device.');
  }

  Future<void> toggle(Task task) async {
    if (!busyTasks.add(task.id)) return;
    setState(() {});
    try {
      await widget.repository.setCompleted(
        task.id,
        completed: task.status != TaskStatus.completed,
      );
      final updated = workspace?.tasks
          .where((t) => t.id == task.id)
          .firstOrNull;
      // Read committed state before offering a guarded undo, including cancelled/in-progress.
      final after = updated?.status == task.status
          ? (await widget.repository.watchTasks().first)
                .where((t) => t.id == task.id)
                .firstOrNull
          : updated;
      message(
        'Status saved.',
        undo: after == null
            ? null
            : () => run(() async {
                await widget.repository.saveTask(
                  TaskDraft.from(task),
                  base: after,
                );
              }),
      );
    } catch (_) {
      message('Change could not be saved. Please try again.');
    } finally {
      busyTasks.remove(task.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> remove(Iterable<String> ids) async {
    final keys = ids.toSet();
    if (keys.isEmpty) return;
    if (!await confirmDialog(
      context,
      'Delete ${keys.length == 1 ? 'task' : '${keys.length} tasks'}?',
      'Tasks and their checklists will be hidden. You can undo this deletion.',
      'Delete',
    )) {
      return;
    }
    try {
      final receipt = await widget.repository.deleteTasks(keys);
      if (mounted) {
        setState(() {
          selected.clear();
          selecting = false;
        });
      }
      message(
        'Deleted ${keys.length} task${keys.length == 1 ? '' : 's'}.',
        undo: () => run(
          () => widget.repository.restoreTasks(receipt),
          success: 'Tasks restored.',
        ),
      );
    } catch (_) {
      message('Delete could not be saved. Nothing was deleted.');
    }
  }

  Future<void> filters() async {
    final q = await Navigator.push<TaskQuery>(
      context,
      MaterialPageRoute(
        builder: (_) => QueryEditor(query: query, tags: workspace?.tags ?? []),
      ),
    );
    if (q != null && mounted) {
      setState(() {
        query = q;
        search.text = q.search;
        selected.clear();
      });
    }
  }

  Future<void> saveView({bool update = false}) async {
    final view = workspace?.views.where((v) => v.id == activeView).firstOrNull;
    final result = await nameDialog(
      context,
      update ? 'Edit saved view' : 'Save current view',
      initial: update ? view?.name ?? '' : '',
      onSave: (name) async {
        final id = await widget.repository.saveView(
          name,
          query,
          id: update ? activeView : null,
        );
        if (mounted) setState(() => activeView = id);
      },
    );
    if (result != null) message('View saved on this device.');
  }

  Widget navigation({bool drawer = false}) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Your workspace',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      for (final v in BuiltInView.values)
        ListTile(
          selected: activeView == null && query.builtIn == v,
          leading: Icon(switch (v) {
            BuiltInView.all => Icons.inbox_outlined,
            BuiltInView.today => Icons.today_outlined,
            BuiltInView.upcoming => Icons.event_outlined,
            BuiltInView.overdue => Icons.schedule,
          }),
          title: Text(viewLabel(v)),
          onTap: () {
            setState(() {
              activeView = null;
              query = TaskQuery(builtIn: v);
              search.clear();
              selected.clear();
            });
            if (drawer) Navigator.pop(context);
          },
        ),
      const Divider(),
      const Padding(padding: EdgeInsets.all(12), child: Text('Saved views')),
      for (final v in workspace?.views ?? <SavedView>[])
        ListTile(
          selected: activeView == v.id,
          title: Text(v.name),
          leading: Icon(
            workspace?.defaultViewId == v.id
                ? Icons.star
                : Icons.filter_alt_outlined,
          ),
          onTap: () {
            setState(() {
              activeView = v.id;
              query = v.query.copy();
              search.text = query.search;
              selected.clear();
            });
            if (drawer) Navigator.pop(context);
          },
        ),
      if (workspace?.views.isEmpty ?? true)
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Save a set of filters to find it here.'),
        ),
      for (final invalid
          in workspace?.invalidViews.entries ?? <MapEntry<String, String>>[])
        ListTile(
          leading: const Icon(Icons.warning_amber_outlined),
          title: Text(invalid.value),
          subtitle: const Text(
            'Invalid or unsupported view. Tasks are kept. Delete this view and save new filters.',
          ),
          trailing: IconButton(
            tooltip: 'Delete invalid view',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirmDialog(
                context,
                'Delete invalid view?',
                'Only this saved filter specification will be removed.',
                'Delete',
              )) {
                await run(() => widget.repository.deleteView(invalid.key));
              }
            },
          ),
        ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.label_outline),
        title: const Text('Manage tags'),
        onTap: () {
          if (drawer) Navigator.pop(context);
          manageTags();
        },
      ),
      const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Local only · No account needed',
          style: TextStyle(fontSize: 12),
        ),
      ),
    ],
  );
  Future<void> manageTags() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => TagManager(repository: widget.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide =
        MediaQuery.sizeOf(context).width >= 1000 &&
        MediaQuery.textScalerOf(context).scale(1) < 1.6;
    final tasks = query.apply(workspace?.tasks ?? [], now: DateTime.now());
    final groups = query.groups(tasks);
    final heading =
        workspace?.views.where((v) => v.id == activeView).firstOrNull?.name ??
        viewLabel(query.builtIn);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            captureFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): filters,
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DoUrStuff'),
          actions: [
            IconButton(
              tooltip: 'Storage information',
              icon: const Icon(Icons.cloud_off_outlined),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Saved on this device'),
                  content: const Text(
                    'Everything here works offline. Cloud sync, calendar, recurrence and reminders arrive in later phases.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        drawer: wide
            ? null
            : Drawer(child: SafeArea(child: navigation(drawer: true))),
        body: SafeArea(
          child: Row(
            children: [
              if (wide) ...[
                SizedBox(width: 250, child: navigation()),
                const VerticalDivider(width: 1),
              ],
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              heading,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text('A little progress, every day.'),
                            const SizedBox(height: 24),
                            captureForm(),
                            const SizedBox(height: 24),
                            if (searchExpanded) ...[
                              TextField(
                                key: const ValueKey('search'),
                                maxLength: 2000,
                                controller: search,
                                focusNode: searchFocus,
                                onChanged: (v) => setState(() {
                                  query.search = v;
                                  selected.clear();
                                }),
                                decoration: InputDecoration(
                                  labelText: 'Search tasks',
                                  counterText: '',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: IconButton(
                                    tooltip: 'Collapse search',
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() => searchExpanded = false);
                                      searchButtonFocus.requestFocus();
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (!searchExpanded)
                                  OutlinedButton.icon(
                                    focusNode: searchButtonFocus,
                                    onPressed: () {
                                      setState(() => searchExpanded = true);
                                      searchFocus.requestFocus();
                                    },
                                    icon: const Icon(Icons.search),
                                    label: Text(
                                      query.search.trim().isEmpty
                                          ? 'Search'
                                          : 'Search (active)',
                                    ),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: filters,
                                  icon: const Icon(Icons.tune),
                                  label: const Text('Filters & sort'),
                                ),
                                TextButton(
                                  onPressed: () => saveView(),
                                  child: const Text('Save view'),
                                ),
                                if (activeView != null)
                                  PopupMenuButton<String>(
                                    tooltip: 'Saved view options',
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        await saveView(update: true);
                                      }
                                      if (v == 'default') {
                                        await run(
                                          () => widget.repository
                                              .setDefaultView(activeView),
                                        );
                                      }
                                      if (v == 'clearDefault') {
                                        await run(
                                          () => widget.repository
                                              .setDefaultView(null),
                                        );
                                      }
                                      if (v == 'delete' &&
                                          context.mounted &&
                                          await confirmDialog(
                                            context,
                                            'Delete saved view?',
                                            'Tasks will be kept. A deleted default falls back to All Tasks.',
                                            'Delete',
                                          )) {
                                        await run(
                                          () => widget.repository.deleteView(
                                            activeView!,
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(
                                          'Update name and current settings',
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'default',
                                        child: Text('Use as startup default'),
                                      ),
                                      PopupMenuItem(
                                        value: 'clearDefault',
                                        child: Text('Use All Tasks as default'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete saved view'),
                                      ),
                                    ],
                                  ),
                                TextButton(
                                  onPressed: () => setState(() {
                                    selecting = !selecting;
                                    selected.clear();
                                  }),
                                  child: Text(
                                    selecting
                                        ? 'Cancel selection'
                                        : 'Select tasks',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${tasks.length} unique task${tasks.length == 1 ? '' : 's'} · ${groupLabel(query.group)} · ${sortLabel(query.sort)}',
                            ),
                            if (selecting)
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () => setState(
                                      () => selected.addAll(
                                        tasks.map((t) => t.id),
                                      ),
                                    ),
                                    child: const Text('Select all results'),
                                  ),
                                  TextButton(
                                    onPressed: selected.isEmpty
                                        ? null
                                        : () => remove(selected),
                                    child: Text(
                                      'Delete ${selected.length} selected',
                                    ),
                                  ),
                                ],
                              ),
                            if (loadError != null) ...[
                              Text(loadError!),
                              TextButton(
                                onPressed: () async {
                                  await subscription.cancel();
                                  _listen();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (workspace == null && loadError == null)
                      const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (workspace != null && tasks.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              const Icon(Icons.checklist_rounded, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                workspace!.tasks.isEmpty
                                    ? 'Room for your next step.'
                                    : 'No tasks match these filters.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                workspace!.tasks.isEmpty
                                    ? 'Add your first task above. No sign-up needed.'
                                    : 'Change your search or reset the filters.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    for (final group in groups.entries) ...[
                      if (query.group != TaskGrouping.none)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                            child: Text(
                              '${group.key} · ${group.value.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.builder(
                          itemCount: group.value.length,
                          itemBuilder: (context, i) => taskTile(group.value[i]),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 48)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget taskTile(Task task) {
    final done = task.status == TaskStatus.completed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: selecting
                      ? 'Select ${task.title}'
                      : done
                      ? 'Reopen ${task.title}'
                      : 'Complete ${task.title}',
                  child: Checkbox(
                    value: selecting ? selected.contains(task.id) : done,
                    onChanged: busyTasks.contains(task.id)
                        ? null
                        : (v) {
                            if (selecting) {
                              setState(() {
                                v!
                                    ? selected.add(task.id)
                                    : selected.remove(task.id);
                              });
                            } else {
                              toggle(task);
                            }
                          },
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => edit(task),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            done
                                ? 'Completed · select to reopen'
                                : task.status.label,
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(switch (task.priority) {
                                    TaskPriority.high => Icons.priority_high,
                                    TaskPriority.medium => Icons.flag_outlined,
                                    TaskPriority.low => Icons.low_priority,
                                    TaskPriority.none => Icons.outlined_flag,
                                  }, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${task.priority.name} priority'),
                                ],
                              ),
                              if (task.due.kind != 'none')
                                Text(dueLabel(task.due)),
                              if (task.overdue(
                                DateTime.now(),
                                (d) => d.toLocal(),
                              ))
                                const Text('Overdue'),
                              if (task.estimateMinutes != null)
                                Text('${task.estimateMinutes} min'),
                              if (task.milestones.isNotEmpty)
                                Text(
                                  '${task.milestones.where((s) => s.completedAt != null).length}/${task.milestones.length} steps',
                                ),
                              for (final tag in task.tags) Text('#${tag.name}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Task actions',
                  onSelected: (v) {
                    if (v == 'edit') edit(task);
                    if (v == 'delete') remove([task.id]);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit task')),
                    PopupMenuItem(value: 'delete', child: Text('Delete task')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TagManager extends StatefulWidget {
  const TagManager({super.key, required this.repository});
  final TaskRepository repository;
  @override
  State<TagManager> createState() => _TagManagerState();
}

class _TagManagerState extends State<TagManager> {
  late final stream = widget.repository.watchWorkspace();
  String? error;
  Future<void> save({Tag? tag}) async {
    await nameDialog(
      context,
      tag == null ? 'New tag' : 'Rename tag',
      initial: tag?.name ?? '',
      onSave: (name) async {
        await widget.repository.saveTag(name, id: tag?.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manage tags')),
    body: StreamBuilder<Workspace>(
      stream: stream,
      builder: (context, s) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Reusable labels for any number of tasks. Renaming updates every task using the tag.',
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: save, child: const Text('New tag')),
          if (error != null) Text(error!),
          if (s.hasError)
            const Text(
              'Tags could not be loaded. Reopen this screen to retry.',
            ),
          for (final tag in s.data?.tags ?? <Tag>[])
            ListTile(
              title: Text(tag.name),
              onTap: () => save(tag: tag),
              trailing: IconButton(
                tooltip: 'Delete ${tag.name}',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (!await confirmDialog(
                    context,
                    'Delete tag?',
                    'This removes the label from all tasks. Tasks are kept.',
                    'Delete',
                  )) {
                    return;
                  }
                  try {
                    await widget.repository.deleteTag(tag.id);
                  } catch (_) {
                    if (mounted) {
                      setState(
                        () => error = 'Tag could not be deleted. Try again.',
                      );
                    }
                  }
                },
              ),
            ),
        ],
      ),
    ),
  );
}
