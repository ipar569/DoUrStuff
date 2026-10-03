import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dourstuff/domain/task.dart';
import 'package:dourstuff/domain/sync.dart';
import 'package:dourstuff/domain/recurrence_identity.dart';

void main() {
  test('civil dates keep their calendar day and reject overflow', () {
    expect(CivilDate.parse('2028-02-29').toString(), '2028-02-29');
    expect(() => CivilDate.parse('2027-02-29'), throwsArgumentError);
    expect(() => CivilDate.parse('2026-13-01'), throwsArgumentError);
    expect(() => CivilDate.parse('2026-1-01'), throwsFormatException);
  });

  test('protocol v1 command matches the committed wire fixture', () {
    const operation = ChangeOperation(
      operationId: '92c984ef-e496-4f84-b4b6-a09c0c84bb49',
      deviceEpoch: 'e9d39cd9-bdab-4679-8dfc-d4f53db46ef3',
      sequence: 1,
      entityId: '529e5f9f-3a5b-4b66-a46f-0e922df72720',
      command: 'task.create',
      changes: {'title': 'Fixture task'},
    );
    final fixture = jsonDecode(
      File('test/fixtures/protocol-v1-create.json').readAsStringSync(),
    );
    expect(jsonDecode(operation.encode()), fixture);
  });

  test(
    'occurrence identity is shared by devices and unaffected by UUID casing',
    () {
      const series = '529e5f9f-3a5b-4b66-a46f-0e922df72720';
      const segment = '92c984ef-e496-4f84-b4b6-a09c0c84bb49';
      final a = occurrenceId(series, segment, 12);
      expect(a, occurrenceId(series.toUpperCase(), segment.toUpperCase(), 12));
      expect(a, isNot(occurrenceId(series, segment, 13)));
      final fixture = jsonDecode(
        File('test/fixtures/occurrence-identity.json').readAsStringSync(),
      ) as Map;
      expect(a, fixture['expected_id']);
      expect(() => occurrenceId(series, segment, -1), throwsArgumentError);
    },
  );
}
