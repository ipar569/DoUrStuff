import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/task.dart';

/// Offline IANA resolver. Device display uses Dart local time; entry zone is explicit.
final class TimePolicy {
  static bool _ready = false;
  static void initialize() {
    if (!_ready) {
      data.initializeTimeZones();
      _ready = true;
    }
  }

  static List<String> get zones {
    initialize();
    return {'UTC', ...tz.timeZoneDatabase.locations.keys}.toList()..sort();
  }

  static Due resolve(
    String date,
    String time,
    String zone, {
    bool later = false,
  }) {
    initialize();
    final day = CivilDate.parse(date);
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time)) {
      throw const FormatException('Use HH:mm (24-hour time).');
    }
    final p = time.split(':').map(int.parse).toList();
    final wall = DateTime.utc(day.year, day.month, day.day, p[0], p[1]);
    final tz.Location location;
    try {
      location = zone == 'UTC' ? tz.UTC : tz.getLocation(zone);
    } on tz.LocationNotFoundException {
      throw const FormatException('Choose a valid IANA time zone.');
    }
    // Resolve all possible offsets explicitly: library constructor fold defaults
    // are not the product contract. Also supports non-hour and full-day gaps.
    final offsets = location.zones.map((z) => z.offset.inMilliseconds).toSet();
    final exact = <DateTime>[];
    final shifted = <(int, DateTime)>[];
    for (final offset in offsets) {
      final instant = wall.subtract(Duration(milliseconds: offset));
      final actual = tz.TZDateTime.from(instant, location);
      final actualWall = DateTime.utc(
        actual.year,
        actual.month,
        actual.day,
        actual.hour,
        actual.minute,
        actual.second,
        actual.millisecond,
        actual.microsecond,
      );
      final delta = actualWall.difference(wall).inMilliseconds;
      if (delta == 0) exact.add(instant);
      // Only offsets active near this transition can define a gap.
      final before = location
          .timeZone(
            instant.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          )
          .offset
          .inMilliseconds;
      final after = location
          .timeZone(instant.add(const Duration(days: 2)).millisecondsSinceEpoch)
          .offset
          .inMilliseconds;
      if (delta > 0 &&
          after > before &&
          offset == before &&
          delta == after - before) {
        shifted.add((delta, instant));
      }
    }
    exact.sort();
    shifted.sort((a, b) => a.$1.compareTo(b.$1));
    if (exact.isEmpty && shifted.isEmpty) {
      throw const FormatException('Cannot resolve this wall time.');
    }
    final instant = exact.isNotEmpty
        ? (later ? exact.last : exact.first)
        : shifted.first.$2;
    return Due.timed(instant: instant, zone: zone, wallTime: '${day}T$time');
  }

  static void validate(Due due) {
    if (due.kind != 'timed') return;
    final wall = due.wallTime!;
    if (wall.length != 16) {
      throw const FormatException('Invalid original wall time.');
    }
    final early = resolve(wall.substring(0, 10), wall.substring(11), due.zone!);
    final late = resolve(
      wall.substring(0, 10),
      wall.substring(11),
      due.zone!,
      later: true,
    );
    if (wall[10] != 'T' ||
        (due.instant != early.instant && due.instant != late.instant)) {
      throw const FormatException(
        'Due instant does not match the named zone and wall time.',
      );
    }
  }
}
