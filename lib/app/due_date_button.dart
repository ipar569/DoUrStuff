import 'package:flutter/material.dart';

import '../domain/task.dart';

/// Date-only shortcuts use calendar arithmetic, including across DST changes.
class DueDateButton extends StatelessWidget {
  const DueDateButton({
    super.key,
    required this.date,
    required this.onChanged,
    this.enabled = true,
  });

  final CivilDate? date;
  final ValueChanged<CivilDate?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final value = date;
    final label = value == null
        ? 'Due date'
        : '${MaterialLocalizations.of(context).formatMediumDate(DateTime(value.year, value.month, value.day))}${value.year == DateTime.now().year ? '' : ', ${value.year}'}';
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: () => onChanged(CivilDate.of(DateTime.now())),
          leadingIcon: const Icon(Icons.today_outlined),
          child: const Text('Today'),
        ),
        MenuItemButton(
          onPressed: () {
            final now = DateTime.now();
            onChanged(CivilDate.of(DateTime(now.year, now.month, now.day + 1)));
          },
          leadingIcon: const Icon(Icons.event_outlined),
          child: const Text('Tomorrow'),
        ),
        MenuItemButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value == null
                  ? DateTime.now()
                  : DateTime(value.year, value.month, value.day),
              firstDate: DateTime(1),
              lastDate: DateTime(9999, 12, 31),
              helpText: 'Due date',
            );
            if (picked != null && context.mounted) {
              onChanged(CivilDate.of(picked));
            }
          },
          leadingIcon: const Icon(Icons.date_range_outlined),
          child: const Text('Choose date…'),
        ),
        if (value != null)
          MenuItemButton(
            onPressed: () => onChanged(null),
            leadingIcon: const Icon(Icons.event_busy_outlined),
            child: const Text('No due date'),
          ),
      ],
      builder: (context, controller, child) => Tooltip(
        message: value == null ? 'Set due date' : 'Due date: $value',
        child: OutlinedButton.icon(
          onPressed: enabled
              ? () => controller.isOpen ? controller.close() : controller.open()
              : null,
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(label),
        ),
      ),
    );
  }
}
