import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/tables/work_order_tables.dart';
import '../../../core/location/device_location_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';
import '../domain/work_order_status.dart';

part 'work_order_actions_controller.g.dart';

/// Thrown by [WorkOrderActionsController.checkIn] when GPS could not be
/// obtained and no manual-override reason was supplied yet - the UI
/// catches this to prompt for a reason, then retries with it (Section
/// 11: "manual override with reason").
class LocationUnavailableError implements Exception {
  const LocationUnavailableError();
}

/// Every technician-initiated status transition (Section 11: Accept ->
/// En Route -> Checked In -> In Progress -> ... -> Work Completed) goes
/// through here. Each method:
///   1. Checks the action against [PolicyGuard].
///   2. Applies the change to the local [WorkOrders] row immediately
///      (optimistic UI - the technician never waits on network).
///   3. Writes an audit row to [WorkOrderStatusHistory].
///   4. Enqueues an outbox entry so the sync engine replays it to the
///      server as soon as connectivity allows.
/// Steps 2-4 run inside one Drift transaction so the device is never left
/// in a state where the local status changed but no outbox entry exists
/// to push it (or vice versa).
@riverpod
class WorkOrderActionsController extends _$WorkOrderActionsController {
  static const _tag = 'WorkOrderActions';

  @override
  void build() {}

  Future<void> _transition({
    required String workOrderId,
    required String newStatus,
    required AppAction action,
    String? blockerReason,
    String? reason,
    DateTime? actualStart,
    DateTime? actualEnd,
    int? actualMinutes,
    double? latitude,
    double? longitude,
    String? locationSource,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;

    final workOrder = await db.workOrderDao.byId(workOrderId);
    if (workOrder == null) return;

    guard.ensure(accessContext, action, siteId: workOrder.siteId);

    await db.transaction(() async {
      await db.workOrderDao.applyLocalStatusChange(
        workOrderId: workOrderId,
        newStatus: newStatus,
        blockerReason: blockerReason,
        actualStart: actualStart,
        actualEnd: actualEnd,
        actualMinutes: actualMinutes,
      );
      await db.workOrderDao.recordStatusHistory(
        WorkOrderStatusHistoryCompanion.insert(
          id: IdGenerator.newId(),
          workOrderId: workOrderId,
          fromStatus: Value(workOrder.status),
          toStatus: newStatus,
          changedBy: accessContext.userId,
          reason: Value(reason ?? blockerReason),
          timestamp: DateTime.now(),
          latitude: Value(latitude),
          longitude: Value(longitude),
          locationSource: Value(locationSource),
        ),
      );
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'work_order_status',
        entityId: workOrderId,
        operation: 'status_transition',
        payloadJson: _payload(
          newStatus,
          reason ?? blockerReason,
          actualStart: actualStart,
          actualEnd: actualEnd,
          actualMinutes: actualMinutes,
          latitude: latitude,
          longitude: longitude,
          locationSource: locationSource,
        ),
        baseServerVersion: workOrder.serverVersion,
        createdBy: accessContext.userId,
      );
    });

    AppLogger.instance.info(_tag, 'Work order $workOrderId -> $newStatus');
  }

  String _payload(
    String status,
    String? reason, {
    DateTime? actualStart,
    DateTime? actualEnd,
    int? actualMinutes,
    double? latitude,
    double? longitude,
    String? locationSource,
  }) {
    final map = {
      'status': status,
      'reason': reason,
      'actualStart': actualStart?.toIso8601String(),
      'actualEnd': actualEnd?.toIso8601String(),
      'actualMinutes': actualMinutes,
      'latitude': latitude,
      'longitude': longitude,
      'locationSource': locationSource,
    };
    return jsonEncode(map);
  }

  Future<void> accept(String workOrderId) => _transition(
        workOrderId: workOrderId,
        newStatus: WorkOrderStatus.accepted,
        action: AppAction.acceptWorkOrder,
      );

  Future<void> startRoute(String workOrderId) => _transition(
        workOrderId: workOrderId,
        newStatus: WorkOrderStatus.enRoute,
        action: AppAction.startWorkOrder,
      );

  /// Checks in, preferring GPS (Section 11). If location can't be
  /// obtained (denied permission, GPS off, timeout) and no
  /// [manualOverrideReason] was given, throws [LocationUnavailableError]
  /// so the UI can prompt for one and retry - the check-in itself is
  /// never silently skipped or silently un-located.
  Future<void> checkIn(String workOrderId, {String? manualOverrideReason}) async {
    double? latitude;
    double? longitude;
    String locationSource;

    if (manualOverrideReason != null) {
      locationSource = 'manual_override';
    } else {
      final location = await DeviceLocationService.getCurrentLocation();
      if (location == null) {
        throw const LocationUnavailableError();
      }
      latitude = location.latitude;
      longitude = location.longitude;
      locationSource = 'gps';
    }

    await _transition(
      workOrderId: workOrderId,
      newStatus: WorkOrderStatus.checkedIn,
      action: AppAction.checkInWorkOrder,
      reason: manualOverrideReason,
      latitude: latitude,
      longitude: longitude,
      locationSource: locationSource,
    );
  }

  /// Starting work also starts the work timer (Section 11: "Technician
  /// starts work timer") - `actualStart` is only set if not already set,
  /// so resuming from a blocker doesn't reset the clock.
  Future<void> startWork(String workOrderId) async {
    final db = ref.read(appDatabaseProvider);
    final workOrder = await db.workOrderDao.byId(workOrderId);
    await _transition(
      workOrderId: workOrderId,
      newStatus: WorkOrderStatus.inProgress,
      action: AppAction.startWorkOrder,
      actualStart: workOrder?.actualStart ?? DateTime.now(),
    );
  }

  /// Technician could not continue - captures a mandatory [blockerReason]
  /// (Section 11/69: "every exception requires an auditable reason").
  Future<void> reportBlocked(String workOrderId, String blockerReason) =>
      _transition(
        workOrderId: workOrderId,
        newStatus: WorkOrderStatus.blocked,
        action: AppAction.startWorkOrder,
        blockerReason: blockerReason,
      );

  Future<void> resume(String workOrderId) => _transition(
        workOrderId: workOrderId,
        newStatus: WorkOrderStatus.resumed,
        action: AppAction.startWorkOrder,
      );

  /// Stops the work timer and records total elapsed minutes (Section 29:
  /// `actual_minutes`) before moving to Work Completed.
  Future<void> submitCompletion(String workOrderId, {String? resolutionNote}) async {
    final db = ref.read(appDatabaseProvider);
    final workOrder = await db.workOrderDao.byId(workOrderId);
    final now = DateTime.now();
    final start = workOrder?.actualStart;
    final minutes = start != null ? now.difference(start).inMinutes : null;

    await _transition(
      workOrderId: workOrderId,
      newStatus: WorkOrderStatus.workCompleted,
      action: AppAction.completeWorkOrder,
      reason: resolutionNote,
      actualEnd: now,
      actualMinutes: minutes,
    );
  }

  Future<void> verify(String workOrderId) => _transition(
        workOrderId: workOrderId,
        newStatus: WorkOrderStatus.verified,
        action: AppAction.verifyWorkOrder,
      );
}
