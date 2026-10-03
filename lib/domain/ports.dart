/// Integration contracts. No transport or OS implementation ships in phase 1.
abstract interface class Clock {
  DateTime nowUtc();
}

final class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

abstract interface class AuthSessionStore {
  Future<String?> readRefreshToken(String accountId);
  Future<void> writeRefreshToken(String accountId, String token);
  Future<void> removeSession(String accountId);
}

final class NotificationIntent {
  const NotificationIntent({
    required this.logicalKey,
    required this.atUtc,
    required this.profileGeneration,
  });
  final String logicalKey;
  final DateTime atUtc;
  final int profileGeneration;
}

abstract interface class NotificationScheduler {
  /// Registration IDs and OS capabilities are private to the device adapter.
  Future<void> reconcile(List<NotificationIntent> desired);
  Future<void> cancelProfile(String profileId);
}

abstract interface class TimeZoneProvider {
  String get deviceIanaZone;
  String get databaseVersion;
}
