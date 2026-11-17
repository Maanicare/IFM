import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'checklist_response_controller.g.dart';

/// Writes one checklist answer locally and enqueues it for sync, in a
/// single transaction (Section 3.2: evidence-before-claims - an answer
/// must be durably recorded the instant it's given, offline or not).
@riverpod
class ChecklistResponseController extends _$ChecklistResponseController {
  @override
  void build() {}

  Future<void> recordAnswer({
    required String workOrderId,
    required String itemId,
    required Object? value,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.submitChecklistResponse);

    final responseJson = jsonEncode({'value': value});
    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.checklistDao.recordResponse(ChecklistResponsesCompanion.insert(
        id: id,
        workOrderId: workOrderId,
        itemId: itemId,
        responseJson: responseJson,
        capturedBy: accessContext.userId,
        capturedAt: now,
      ));
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'checklist_response',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({
          'workOrderId': workOrderId,
          'itemId': itemId,
          'response': responseJson,
          'capturedBy': accessContext.userId,
          'capturedAt': now.toIso8601String(),
        }),
        createdBy: accessContext.userId,
      );
    });
  }
}
