import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';
import '../domain/permit_type.dart';

part 'permit_controller.g.dart';

/// Backs Screen 37 (Permit to Work): issuing and closing a permit.
@riverpod
class PermitController extends _$PermitController {
  @override
  void build() {}

  Future<String> issuePermit({
    required String siteId,
    String? workOrderId,
    required PermitType type,
    String? vendorName,
    required DateTime validFrom,
    required DateTime validTo,
    String? riskAssessmentNote,
    String? authorisedPersons,
    String? controlsNote,
    String? isolationNote,
    required String issuerName,
    required String receiverName,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) {
      throw StateError('Cannot issue a permit without a logged-in user.');
    }
    guard.ensure(accessContext, AppAction.managePermit, siteId: siteId);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.permitDao.insert(PermitsCompanion.insert(
        id: id,
        permitNumber: 'PTW-${id.substring(0, 8).toUpperCase()}',
        siteId: siteId,
        workOrderId: Value(workOrderId),
        permitType: type.name,
        vendorName: Value(vendorName),
        validFrom: validFrom,
        validTo: validTo,
        riskAssessmentNote: Value(riskAssessmentNote),
        authorisedPersons: Value(authorisedPersons),
        controlsNote: Value(controlsNote),
        isolationNote: Value(isolationNote),
        issuerName: issuerName,
        receiverName: receiverName,
        createdBy: accessContext.userId,
        createdAt: now,
      ));
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'permit',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({'permitId': id}),
        createdBy: accessContext.userId,
      );
    });
    return id;
  }

  Future<void> closePermit(String permitId, {required String siteId}) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.managePermit, siteId: siteId);

    await db.transaction(() async {
      await db.permitDao.closePermit(permitId);
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'permit_close',
        entityId: permitId,
        operation: 'update',
        payloadJson: jsonEncode({'permitId': permitId}),
        createdBy: accessContext.userId,
      );
    });
  }
}
