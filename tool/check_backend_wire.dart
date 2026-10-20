import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/data/time_policy.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:dourstuff/domain/account_task_validation.dart';
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
          final receipt = result.results[i];
          final patches = request.operations[i].patches;
          if (receipt is! OperationReceipt) continue;
          final validity = <String, bool>{};
          if (patches.containsKey('due')) {
            validity['invalid_due'] = TimePolicy.validAccountDue(
              patches['due']!.value,
            );
          }
          if (patches.containsKey('description')) {
            validity['invalid_description'] = validAccountDescription(
              patches['description']!.value,
            );
          }
          if (patches.containsKey('estimate_minutes')) {
            validity['invalid_estimate_minutes'] = validAccountEstimate(
              patches['estimate_minutes']!.value,
            );
          }
          if (patches.containsKey('status_group')) {
            validity['invalid_status_group'] = validAccountStatusGroup(
              patches['status_group']!.value,
            );
          }
          if (patches.containsKey('title')) {
            final title = patches['title']!.value;
            var valid = title is String;
            if (title is String) {
              try {
                TaskDraft(title: title).validate();
              } on ArgumentError {
                valid = false;
              }
            }
            validity['invalid_title'] = valid;
          }
          if (patches.containsKey('priority')) {
            validity['invalid_priority'] = TaskPriority.values.any(
              (priority) => priority.name == patches['priority']!.value,
            );
          }
          // A command can contain several invalid groups. Any of them may
          // explain its terminal rejection; none may be accepted canonically.
          if ((validity.containsValue(false) &&
                  receipt.disposition != ReceiptDisposition.rejected) ||
              (const {
                    'invalid_title',
                    'invalid_status_group',
                    'invalid_priority',
                    'invalid_description',
                    'invalid_estimate_minutes',
                    'invalid_due',
                  }.contains(receipt.rejectionCode) &&
                  validity[receipt.rejectionCode] != false)) {
            throw const FormatException('Server and Dart task rules differ.');
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
