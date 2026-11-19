import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/fixtures/fixture_loader.dart';
import 'work_order_repository.dart';

/// Backs the Technician "My Work" and Work Order Detail screens from
/// `assets/fixtures/work_orders.json`. Also encodes the one deliberate
/// edge-case fixture (`wo-1003`) that always reports a sync conflict, so
/// the conflict-resolution UI can be exercised without a real backend.
class MockWorkOrderRepository implements WorkOrderRepository {
  MockWorkOrderRepository(this._db);

  final AppDatabase _db;

  /// Server-side "truth" for the conflict demo: pretend a supervisor has
  /// already moved wo-1003 to `verified` at server version 3, so any
  /// device push based on an older version is rejected.
  static const _conflictWorkOrderId = 'wo-1003';
  static const _conflictServerVersion = 3;

  @override
  Future<void> syncAssignedWorkOrders({
    required String userId,
    required String siteId,
  }) async {
    final list =
        await FixtureLoader.loadJson('assets/fixtures/work_orders.json')
            as List;

    await _db.transaction(() async {
      for (final w in list.cast<Map<String, dynamic>>()) {
        if (w['siteId'] != siteId || w['assignedUserId'] != userId) continue;

        await _db.workOrderDao.upsertFromServer(WorkOrdersCompanion.insert(
          id: w['id'] as String,
          woNumber: w['woNumber'] as String,
          requestId: Value(w['requestId'] as String?),
          type: w['type'] as String,
          assetId: Value(w['assetId'] as String?),
          spaceId: w['spaceId'] as String,
          siteId: w['siteId'] as String,
          priority: w['priority'] as String,
          status: w['status'] as String,
          assignedUserId: Value(w['assignedUserId'] as String?),
          scheduledStart:
              Value(FixtureLoader.resolveOffset(w, 'scheduledStart')),
          scheduledEnd: Value(FixtureLoader.resolveOffset(w, 'scheduledEnd')),
          estimatedMinutes: Value((w['estimatedMinutes'] as num?)?.toInt()),
          problemDescription: Value(w['problemDescription'] as String?),
          checklistId: Value(w['checklistId'] as String?),
          requiredToolsNote: Value(w['requiredToolsNote'] as String?),
          permitRequired: Value(w['permitRequired'] as bool? ?? false),
          permitType: Value(w['permitType'] as String?),
          slaResponseTarget:
              Value(FixtureLoader.resolveOffset(w, 'slaResponse')),
          slaResolutionTarget:
              Value(FixtureLoader.resolveOffset(w, 'slaResolution')),
          serverVersion: Value(
            w['id'] == _conflictWorkOrderId ? _conflictServerVersion - 1 : 1,
          ),
          updatedAt: DateTime.now(),
        ));
      }
    });

    final plannedParts = await FixtureLoader.loadJson(
      'assets/fixtures/work_order_planned_parts.json',
    ) as List;
    await _db.transaction(() async {
      for (final p in plannedParts.cast<Map<String, dynamic>>()) {
        final workOrder = list.cast<Map<String, dynamic>>().firstWhere(
            (w) => w['id'] == p['workOrderId'],
            orElse: () => const {});
        if (workOrder['siteId'] != siteId ||
            workOrder['assignedUserId'] != userId) {
          continue;
        }
        await _db.workOrderDao.upsertPlannedPart(WorkOrderPlannedPartsCompanion.insert(
          id: p['id'] as String,
          workOrderId: p['workOrderId'] as String,
          itemName: p['itemName'] as String,
          plannedQuantity: (p['plannedQuantity'] as num).toDouble(),
          unit: p['unit'] as String,
        ));
      }
    });
  }

  @override
  Future<PushResult> pushStatusChange({
    required String workOrderId,
    required String newStatus,
    String? reason,
    int? baseServerVersion,
    required String changedBy,
    DateTime? actualStart,
    DateTime? actualEnd,
    int? actualMinutes,
    double? latitude,
    double? longitude,
    String? locationSource,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (workOrderId == _conflictWorkOrderId) {
      throw SyncConflictError(
        message: 'This work order was already verified by a supervisor. '
            'Review the current state before retrying your change.',
        entityType: 'work_order',
        entityId: workOrderId,
        localPayload: {'status': newStatus, 'reason': reason},
        remotePayload: {
          'status': 'verified',
          'serverVersion': _conflictServerVersion,
        },
      );
    }

    return PushResult(newServerVersion: (baseServerVersion ?? 0) + 1);
  }
}
