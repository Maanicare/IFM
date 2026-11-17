import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'shift_roster_controller.g.dart';

/// Self-service attendance changes on Screen 25 - "Mark absence" and
/// "Request relief". Full roster authoring (Swap/Replace another
/// employee's entry) stays a manager action outside this mobile app.
@riverpod
class ShiftRosterController extends _$ShiftRosterController {
  @override
  void build() {}

  Future<void> _setStatus(String rosterEntryId, String status, {required String siteId}) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.manageShiftHandover, siteId: siteId);

    await db.transaction(() async {
      await db.shiftRosterDao.setAttendanceStatus(rosterEntryId, status);
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'shift_roster_attendance',
        entityId: rosterEntryId,
        operation: 'update',
        payloadJson: jsonEncode({'status': status}),
        createdBy: accessContext.userId,
      );
    });
  }

  Future<void> markAbsent(String rosterEntryId, {required String siteId}) =>
      _setStatus(rosterEntryId, 'absent', siteId: siteId);

  Future<void> requestRelief(String rosterEntryId, {required String siteId}) =>
      _setStatus(rosterEntryId, 'relief_requested', siteId: siteId);
}
