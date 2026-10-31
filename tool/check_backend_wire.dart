import 'dart:convert';
import 'dart:io';

import 'package:dourstuff/data/time_policy.dart';
import 'package:dourstuff/domain/account_sync_codec.dart';
import 'package:dourstuff/domain/account_sync_rpc.dart';
import 'package:dourstuff/domain/account_task_validation.dart';
import 'package:dourstuff/domain/account_view_validation.dart';
import 'package:dourstuff/domain/task.dart';
import 'package:dourstuff/domain/tag_normalization.dart';

/// Verifies sanitized synthetic responses captured by the backend harnesses.
void main(List<String> args) {
  if (args.length != 1) {
    throw ArgumentError('Expected a synthetic wire fixture path.');
  }
  final entries = jsonDecode(File(args.single).readAsStringSync()) as List;
  if (entries.isEmpty) {
    throw const FormatException('Expected real backend replies.');
  }
  final manifests = <String, SnapshotManifest>{};
  for (final entry in entries) {
    final withHistory = entry['request']['history_version'] == 1;
    final withRecovery = entry['request']['resolution_version'] == 1;
    switch (entry['rpc']) {
      case 'resolve_recovery':
        validateRecoveryResolutionReply(
          resolveRecoveryCodec.decodeRequest(entry['request']),
          (resolveRecoveryCodec.decodeReply(
            entry['reply'],
          ) as SyncSuccess<ResolveRecoveryResult>).value,
        );
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
          if (request.operations[i].entity.kind.name == 'view') {
            if (patches.containsKey('name')) {
              validity['invalid_view_name'] = validAccountViewName(
                patches['name']!.value,
              );
            }
            if (patches.containsKey('query')) {
              validity['invalid_view_query'] = validAccountViewQuery(
                patches['query']!.value,
              );
            }
          }
          if (request.operations[i].command == 'task.tag') {
            final patch = patches['membership']!;
            final base = patch.base.toJson();
            validity['invalid_membership'] =
                patch.value is bool &&
                (base['kind'] == 'absent' || base['value'] is bool);
          }
          if (request.operations[i].entity.kind.name == 'tag' &&
              patches.containsKey('name')) {
            validity['invalid_tag_name'] = validAccountTagName(
              patches['name']!.value,
            );
          }
          if (patches.containsKey('milestone_order') &&
              request.operations[i].command == 'task.milestone_order' &&
              patches.length == 1) {
            validity['invalid_milestone_order'] = validAccountMilestoneOrder(
              patches['milestone_order']!.value,
            );
          }
          if (patches.containsKey('completion')) {
            final completion = patches['completion']!.value;
            validity['invalid_completion'] = validAccountStatusGroup({
              'status': completion == null ? 'todo' : 'completed',
              'completed_at': completion,
            });
          }
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
                    'invalid_completion',
                    'invalid_milestone_order',
                    'invalid_tag_name',
                    'invalid_membership',
                    'invalid_view_name',
                    'invalid_view_query',
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
        if (withRecovery) {
          validateRecoveryPullReply(
            recoveryPullCodec.decodeRequest(entry['request']),
            (recoveryPullCodec.decodeReply(
              entry['reply'],
            ) as SyncSuccess<RecoveryPullResult>).value,
          );
          break;
        }
        if (withHistory) {
          validateHistoryPullReply(
            historyPullCodec.decodeRequest(entry['request']),
            (historyPullCodec.decodeReply(
              entry['reply'],
            ) as SyncSuccess<HistoryPullResult>).value,
          );
          break;
        }
        validatePullReply(
          pullCodec.decodeRequest(entry['request']),
          (pullCodec.decodeReply(
            entry['reply'],
          ) as SyncSuccess<PullResult>).value,
        );
      case 'snapshot_begin':
        final codec = withRecovery
            ? recoveryBeginSnapshotCodec
            : withHistory
            ? historyBeginSnapshotCodec
            : beginSnapshotCodec;
        final manifest = (codec.decodeReply(
          entry['reply'],
        ) as SyncSuccess<SnapshotManifest>).value;
        validateBeginSnapshotReply(
          codec.decodeRequest(entry['request']),
          manifest,
          DateTime.parse(entry['checked_at_utc'] as String),
        );
        manifests[manifest.token] = manifest;
      case 'snapshot_page':
        if (withRecovery) {
          final request = recoverySnapshotPageCodec.decodeRequest(
            entry['request'],
          );
          validateRecoverySnapshotPage(
            manifests[request.token]!,
            request,
            (recoverySnapshotPageCodec.decodeReply(
              entry['reply'],
            ) as SyncSuccess<RecoverySnapshotPage>).value,
            DateTime.parse(entry['checked_at_utc'] as String),
          );
          break;
        }
        if (withHistory) {
          final request = historySnapshotPageCodec.decodeRequest(
            entry['request'],
          );
          validateHistorySnapshotPage(
            manifests[request.token]!,
            request,
            (historySnapshotPageCodec.decodeReply(
              entry['reply'],
            ) as SyncSuccess<HistorySnapshotPage>).value,
            DateTime.parse(entry['checked_at_utc'] as String),
          );
          break;
        }
        final request = snapshotPageCodec.decodeRequest(entry['request']);
        validateSnapshotPage(
          manifests[request.token]!,
          request,
          (snapshotPageCodec.decodeReply(
            entry['reply'],
          ) as SyncSuccess<SnapshotPage>).value,
          DateTime.parse(entry['checked_at_utc'] as String),
        );
      default:
        throw const FormatException('Unexpected backend RPC.');
    }
  }
  stdout.writeln(
    '${entries.length} real backend replies passed Dart wire validation.',
  );
}
