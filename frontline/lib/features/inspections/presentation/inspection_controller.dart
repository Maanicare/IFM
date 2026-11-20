import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';
import '../domain/soft_service_template.dart';

part 'inspection_controller.g.dart';

/// Backs Screen 23 (Soft Service Inspection). Writes locally first, then
/// pushes through the outbox - same pattern as Incident/Hazard
/// reporting.
@riverpod
class InspectionController extends _$InspectionController {
  @override
  void build() {}

  Future<String> submitInspection({
    required String siteId,
    String? spaceId,
    required SoftServiceTemplate template,
    required double score,
    String? nonConformanceNote,
    String? correctiveTaskNote,
    String? correctiveOwnerName,
    DateTime? correctiveDueDate,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) {
      throw StateError('Cannot submit an inspection without a logged-in user.');
    }
    guard.ensure(accessContext, AppAction.manageCleaningTask, siteId: siteId);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.softServiceInspectionDao.insert(SoftServiceInspectionsCompanion.insert(
        id: id,
        siteId: siteId,
        spaceId: Value(spaceId),
        template: template.name,
        score: score,
        nonConformanceNote: Value(nonConformanceNote),
        correctiveTaskNote: Value(correctiveTaskNote),
        correctiveOwnerName: Value(correctiveOwnerName),
        correctiveDueDate: Value(correctiveDueDate),
        inspectedBy: accessContext.userId,
        inspectedAt: now,
      ));
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'soft_service_inspection',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({'inspectionId': id}),
        createdBy: accessContext.userId,
      );
    });
    return id;
  }

  /// Screen 34: marks a corrective task done.
  Future<void> markCorrectiveComplete(String inspectionId, {required String siteId}) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.manageCleaningTask, siteId: siteId);

    await db.transaction(() async {
      await db.softServiceInspectionDao.markCorrectiveComplete(inspectionId);
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'soft_service_inspection_corrective_complete',
        entityId: inspectionId,
        operation: 'update',
        payloadJson: jsonEncode({'inspectionId': inspectionId}),
        createdBy: accessContext.userId,
      );
    });
  }
}
