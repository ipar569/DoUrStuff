import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Fixed namespace and canonical tuple are part of protocol v1. Do not change
/// either after occurrence data exists. DST and tzdata never enter this key.
const occurrenceNamespace = '45c4f10e-70ac-5b0a-9b5b-17118e51c436';

String occurrenceId(String seriesId, String segmentId, int ordinal) {
  if (!Uuid.isValidUUID(fromString: seriesId) ||
      !Uuid.isValidUUID(fromString: segmentId) ||
      ordinal < 0) {
    throw ArgumentError(
      'Occurrence identity requires UUIDs and a nonnegative ordinal.',
    );
  }
  return const Uuid().v5(
    occurrenceNamespace,
    jsonEncode([seriesId.toLowerCase(), segmentId.toLowerCase(), ordinal]),
  );
}
