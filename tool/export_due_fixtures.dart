import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/data/time_policy.dart';
import 'package:dourstuff/domain/task.dart';

/// Export synthetic values from the pinned client resolver for real SQL tests.
/// This also records the precise zone vocabulary used by migration 007.
void main(List<String> args) {
  if (args.length != 1) throw ArgumentError('Expected output path.');
  final cases = <Map<String, Object?>>[];
  void add(String label, Object? value, bool valid) {
    if (TimePolicy.validAccountDue(value) != valid) {
      throw StateError('Unexpected client validation: $label');
    }
    cases.add({'label': label, 'value': value, 'valid': valid});
  }

  add('none', const Due.none().toJson(), true);
  for (final day in ['0001-01-01', '2000-02-29', '2026-10-20', '9999-12-31']) {
    add(day, Due.date(CivilDate.parse(day)).toJson(), true);
  }
  for (final zone in TimePolicy.zones) {
    for (final day in ['2026-01-15', '2026-07-15']) {
      add('$zone $day', TimePolicy.resolve(day, '12:34', zone).toJson(), true);
    }
  }
  for (final (day, time, zone) in [
    ('2026-09-27', '02:30', 'Pacific/Auckland'),
    ('2026-04-05', '02:30', 'Pacific/Auckland'),
    ('2026-03-08', '02:30', 'America/New_York'),
    ('2026-11-01', '01:30', 'America/New_York'),
    ('2026-10-04', '02:15', 'Australia/Lord_Howe'),
    ('2026-04-05', '01:45', 'Australia/Lord_Howe'),
    ('2011-12-30', '12:00', 'Pacific/Apia'),
    ('0001-01-01', '00:00', 'UTC'),
    ('9999-12-31', '23:59', 'UTC'),
    ('1900-01-01', '12:34', 'Europe/Paris'),
  ]) {
    for (final later in [false, true]) {
      final due = TimePolicy.resolve(day, time, zone, later: later).toJson();
      add('$zone $day $time later=$later', due, true);
      add('wrong instant $zone $day $later', {
        ...due,
        'instant': (due['instant'] as int) + 1,
      }, false);
    }
  }
  final timed = TimePolicy.resolve('2026-10-20', '12:34', 'UTC').toJson();
  for (final value in <Object?>[
    null,
    true,
    1,
    [],
    {},
    'date',
    {'kind': 'other'},
    {'kind': 'none', 'date': null},
    {'kind': 'date'},
    {'kind': 'date', 'date': 20261020},
    for (final day in [
      '0000-01-01',
      '10000-01-01',
      '1900-02-29',
      '2026-02-30',
      '2026-13-01',
      '2026-01-00',
      '2026-1-01',
      '2026-01-01\n',
    ])
      {'kind': 'date', 'date': day},
    {...timed, 'date': '2026-10-20'},
    {...timed}..remove('wall_time'),
    {...timed, 'instant': null},
    {...timed, 'instant': '0'},
    {...timed, 'instant': true},
    {...timed, 'instant': 8640000000000000},
    {...timed, 'instant': -8640000000000000},
    {...timed, 'zone': 'Not/AZone'},
    {...timed, 'zone': 'utc'},
    {...timed, 'zone': 'UTC+0'},
    {...timed, 'zone': null},
    for (final wall in [
      '2026-10-20 12:34',
      '2026-10-20T24:00',
      '2026-10-20T12:60',
      '2026-10-20T12:34:00',
      '2026-02-30T12:34',
    ])
      {...timed, 'wall_time': wall},
  ]) {
    add('invalid ${cases.length}', value, false);
  }
  File(
    args.single,
  ).writeAsStringSync(jsonEncode({'zones': TimePolicy.zones, 'cases': cases}));
  stdout.writeln(
    '${TimePolicy.zones.length} zones; ${cases.length} due cases.',
  );
}
