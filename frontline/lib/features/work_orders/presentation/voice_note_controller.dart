import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';
import '../../../core/voice/voice_to_workflow_parser.dart';

part 'voice_note_controller.g.dart';

/// Persists the (technician-reviewed) structured fields from a voice
/// note (Section 16.12) - writes locally first, then outboxes the push,
/// same pattern as every other field mutation in this app.
@riverpod
class VoiceNoteController extends _$VoiceNoteController {
  @override
  void build() {}

  Future<void> saveFields(String workOrderId, VoiceWorkflowFields fields) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;

    final workOrder = await db.workOrderDao.byId(workOrderId);
    if (workOrder == null) return;
    guard.ensure(accessContext, AppAction.captureAttachment, siteId: workOrder.siteId);

    await db.transaction(() async {
      await db.workOrderDao.updateVoiceFields(
        workOrderId: workOrderId,
        finding: fields.finding,
        reading: fields.reading,
        diagnosis: fields.diagnosis,
        recommendation: fields.recommendation,
      );
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'work_order_voice_note',
        entityId: workOrderId,
        operation: 'update',
        payloadJson: jsonEncode({
          'finding': fields.finding,
          'reading': fields.reading,
          'diagnosis': fields.diagnosis,
          'recommendation': fields.recommendation,
        }),
        createdBy: accessContext.userId,
      );
    });
  }

  /// Pushes one voice-note update to the server - called by the sync
  /// engine. Mock mode just simulates latency.
  Future<void> push(String workOrderId, Map<String, dynamic> fields) async {
    if (AppConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return;
    }
    await ref.read(dioClientProvider).patch<void>(
          '/v1/work-orders/$workOrderId/voice-note',
          data: fields,
        );
  }
}
