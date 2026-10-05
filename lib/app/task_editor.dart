import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/task.dart';
import '../data/time_policy.dart';
import 'due_date_button.dart';

String dueLabel(Due due) {
  if (due.date != null) return '${due.date} · date only';
  if (due.instant == null) return 'No due date';
  final local = due.instant!.toLocal();
  return '${CivilDate.of(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} ${local.timeZoneName}';
}

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, required this.repository, this.task});
  final TaskRepository repository;
  final Task? task;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _Step {
  _Step(Milestone value)
    : id = value.id,
      title = TextEditingController(text: value.title),
      done = value.completedAt != null,
      completedAt = value.completedAt;
  final String? id;
  final TextEditingController title;
  final DateTime? completedAt;
  bool done;
}

class _TaskEditorState extends State<TaskEditor> {
  late final TaskDraft draft;
  late final TextEditingController title,
      description,
      estimate,
      date,
      time,
      zone;
  late final Stream<Workspace> workspace;
  final steps = <_Step>[];
  bool busy = false, later = false;
  String kind = 'none';
  String? error;
  @override
  void initState() {
    super.initState();
    draft = widget.task == null ? TaskDraft() : TaskDraft.from(widget.task!);
    title = TextEditingController(text: draft.title);
    description = TextEditingController(text: draft.description);
    estimate = TextEditingController(
      text: draft.estimateMinutes?.toString() ?? '',
    );
    kind = draft.due.kind;
    date = TextEditingController(
      text:
          draft.due.date?.toString() ??
          draft.due.wallTime?.substring(0, 10) ??
          '',
    );
    time = TextEditingController(
      text: draft.due.wallTime?.substring(11) ?? '09:00',
    );
    zone = TextEditingController(text: draft.due.zone ?? 'UTC');
    if (kind == 'timed') {
      later =
          TimePolicy.resolve(date.text, time.text, zone.text).instant !=
          draft.due.instant;
    }
    steps.addAll(draft.milestones.map(_Step.new));
    workspace = widget.repository.watchWorkspace();
  }

  @override
  void dispose() {
    for (final c in [
      title,
      description,
      estimate,
      date,
      time,
      zone,
      ...steps.map((s) => s.title),
    ]) {
      c.dispose();
    }
    _zoneFocus.dispose();
    super.dispose();
  }

