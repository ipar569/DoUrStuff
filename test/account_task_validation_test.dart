import 'package:dourstuff/domain/account_task_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('status completion is atomic and uses native DateTime bounds', () {
    for (final status in ['todo', 'in_progress', 'cancelled']) {
      expect(
        validAccountStatusGroup({'status': status, 'completed_at': null}),
        isTrue,
      );
      expect(
        validAccountStatusGroup({'status': status, 'completed_at': 0}),
        isFalse,
      );
    }
    for (final instant in [-8640000000000000, -1, 0, 8640000000000000]) {
      expect(
        validAccountStatusGroup({
          'status': 'completed',
          'completed_at': instant,
        }),
        isTrue,
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(
          instant,
          isUtc: true,
        ).millisecondsSinceEpoch,
        instant,
      );
    }
    for (final instant in [
      null,
      true,
      '100',
      1.0,
      -8640000000000001,
      8640000000000001,
    ]) {
      expect(
        validAccountStatusGroup({
          'status': 'completed',
          'completed_at': instant,
        }),
        isFalse,
      );
    }
  });

  test('status requires exactly both supported members', () {
    for (final value in [
      null,
      [],
      'completed',
      {},
      {'status': 'todo'},
      {'status': 'unknown', 'completed_at': null},
      {'status': 'todo', 'completed_at': null, 'extra': true},
    ]) {
      expect(validAccountStatusGroup(value), isFalse);
    }
  });
}
