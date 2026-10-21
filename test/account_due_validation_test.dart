import 'package:dourstuff/data/time_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ordinary times after a gap cannot use the pre-transition offset', () {
    for (final (day, time, zone, shift) in [
      ('2026-09-27', '03:00', 'Pacific/Auckland', 3600000),
      ('2026-09-27', '06:00', 'Pacific/Auckland', 3600000),
      ('2026-09-27', '03:30', 'Pacific/Auckland', 3600000),
      ('2026-03-08', '03:00', 'America/New_York', 3600000),
      ('2026-03-08', '06:00', 'America/New_York', 3600000),
      ('2026-03-08', '03:30', 'America/New_York', 3600000),
      ('2026-10-04', '02:30', 'Australia/Lord_Howe', 1800000),
      ('2026-10-04', '04:00', 'Australia/Lord_Howe', 1800000),
      ('2026-10-04', '02:45', 'Australia/Lord_Howe', 1800000),
      ('2011-12-31', '00:00', 'Pacific/Apia', 86400000),
      ('2011-12-31', '12:00', 'Pacific/Apia', 86400000),
    ]) {
      final due = TimePolicy.resolve(day, time, zone).toJson();
      expect(TimePolicy.validAccountDue(due), isTrue);
      expect(
        TimePolicy.validAccountDue({
          ...due,
          'instant': (due['instant'] as int) + shift,
        }),
        isFalse,
      );
    }
  });

  test('due wire shape rejects hybrids and invalid civil dates', () {
    for (final value in [
      {'kind': 'none'},
      {'kind': 'date', 'date': '0001-01-01'},
      {'kind': 'date', 'date': '2000-02-29'},
      {'kind': 'date', 'date': '9999-12-31'},
    ]) {
      expect(TimePolicy.validAccountDue(value), isTrue);
    }
    for (final value in [
      null,
      [],
      {},
      {'kind': 'none', 'date': null},
      {'kind': 'date', 'date': '1900-02-29'},
      {'kind': 'date', 'date': '0000-01-01'},
      {'kind': 'date', 'date': '2026-02-30'},
      {'kind': 'date', 'date': '2026-10-20\n'},
      {'kind': 'date', 'date': '2026-10-20', 'instant': 0},
    ]) {
      expect(TimePolicy.validAccountDue(value), isFalse);
    }
  });

  test('timed account values preserve fixed instants and gap/fold choices', () {
    final gap = {
      'kind': 'timed',
      'wall_time': '2026-09-27T02:30',
      'zone': 'Pacific/Auckland',
      'instant': DateTime.utc(2026, 9, 26, 14, 30).millisecondsSinceEpoch,
    };
    expect(TimePolicy.validAccountDue(gap), isTrue);
    for (final hour in [13, 14]) {
      final fold = {
        'kind': 'timed',
        'wall_time': '2026-04-05T02:30',
        'zone': 'Pacific/Auckland',
        'instant': DateTime.utc(2026, 4, 4, hour, 30).millisecondsSinceEpoch,
      };
      expect(TimePolicy.validAccountDue(fold), isTrue);
    }
    for (final value in [
      {...gap, 'instant': (gap['instant'] as int) + 1},
      {...gap, 'instant': (gap['instant'] as int).toDouble()},
      {...gap, 'instant': 8640000000000001},
      {...gap, 'zone': 'Not/AZone'},
      {...gap, 'wall_time': '2026-09-27 02:30'},
      {...gap, 'date': '2026-09-27'},
      {...gap}..remove('zone'),
    ]) {
      expect(TimePolicy.validAccountDue(value), isFalse);
    }
  });
}
