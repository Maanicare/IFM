import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'visitor_controller.g.dart';

/// Backs Screen 44 (Visitor Management): check in a visitor (generating
/// a QR pass) and check them out.
@riverpod
class VisitorController extends _$VisitorController {
  @override
  void build() {}

  Future<String> checkIn({
    required String siteId,
    required String visitorName,
    String? visitorMobile,
    String? visitorEmail,
    String? company,
    required String hostName,
    String? purpose,
    String? vehicleNumber,
    bool idVerified = false,
    String? idTypeNote,
    String? accessRequirementsNote,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) {
      throw StateError('Cannot check in a visitor without a logged-in user.');
    }
    guard.ensure(accessContext, AppAction.manageVisitor, siteId: siteId);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.visitorDao.insert(VisitsCompanion.insert(
        id: id,
        siteId: siteId,
        visitorName: visitorName,
        visitorMobile: Value(visitorMobile),
        visitorEmail: Value(visitorEmail),
        company: Value(company),
        hostName: hostName,
        purpose: Value(purpose),
        vehicleNumber: Value(vehicleNumber),
        idVerified: Value(idVerified),
        idTypeNote: Value(idTypeNote),
        accessRequirementsNote: Value(accessRequirementsNote),
        actualArrival: Value(now),
        status: const Value('checked_in'),
        passId: id,
        createdBy: accessContext.userId,
        createdAt: now,
      ));
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'visit',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({'visitId': id}),
        createdBy: accessContext.userId,
      );
    });
    return id;
  }

  Future<void> checkOut(String visitId, {required String siteId}) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.manageVisitor, siteId: siteId);

    await db.transaction(() async {
      await db.visitorDao.checkOut(visitId);
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'visit_check_out',
        entityId: visitId,
        operation: 'update',
        payloadJson: jsonEncode({'visitId': visitId}),
        createdBy: accessContext.userId,
      );
    });
  }
}
