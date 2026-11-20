import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'safety_report_controller.g.dart';

/// Backs Screen 35 (Incident Report) and Screen 36 (Hazard/Near Miss).
/// Both write locally first - a safety report must never be lost to a
/// dropped connection - then push through the same repository-call
/// pattern used everywhere else in this app.
@riverpod
class SafetyReportController extends _$SafetyReportController {
  @override
  void build() {}

  Future<String> submitIncident({
    required String siteId,
    String? spaceId,
    required String type,
    required String severity,
    required String description,
    String? assetId,
    bool injury = false,
    String? immediateAction,
    String? peopleInvolved,
    String? witnesses,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) {
      throw StateError('Cannot report an incident without a logged-in user.');
    }
    guard.ensure(accessContext, AppAction.reportIncident, siteId: siteId);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.safetyDao.insertIncident(IncidentsCompanion.insert(
        id: id,
        incidentNumber: 'INC-${id.substring(0, 8).toUpperCase()}',
        siteId: siteId,
        spaceId: Value(spaceId),
        type: type,
        severity: severity,
        occurredAt: now,
        reportedBy: accessContext.userId,
        description: description,
        assetId: Value(assetId),
        injury: Value(injury),
        immediateAction: Value(immediateAction),
        peopleInvolved: Value(peopleInvolved),
        witnesses: Value(witnesses),
        createdAt: now,
      ));
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'incident',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({'incidentId': id}),
        createdBy: accessContext.userId,
      );
    });
    return id;
  }

  Future<String> submitHazard({
    required String siteId,
    String? spaceId,
    required String category,
    required String description,
    required int riskProbability,
    required int riskConsequence,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) {
      throw StateError('Cannot report a hazard without a logged-in user.');
    }
    guard.ensure(accessContext, AppAction.reportIncident, siteId: siteId);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.safetyDao.insertHazard(HazardsCompanion.insert(
        id: id,
        siteId: siteId,
        spaceId: Value(spaceId),
        category: category,
        description: description,
        riskProbability: riskProbability,
        riskConsequence: riskConsequence,
        riskScore: riskProbability * riskConsequence,
        reportedBy: accessContext.userId,
        createdAt: now,
      ));
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'hazard',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({'hazardId': id}),
        createdBy: accessContext.userId,
      );
    });
    return id;
  }
}
