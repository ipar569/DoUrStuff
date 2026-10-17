import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:dourstuff/domain/task.dart';

/// Verifies sanitized synthetic responses captured by the backend harnesses.
void main(List<String> args) {
  if (args.length != 1) {
    throw ArgumentError('Expected a synthetic wire fixture path.');
  }
  final entries = jsonDecode(File(args.single).readAsStringSync()) as List;
  if (entries.isEmpty) {
    throw const FormatException('Expected real backend replies.');
  }
  for (final entry in entries) {
    switch (entry['rpc']) {
      case 'apply':
        final request = applyCodec.decodeRequest(entry['request']);
        final result = (applyCodec.decodeReply(
          entry['reply'],
        ) as SyncSuccess<ApplyResult>).value;
        validateApplyReply(request, result);
        for (var i = 0; i < request.operations.length; i++) {
          final title = request.operations[i].patches['title']?.value;
          final receipt = result.results[i];
          if (title is! String || receipt is! OperationReceipt) continue;
          var valid = true;
          try {
            TaskDraft(title: title).validate();
          } on ArgumentError {
            valid = false;
          }
          if (valid == (receipt.rejectionCode == 'invalid_title')) {
            throw const FormatException('Server and Dart title rules differ.');
          }
        }
      case 'register_device':
        validateRegisterDeviceReply(
          registerDeviceCodec.decodeRequest(entry['request']),
          (registerDeviceCodec.decodeReply(
            entry['reply'],
          ) as SyncSuccess<RegisteredDevice>).value,
        );
      case 'pull':
        validatePullReply(
          pullCodec.decodeRequest(entry['request']),
          (pullCodec.decodeReply(
            entry['reply'],
          ) as SyncSuccess<PullResult>).value,
        );
      default:
        throw const FormatException('Unexpected backend RPC.');
    }
  }
  stdout.writeln(
    '${entries.length} real backend replies passed Dart wire validation.',
  );
}
