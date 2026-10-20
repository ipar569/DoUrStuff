import 'package:dourstuff/data/time_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
