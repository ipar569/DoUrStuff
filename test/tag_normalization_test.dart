import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/query.dart';
import 'package:dourstuff/domain/tag_normalization.dart';
import 'package:dourstuff/domain/tag_normalization_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'frozen policy matches native SDK for every scalar and contiguous chunks',
    () {
      expect(Platform.version, startsWith('3.13.5 '));
      final fixture = jsonDecode(
        File('test/fixtures/tag-normalization-v1.json').readAsStringSync(),
      ) as Map;
      expect(tagLowercaseV1, {
        for (final pair in fixture['lower']) pair[0]: pair[1],
      });
      expect(tagTrimV1, (fixture['trim'] as List).toSet());
      expect(tagWhitespaceV1, (fixture['whitespace'] as List).toSet());
      final space = RegExp(r'\s');
      final chunk = <int>[];
      void flush() {
        final value = String.fromCharCodes(chunk);
        expect(normalizedTagName(value), normalized(value));
        chunk.clear();
      }

      for (var cp = 0; cp <= 0x10ffff; cp++) {
        if (cp >= 0xd800 && cp <= 0xdfff) continue;
        final s = String.fromCharCode(cp);
        if (s.toLowerCase() != String.fromCharCode(tagLowercaseV1[cp] ?? cp) ||
            s.trim().isEmpty != tagTrimV1.contains(cp) ||
            space.hasMatch(s) != tagWhitespaceV1.contains(cp)) {
          fail('Native normalization drift at U+${cp.toRadixString(16)}');
        }
        chunk.add(cp);
        if (chunk.length == 4096) flush();
      }
      flush();
    },
  );

  test(
    'whitespace boundaries, context, canonical forms and malformed guest data',
    () {
      for (final cp in {...tagTrimV1, ...tagWhitespaceV1, 0, 0xd800, 0xdc00}) {
        final c = String.fromCharCode(cp);
        for (final value in [c, '${c}A${c}B$c', 'A$c$c', '${c}A']) {
          expect(
            cleanTagName(value),
            value.trim().replaceAll(RegExp(r'\s+'), ' '),
          );
          expect(normalizedTagName(value), normalized(value));
        }
      }
      expect(normalizedTagName('\u0085A\u0085B\u0085'), 'a\u0085b');
      expect(normalizedTagName('ΟΣ İ 𐐀'), 'οσ i 𐐨');
      expect(normalizedTagName('CAFÉ'), isNot(normalizedTagName('Cafe\u0301')));
      expect(normalizedTagName('Straße'), isNot(normalizedTagName('STRASSE')));
    },
  );

  test(
    'atomic name group enforces exact key, clean display and UTF-16 length',
    () {
      for (final row in jsonDecode(
        File('test/fixtures/tag-name-validation.json').readAsStringSync(),
      ) as List) {
        expect(validAccountTagName(row['value']), row['valid']);
      }
      for (final name in ['a' * 80, '𐐀' * 40]) {
        expect(
          validAccountTagName({
            'name': name,
            'normalized_name': normalizedTagName(name),
          }),
          isTrue,
        );
      }
      for (final name in [
        'a' * 81,
        '𐐀' * 41,
        'a\u0000b',
        '\ud800',
        '\udc00',
      ]) {
        expect(
          validAccountTagName({
            'name': name,
            'normalized_name': normalizedTagName(name),
          }),
          isFalse,
        );
      }
    },
  );
}
