import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';
import '../domain/cleaning_task_status.dart';

part 'cleaning_task_controller.g.dart';

/// Screen 21 actions: start a task, record an inspection-point response,
/// and submit completion (Consumables used / Exception notes).
@riverpod
class CleaningTaskController extends _$CleaningTaskController {
  @override
  void build() {}

  Future<void> startTask(String cleaningTaskId, {required String siteId}) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.manageCleaningTask, siteId: siteId);

    await db.cleaningTaskDao.startTask(cleaningTaskId);
  }

  Future<void> recordInspectionResponse({
    required String cleaningTaskId,
    required String inspectionPointId,
    required bool passed,
    String? note,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;

    await db.cleaningTaskDao.recordInspectionResponse(
      CleaningTaskInspectionResponsesCompanion.insert(
        id: IdGenerator.newId(),
        cleaningTaskId: cleaningTaskId,
        inspectionPointId: inspectionPointId,
        passed: passed,
        note: Value(note),
        capturedBy: accessContext.userId,
        capturedAt: DateTime.now(),
      ),
    );
  }

  Future<void> submitCompletion(
    String cleaningTaskId, {
    required String siteId,
    String? consumablesNote,
    String? exceptionNote,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.manageCleaningTask, siteId: siteId);

    await db.transaction(() async {
      await db.cleaningTaskDao.submitCompletion(
        cleaningTaskId: cleaningTaskId,
        consumablesNote: consumablesNote,
        exceptionNote: exceptionNote,
      );
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'cleaning_task_completion',
        entityId: cleaningTaskId,
        operation: 'update',
        payloadJson: jsonEncode({'status': CleaningTaskStatus.completed}),
        createdBy: accessContext.userId,
      );
    });
  }
}
