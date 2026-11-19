import 'account_sync.dart';
import 'query.dart';
import 'tag_normalization.dart';
import 'task.dart';

/// Account names preserve the same cleaned display text as guest saved views.
bool validAccountViewName(Object? value) =>
    value is String &&
    value.isNotEmpty &&
    value.length <= 80 &&
    value == cleanTagName(value);

/// The persisted guest query uses Dart enum names. Account filters use the
/// same wire status tokens as account task commands.
Map<String, Object?> encodeAccountViewQuery(TaskQuery query) => {
  ...query.toJson(),
  'statuses': query.statuses.map((status) => status.wire).toList()..sort(),
};

/// A complete canonical TaskQuery is one field, never independently merged
/// filters. Set arrays must be sorted and unique; original bases are immutable.
bool validAccountViewQuery(Object? value) {
  try {
    if (value is! Map || value['version'] is! int) return false;
    final statuses = value['statuses'];
    if (statuses is! List) return false;
    final query = TaskQuery.fromJson({
      ...value,
      'statuses': [
        for (final status in statuses)
          status == TaskStatus.inProgress.wire
              ? TaskStatus.inProgress.name
              : status,
      ],
    });
    return query.tags.every(isAccountUuid) &&
        canonicalSyncJson(value) ==
            canonicalSyncJson(encodeAccountViewQuery(query));
  } on FormatException {
    return false;
  }
}
