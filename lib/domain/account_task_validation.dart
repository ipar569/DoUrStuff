/// The account status/completion group is indivisible. Completion time is
/// device provenance in UTC epoch milliseconds, never a conflict ordering key.
bool validAccountStatusGroup(Object? value) {
  if (value is! Map ||
      value.length != 2 ||
      !value.containsKey('status') ||
      !value.containsKey('completed_at')) {
    return false;
  }
  final completedAt = value['completed_at'];
  return switch (value['status']) {
    'completed' =>
      completedAt is int &&
          completedAt >= -8640000000000000 &&
          completedAt <= 8640000000000000,
    'todo' || 'in_progress' || 'cancelled' => completedAt == null,
    _ => false,
  };
}
