import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/work_order_tables.dart';

part 'work_order_dao.g.dart';

/// Queries backing the Technician "My Work" screen (Now/Next/Later) and the
/// Work Order detail screen.
@DriftAccessor(tables: [WorkOrders, WorkOrderStatusHistory])
class WorkOrderDao extends DatabaseAccessor<AppDatabase>
    with _$WorkOrderDaoMixin {
  WorkOrderDao(super.db);

  Stream<List<WorkOrder>> watchAssignedTo(String userId) {
    return (select(workOrders)
          ..where((t) =>
              t.assignedUserId.equals(userId) &
              t.status.isNotIn(const [
                'closed',
                'cancelled',
                'rejected',
                'duplicate',
              ]))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledStart)]))
        .watch();
  }

  /// All open work orders at a site, regardless of assignee - used to
  /// auto-populate the "Open jobs" line of a shift handover (Screen 26)
  /// with what's actually still open at the site, not just this one
  /// technician's own assignments.
  Future<List<WorkOrder>> openAtSite(String siteId) {
    return (select(workOrders)
          ..where((t) =>
              t.siteId.equals(siteId) &
              t.status.isNotIn(const [
                'closed',
                'cancelled',
                'rejected',
                'duplicate',
                'verified',
              ])))
        .get();
  }

  /// Every work order ever raised against an asset, oldest first - the
  /// Asset Profile screen (Screen 12) derives "Open WO", "Failure
  /// history" and MTBF/MTTR from this rather than the server
  /// pre-computing and shipping them as separate fields.
  Future<List<WorkOrder>> forAsset(String assetId) {
    return (select(workOrders)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledStart)]))
        .get();
  }

  /// The work order a request escalated into, if any (Screen 07: "Linked
  /// work order").
  Future<WorkOrder?> byRequestId(String requestId) =>
      (select(workOrders)..where((t) => t.requestId.equals(requestId))).getSingleOrNull();

  Future<WorkOrder?> byId(String id) =>
      (select(workOrders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<WorkOrder?> watchById(String id) =>
      (select(workOrders)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> upsertFromServer(WorkOrdersCompanion row) =>
      into(workOrders).insertOnConflictUpdate(row);

  /// Applies a local status transition optimistically (before the outbox
  /// entry is confirmed by the server) so the UI reflects the technician's
  /// action immediately, and flags the row as having pending local changes
  /// so the sync engine knows not to let an incoming server snapshot
  /// silently overwrite it until the push resolves.
  Future<void> applyLocalStatusChange({
    required String workOrderId,
    required String newStatus,
    String? blockerReason,
    DateTime? actualStart,
    DateTime? actualEnd,
    int? actualMinutes,
  }) {
    return (update(workOrders)..where((t) => t.id.equals(workOrderId))).write(
      WorkOrdersCompanion(
        status: Value(newStatus),
        blockerReason: Value(blockerReason),
        hasPendingLocalChanges: const Value(true),
        updatedAt: Value(DateTime.now()),
        actualStart: actualStart != null ? Value(actualStart) : const Value.absent(),
        actualEnd: actualEnd != null ? Value(actualEnd) : const Value.absent(),
        actualMinutes: actualMinutes != null ? Value(actualMinutes) : const Value.absent(),
      ),
    );
  }

  Future<void> recordStatusHistory(WorkOrderStatusHistoryCompanion entry) =>
      into(workOrderStatusHistory).insert(entry);

  Future<List<WorkOrderStatusHistoryData>> historyFor(String workOrderId) {
    return (select(workOrderStatusHistory)
          ..where((t) => t.workOrderId.equals(workOrderId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  /// Saves the structured fields parsed from a voice note (Section
  /// 16.12). A plain field update, not a status transition - voice
  /// notes can be added at any point in the job's life.
  Future<void> updateVoiceFields({
    required String workOrderId,
    String? finding,
    String? reading,
    String? diagnosis,
    String? recommendation,
  }) {
    return (update(workOrders)..where((t) => t.id.equals(workOrderId))).write(
      WorkOrdersCompanion(
        voiceFindingNote: Value(finding),
        voiceReadingNote: Value(reading),
        voiceDiagnosisNote: Value(diagnosis),
        voiceRecommendationNote: Value(recommendation),
        hasPendingLocalChanges: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Jobs awaiting this site's sign-off (Screen 03: "Approvals") - work
  /// completed by a technician but not yet verified by a supervisor.
  /// Only meaningful to show to a role that can actually act on it
  /// (gated by `verifyWorkOrder`/`approveQuoteOrSpend` at the call
  /// site, not here).
  Stream<int> watchPendingApprovalCountAtSite(String siteId) {
    final countExp = workOrders.id.count();
    final query = selectOnly(workOrders)
      ..addColumns([countExp])
      ..where(workOrders.siteId.equals(siteId) & workOrders.status.equals('work_completed'));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Section 63 (Universal Search): "AHU 5 should return the asset,
  /// current work orders...".
  Future<List<WorkOrder>> searchAtSite(String siteId, String query) {
    final like = '%$query%';
    return (select(workOrders)
          ..where((t) =>
              t.siteId.equals(siteId) &
              (t.woNumber.like(like) | t.problemDescription.like(like)))
          ..limit(20))
        .get();
  }

  /// Section E (Closure): Root cause, Work performed, Remaining issue,
  /// Follow-up. A plain field update, not a status transition - a
  /// technician can fill these in while still `in_progress`, not only
  /// at the moment of submitting completion.
  Future<void> updateClosureDetails({
    required String workOrderId,
    String? rootCause,
    String? workPerformed,
    String? remainingIssue,
    String? followUp,
  }) {
    return (update(workOrders)..where((t) => t.id.equals(workOrderId))).write(
      WorkOrdersCompanion(
        rootCauseCode: Value(rootCause),
        resolutionCode: Value(workPerformed),
        remainingIssueNote: Value(remainingIssue),
        followUpNote: Value(followUp),
        hasPendingLocalChanges: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Section E (Closure): "QA" - set by whoever verifies the job
  /// (gated at the call site by `verifyWorkOrder`).
  Future<void> updateQaStatus(String workOrderId, String qaStatus) {
    return (update(workOrders)..where((t) => t.id.equals(workOrderId))).write(
      WorkOrdersCompanion(
        qaStatus: Value(qaStatus),
        hasPendingLocalChanges: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> clearPendingFlag(String workOrderId) {
    return (update(workOrders)..where((t) => t.id.equals(workOrderId))).write(
      const WorkOrdersCompanion(hasPendingLocalChanges: Value(false)),
    );
  }
}
