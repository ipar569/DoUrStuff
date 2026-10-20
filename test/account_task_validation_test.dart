import 'package:dourstuff/domain/account_task_validation.dart';
import 'package:dourstuff/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('description validation matches draft UTF-16 boundaries', () {
    for (final text in ['', '  body\n😀  ', 'a' * 100000, '😀' * 50000]) {
      expect(validAccountDescription(text), isTrue);
      expect(
        () => TaskDraft(title: 'X', description: text).validate(),
        returnsNormally,
      );
    }
    for (final text in ['a' * 100001, '${'😀' * 50000}a']) {
      expect(validAccountDescription(text), isFalse);
      expect(
        () => TaskDraft(title: 'X', description: text).validate(),
        throwsArgumentError,
      );
    }
    for (final value in [null, 1, true, [], {}]) {
      expect(validAccountDescription(value), isFalse);
    }
  });

  test('estimate validation matches nullable whole-minute draft range', () {
    for (final value in <int?>[null, 1, 5256000]) {
      expect(validAccountEstimate(value), isTrue);
      expect(
        () => TaskDraft(title: 'X', estimateMinutes: value).validate(),
        returnsNormally,
      );
    }
    for (final value in [0, -1, 5256001]) {
      expect(validAccountEstimate(value), isFalse);
      expect(
        () => TaskDraft(title: 'X', estimateMinutes: value).validate(),
        throwsArgumentError,
      );
    }
    for (final value in [1.0, true, '1', [], {}]) {
      expect(validAccountEstimate(value), isFalse);
    }
  });

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
