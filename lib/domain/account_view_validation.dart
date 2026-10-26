import 'account_sync.dart';
import 'query.dart';
import 'tag_normalization.dart';

/// Account names preserve the same cleaned display text as guest saved views.
bool validAccountViewName(Object? value) =>
    value is String &&
    value.isNotEmpty &&
    value.length <= 80 &&
    value == cleanTagName(value);

/// A complete canonical TaskQuery is one field, never independently merged
/// filters. Set arrays must be sorted and unique; original bases are immutable.
bool validAccountViewQuery(Object? value) {
  try {
    if (value is! Map || value['version'] is! int) return false;
    final query = TaskQuery.fromJson(value);
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    );
    return query.tags.every(uuid.hasMatch) &&
        canonicalSyncJson(value) == canonicalSyncJson(query.toJson());
  } on FormatException {
    return false;
  }
}
