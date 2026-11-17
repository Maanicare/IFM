import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'shift_handover_controller.g.dart';

/// Backs Screen 26 (Shift Handover): the outgoing team's briefing, and
/// the incoming team's acknowledgement. Both are offline-first writes -
/// a shift ending with no connectivity must still hand over cleanly.
@riverpod
class ShiftHandoverController extends _$ShiftHandoverController {
  @override
  void build() {}

  Future<String> submitHandover({
    required String siteId,
    String? openJobsNote,
    String? equipmentIssueNote,
    String? temporaryFixNote,
    String? vendorExpectedNote,
    String? safetyConcernNote,
    String? clientCommitmentNote,
    String? materialShortageNote,
    String? specialInstructionNote,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) {
      throw StateError('Cannot submit a handover without a logged-in user.');
    }
    guard.ensure(accessContext, AppAction.manageShiftHandover, siteId: siteId);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.shiftHandoverDao.insertLocal(ShiftHandoversCompanion.insert(
        id: id,
        siteId: siteId,
        openJobsNote: Value(openJobsNote),
        equipmentIssueNote: Value(equipmentIssueNote),
        temporaryFixNote: Value(temporaryFixNote),
        vendorExpectedNote: Value(vendorExpectedNote),
        safetyConcernNote: Value(safetyConcernNote),
        clientCommitmentNote: Value(clientCommitmentNote),
        materialShortageNote: Value(materialShortageNote),
        specialInstructionNote: Value(specialInstructionNote),
        createdBy: accessContext.userId,
        createdAt: now,
      ));
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'shift_handover',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({'handoverId': id}),
        createdBy: accessContext.userId,
      );
    });

    return id;
  }

  /// Incoming team confirms they've read the handover (Screen 26: "Must
  /// acknowledge handover").
  Future<void> acknowledge(String handoverId, {required String siteId}) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.manageShiftHandover, siteId: siteId);

    final now = DateTime.now();

    await db.transaction(() async {
      await db.shiftHandoverDao.acknowledgeLocally(
        id: handoverId,
        acknowledgedBy: accessContext.userId,
        acknowledgedAt: now,
      );
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'shift_handover',
        entityId: handoverId,
        operation: 'acknowledge',
        payloadJson: jsonEncode({
          'acknowledgedBy': accessContext.userId,
          'acknowledgedAt': now.toIso8601String(),
        }),
        createdBy: accessContext.userId,
      );
    });
  }
}
