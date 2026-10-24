import 'tag_normalization_data.dart';

/// Frozen native Dart 3.13.5 policy. Trim and internal whitespace differ at
/// U+0085. No NFC/NFKC, locale tailoring, case folding or UUID aliasing.
String cleanTagName(String value) {
  // Code units preserve malformed guest strings too. Account representation
  // validation is separate; it must never replace or truncate guest content.
  final units = value.codeUnits;
  var start = 0;
  var end = units.length;
  while (start < end && tagTrimV1.contains(units[start])) {
    start++;
  }
  while (end > start && tagTrimV1.contains(units[end - 1])) {
    end--;
  }
  final result = <int>[];
  var previousSpace = false;
  for (var i = start; i < end; i++) {
    final space = tagWhitespaceV1.contains(units[i]);
    if (!space || !previousSpace) result.add(space ? 32 : units[i]);
    previousSpace = space;
  }
  return String.fromCharCodes(result);
}

String normalizedTagName(String value) => String.fromCharCodes(
  cleanTagName(value).runes.map((cp) => tagLowercaseV1[cp] ?? cp),
);

/// Tag name is one atomic group. Accept only an already-clean display name and
/// its exact derived key; never rewrite immutable incoming operation payloads.
bool validAccountTagName(Object? value) {
  if (value is! Map ||
      value.length != 2 ||
      value['name'] is! String ||
      value['normalized_name'] is! String) {
    return false;
  }
  final name = value['name'] as String;
  if (name.isEmpty || name.length > 80 || name != cleanTagName(name)) {
    return false;
  }
  // PostgreSQL text cannot represent NUL or unpaired UTF-16 surrogates.
  if (name.runes.any((cp) => cp == 0 || (cp >= 0xd800 && cp <= 0xdfff))) {
    return false;
  }
  return value['normalized_name'] == normalizedTagName(name);
}
