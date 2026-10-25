import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/account_sync.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/tag_normalization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'tag wire fixture preserves original atomic names and kind-qualified UUIDs',
    () {
      final fixture = jsonDecode(
        File('test/fixtures/account-protocol-v2-tag-commands.json')
            .readAsStringSync(),
      );
      final request = applyCodec.decodeRequest(fixture);
      expect(applyCodec.encodeRequest(request), fixture);
      final task = request.operations[0];
      final tag = request.operations[1];
      final edit = request.operations[2];
      final deletion = request.operations[3];
      expect(tag.entity.key, task.entity.key);
      expect(tag.entity.identity, isNot(task.entity.identity));
      expect(tag.patches.keys.toSet(), {'existence', 'name'});
      expect(validAccountTagName(tag.patches['name']!.value), isTrue);
      expect(validAccountTagName(edit.patches['name']!.value), isTrue);
      final base = edit.patches['name']!.base as PredecessorBase;
      expect(base.operationId, tag.operationId);
      expect(base.sequence, tag.sequence);
      expect(base.value, tag.patches['name']!.value);
      expect(deletion.patches['existence']!.value, false);
      expect(
        (deletion.patches['existence']!.base as PredecessorBase).operationId,
        tag.operationId,
      );
      final original = tag.payloadIdentity;
      expect(
        () =>
            (tag.patches['name']!.value as Map)['normalized_name'] = 'another',
        throwsUnsupportedError,
      );
      expect(tag.payloadIdentity, original);
    },
  );
}
