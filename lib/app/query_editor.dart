import 'package:flutter/material.dart';

import '../domain/task.dart';
import '../domain/query.dart';

class QueryEditor extends StatefulWidget {
  const QueryEditor({super.key, required this.query, required this.tags});
  final TaskQuery query;
  final List<Tag> tags;
  @override
  State<QueryEditor> createState() => _QueryEditorState();
}

class _QueryEditorState extends State<QueryEditor> {
  late final TaskQuery q = widget.query.copy();
  late final TextEditingController from = TextEditingController(
    text: q.from?.toString() ?? '',
  );
  late final TextEditingController to = TextEditingController(
    text: q.to?.toString() ?? '',
  );
  String? error;
  @override
  void dispose() {
    from.dispose();
    to.dispose();
    super.dispose();
  }

  void apply() {
    try {
      q.from = from.text.trim().isEmpty
          ? null
          : CivilDate.parse(from.text.trim());
      q.to = to.text.trim().isEmpty ? null : CivilDate.parse(to.text.trim());
      q.validate();
      Navigator.pop(context, q);
    } catch (_) {
      setState(
        () => error = 'Check the dates: use YYYY-MM-DD, start before end. Undated cannot combine with date filters or dated views.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Filters and ordering')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Filters combine with AND. Status and priority choices use OR. Search matches every word across title, description and tags.',
              ),
              const SizedBox(height: 16),
              const Text('Status'),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in TaskStatus.values)
                    FilterChip(
                      label: Text(s.label),
                      selected: q.statuses.contains(s),
                      onSelected: (v) => setState(() {
                        v ? q.statuses.add(s) : q.statuses.remove(s);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Priority'),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in TaskPriority.values)
                    FilterChip(
                      label: Text(p.name),
                      selected: q.priorities.contains(p),
                      onSelected: (v) => setState(() {
                        v ? q.priorities.add(p) : q.priorities.remove(p);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Tags'),
              if (widget.tags.isEmpty)
                const Text(
                  'Create reusable tags in task details or Manage tags.',
                ),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in widget.tags)
                    FilterChip(
                      label: Text(t.name),
                      selected: q.tags.contains(t.id),
                      onSelected: (v) => setState(() {
                        v ? q.tags.add(t.id) : q.tags.remove(t.id);
                      }),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Require all selected tags'),
                subtitle: const Text('Off: match any selected tag.'),
                value: q.allTags,
                onChanged: (v) => setState(() => q.allTags = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Only undated tasks'),
                value: q.undated,
                onChanged: (v) => setState(() => q.undated = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Only overdue open tasks'),
                value: q.overdue,
                onChanged: (v) => setState(() => q.overdue = v),
              ),
              TextField(
                controller: from,
                decoration: const InputDecoration(
                  labelText: 'Due from (inclusive)',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: to,
                decoration: const InputDecoration(
                  labelText: 'Due through (inclusive)',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<TaskGrouping>(
                initialValue: q.group,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Group by'),
                items: TaskGrouping.values
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(groupLabel(g)),
                      ),
                    )
                    .toList(),
                onChanged: (g) => setState(() => q.group = g!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskSort>(
                initialValue: q.sort,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Sort by'),
                items: TaskSort.values
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s, child: Text(sortLabel(s))),
                    )
                    .toList(),
                onChanged: (s) => setState(() => q.sort = s!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reverse sort direction'),
                value: q.descending,
                onChanged: (v) => setState(() => q.descending = v),
              ),
              const Text(
                'Default: due earliest, priority highest, then oldest created and ID. Empty dates/estimates stay last. Date-only deadlines precede timed tasks on the same day. Tag groups repeat tasks; counts and selections count each task once.',
              ),
              if (error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: apply,
                child: const Text('Apply filters'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, TaskQuery()),
                child: const Text('Reset to All Tasks'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String groupLabel(TaskGrouping g) => switch (g) {
  TaskGrouping.none => 'No grouping',
  TaskGrouping.status => 'Status',
  TaskGrouping.dueDay => 'Due day',
  TaskGrouping.tag => 'Tag',
  TaskGrouping.priority => 'Priority',
};
String sortLabel(TaskSort s) => switch (s) {
  TaskSort.due => 'Due date',
  TaskSort.priority => 'Priority (highest first)',
  TaskSort.created => 'Created',
  TaskSort.title => 'Title',
  TaskSort.duration => 'Estimated duration',
};
String viewLabel(BuiltInView v) => switch (v) {
  BuiltInView.all => 'All Tasks',
  BuiltInView.today => 'Today',
  BuiltInView.upcoming => 'Upcoming',
  BuiltInView.overdue => 'Overdue',
};
