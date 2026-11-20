import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'shift_roster_controller.g.dart';

/// Self-service actions on Screen 25 - Mark absence / Request relief
/// (attendance), and Swap / Replace (see the doc comments on
/// [AppDatabase.shiftRosterDao]'s `swapShifts`/`setReplacement` for
/// what those mean here given there's no synced employee directory
/// beyond today's roster).
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

  /// Screen 25 action: "Swap".
  Future<void> swapShifts({
    required String entryIdA,
    required String entryIdB,
    required String siteId,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.manageShiftHandover, siteId: siteId);

    await db.transaction(() async {
      await db.shiftRosterDao.swapShifts(entryIdA, entryIdB);
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'shift_roster_swap',
        entityId: entryIdA,
        operation: 'update',
        payloadJson: jsonEncode({'entryIdA': entryIdA, 'entryIdB': entryIdB}),
        createdBy: accessContext.userId,
      );
    });
  }

  /// Screen 25 action: "Replace".
  Future<void> setReplacement(
    String rosterEntryId, {
    required String? replacementName,
    required String siteId,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.manageShiftHandover, siteId: siteId);

    await db.transaction(() async {
      await db.shiftRosterDao.setReplacement(rosterEntryId, replacementName);
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'shift_roster_replace',
        entityId: rosterEntryId,
        operation: 'update',
        payloadJson: jsonEncode({'replacementName': replacementName}),
        createdBy: accessContext.userId,
      );
    });
  }
}