  Due _due() => switch (kind) {
    'date' => Due.date(CivilDate.parse(date.text.trim())),
    'timed' => TimePolicy.resolve(
      date.text.trim(),
      time.text.trim(),
      zone.text.trim(),
      later: later,
    ),
    _ => const Due.none(),
  };
  Future<void> _save() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      draft.title = title.text;
      draft.description = description.text;
      if (estimate.text.trim().isNotEmpty &&
          !RegExp(r'^\d+$').hasMatch(estimate.text.trim())) {
        throw const FormatException(
          'Estimate must be a positive whole number of minutes.',
        );
      }
      draft.estimateMinutes = estimate.text.trim().isEmpty
          ? null
          : int.parse(estimate.text.trim());
      draft.due = _due();
      draft.milestones = steps
          .map(
            (s) => Milestone(
              id: s.id,
              title: s.title.text,
              completedAt: s.done
                  ? s.completedAt ?? DateTime.now().toUtc()
                  : null,
            ),
          )
          .toList();
      draft.validate();
      await widget.repository.saveTask(draft, base: widget.task);
      if (mounted) Navigator.pop(context, true);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => error = e.message.toString());
    } on FormatException catch (e) {
      if (mounted) setState(() => error = e.message);
    } on StateError catch (_) {
      if (mounted) {
        setState(
          () => error = 'Task or tags changed. Your draft is kept. Reopen the task to use its latest values.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Could not save. Your draft is kept. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _newTag() async {
    await nameDialog(
      context,
      'New reusable tag',
      onSave: (name) async {
        final id = await widget.repository.saveTag(name);
        if (mounted) {
          setState(() {
            if (!draft.tagIds.contains(id)) draft.tagIds.add(id);
          });
        }
      },
    );
  }

  Future<void> _close() async {
    final discard = await confirmDialog(
      context,
      'Discard this draft?',
      'Any unsaved edits in this editor will be lost.',
      'Discard',
    );
    if (discard && mounted) Navigator.pop(context);
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int lines = 1,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: c,
      readOnly: busy,
      maxLines: lines,
      onChanged: (_) {
        if (c == date || c == time || c == zone) setState(() {});
      },
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !busy) _close();
    },
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close editor',
            onPressed: busy ? null : _close,
            icon: const Icon(Icons.close),
          ),
          title: Text(widget.task == null ? 'New task' : 'Task details'),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: AbsorbPointer(
                absorbing: busy,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _field(title, 'Title'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DueDateButton(
                          date: kind == 'none'
                              ? null
                              : CivilDate.parse(date.text),
                          enabled: !busy,
                          onChanged: (picked) => setState(() {
                            date.text = picked?.toString() ?? '';
                            kind = picked == null
                                ? 'none'
                                : kind == 'timed'
                                ? 'timed'
                                : 'date';
                          }),
                        ),
                        if (kind != 'none')
                          TextButton.icon(
                            onPressed: () => setState(() {
                              kind = kind == 'timed' ? 'date' : 'timed';
                            }),
                            icon: const Icon(Icons.schedule, size: 18),
                            label: Text(
                              kind == 'timed' ? 'Remove time' : 'Add time',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (kind == 'timed') ...[
                      _field(time, 'Time (24-hour)', hint: 'HH:mm'),
                      RawAutocomplete<String>(
                        textEditingController: zone,
                        focusNode: _zoneFocus,
                        optionsBuilder: (v) => TimePolicy.zones
                            .where(
                              (z) => z.toLowerCase().contains(
                                v.text.toLowerCase(),
                              ),
                            )
                            .take(12),
                        fieldViewBuilder: (context, c, f, onSubmit) =>
                            TextField(
                              controller: c,
                              focusNode: f,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'IANA time zone',
                                helperText: 'Choose the zone for the entered wall time.',
                                helperMaxLines: 3,
                              ),
                            ),
                        onSelected: (_) => setState(() {}),
                        optionsViewBuilder: (context, select, options) => Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 8,
                            child: SizedBox(
                              width: 280,
                              height: 220,
                              child: ListView(
                                children: options
                                    .map(
                                      (z) => ListTile(
                                        title: Text(z),
                                        onTap: () => select(z),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Use later instant when clocks repeat',
                        ),
                        subtitle: const Text(
                          'Default: earlier instant. Missing times advance by the DST gap.',
                        ),
                        value: later,
                        onChanged: (v) => setState(() => later = v!),
                      ),
                      Builder(
                        builder: (context) {
                          String preview;
                          try {
                            preview = 'Fixed deadline: ${dueLabel(_due())}';
                          } catch (_) {
                            preview = 'Enter a valid date, time and IANA zone to preview.';
                          }
                          return Text(preview);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    ExpansionTile(
                      title: const Text('More details'),
                      subtitle: const Text(
                        'Notes, priority, tags & milestones',
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                      maintainState: true,
                      children: [
                        _field(description, 'Description', lines: 4),
                        DropdownButtonFormField<TaskStatus>(
                          initialValue: draft.status,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: TaskStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ),
                              )
                              .toList(),
                          onChanged: (s) => setState(() => draft.status = s!),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<TaskPriority>(
                          initialValue: draft.priority,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                          ),
                          items: TaskPriority.values
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text('${p.name} priority'),
                                ),
                              )
                              .toList(),
                          onChanged: (p) => setState(() => draft.priority = p!),
                        ),
                        const SizedBox(height: 24),
                        _field(estimate, 'Estimated minutes (optional)'),
                        const Text(
                          'An estimate is effort, not a calendar booking.',
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Tags',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        StreamBuilder<Workspace>(
                          stream: workspace,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Text(
                                'Tags could not be loaded. Your draft is kept.',
                              );
                            }
                            final tags = snapshot.data?.tags ?? <Tag>[];
                            return Wrap(
                              spacing: 8,
                              children: [
                                for (final tag in tags)
                                  FilterChip(
                                    label: Text(tag.name),
                                    selected: draft.tagIds.contains(tag.id),
                                    onSelected: (v) => setState(() {
                                      v
                                          ? draft.tagIds.add(tag.id)
                                          : draft.tagIds.remove(tag.id);
                                    }),
                                  ),
                                ActionChip(
                                  label: const Text('New tag'),
                                  avatar: const Icon(Icons.add),
                                  onPressed: _newTag,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Milestones',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Text(
                          'Each step is independent of task completion.',
                        ),
                        for (var i = 0; i < steps.length; i++) _step(i),
                        TextButton.icon(
                          onPressed: () => setState(
                            () => steps.add(_Step(const Milestone(title: ''))),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add milestone'),
                        ),
                        if (widget.task != null) ...[
                          const Divider(),
                          Text('Created: ${widget.task!.createdAt.toLocal()}'),
                          Text('Updated: ${widget.task!.updatedAt.toLocal()}'),
                          if (widget.task!.completedAt != null)
                            Text(
                              'Completed: ${widget.task!.completedAt!.toLocal()}',
                            ),
                        ],
                      ],
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: busy ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(busy ? 'Saving locally…' : 'Save task'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final _zoneFocus = FocusNode();
  Widget _step(int i) {
    final step = steps[i];
    return Padding(
      key: ObjectKey(step),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          TextField(
            controller: step.title,
            decoration: InputDecoration(labelText: 'Milestone ${i + 1}'),
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                label: 'Complete milestone ${i + 1}',
                child: Checkbox(
                  value: step.done,
                  onChanged: (v) => setState(() => step.done = v!),
                ),
              ),
              Text(step.done ? 'Completed' : 'Open'),
              IconButton(
                tooltip: 'Move milestone ${i + 1} up',
                onPressed: i == 0
                    ? null
                    : () => setState(() {
                        steps.removeAt(i);
                        steps.insert(i - 1, step);
                      }),
                icon: const Icon(Icons.arrow_upward),
              ),
              IconButton(
                tooltip: 'Move milestone ${i + 1} down',
                onPressed: i == steps.length - 1
                    ? null
                    : () => setState(() {
                        steps.removeAt(i);
                        steps.insert(i + 1, step);
                      }),
                icon: const Icon(Icons.arrow_downward),
              ),
              IconButton(
                tooltip: 'Remove milestone ${i + 1}',
                onPressed: () => setState(() {
                  steps.removeAt(i);
                  step.title.dispose();
                }),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<String?> nameDialog(
  BuildContext context,
  String title, {
  String initial = '',
  Future<void> Function(String)? onSave,
}) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _NameDialog(title: title, initial: initial, onSave: onSave),
);

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial, this.onSave});
  final String title, initial;
  final Future<void> Function(String)? onSave;
  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final controller = TextEditingController(text: widget.initial);
  bool saving = false;
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    if (controller.text.trim().isEmpty) {
      setState(() => error = 'Enter a name.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSave?.call(controller.text);
      if (mounted) Navigator.pop(context, controller.text);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => error = e.message.toString());
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

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: controller,
        readOnly: saving,
        autofocus: true,
        maxLength: 80,
        decoration: InputDecoration(
          labelText: 'Name',
          errorText: error,
          errorMaxLines: 4,
        ),
        onSubmitted: (_) => save(),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(saving ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}

Future<bool> confirmDialog(
  BuildContext context,
  String title,
  String detail,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
