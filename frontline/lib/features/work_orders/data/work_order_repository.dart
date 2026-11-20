/// Result of successfully pushing a queued work-order mutation to the
/// server: the authoritative version counter after the write, used to
/// keep the local optimistic-concurrency state in sync.
class PushResult {
  const PushResult({required this.newServerVersion});
  final int newServerVersion;
}

/// Syncs work orders (Section 29) assigned to the current user, and pushes
/// queued status transitions through to the server with optimistic
/// concurrency control.
abstract interface class WorkOrderRepository {
  Future<void> syncAssignedWorkOrders({
    required String userId,
    required String siteId,
  });

  /// Pushes one queued status transition. [baseServerVersion] is the
  /// version the mutation was computed against; implementations must
  /// throw [SyncConflictError] (see core/error/exceptions.dart) if the
  /// server's current version for [workOrderId] has since moved past it.
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
  });

  /// Screen 07 "Convert": pushes a work order that was created directly
  /// on the device (see [WorkOrderDao.insertLocal]) to the server.
  Future<void> pushNewWorkOrder(String workOrderId);
}
