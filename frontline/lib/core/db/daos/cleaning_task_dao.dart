import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/cleaning_task_tables.dart';

part 'cleaning_task_dao.g.dart';

/// Queries backing Screen 21 (Cleaning Task) - a Housekeeping Employee's
/// assigned tasks for the day, their inspection points, and completion
/// responses.
@DriftAccessor(tables: [
  CleaningTasks,
  CleaningTaskInspectionPoints,
  CleaningTaskInspectionResponses,
])
class CleaningTaskDao extends DatabaseAccessor<AppDatabase>
    with _$CleaningTaskDaoMixin {
  CleaningTaskDao(super.db);

  Stream<List<CleaningTask>> watchAssignedTo(String userId) {
    return (select(cleaningTasks)
          ..where((t) => t.assignedUserId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .watch();
  }

  Stream<CleaningTask?> watchById(String id) =>
      (select(cleaningTasks)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<CleaningTask?> byId(String id) =>
      (select(cleaningTasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertFromServer(CleaningTasksCompanion row) =>
      into(cleaningTasks).insertOnConflictUpdate(row);

  Future<void> upsertInspectionPoint(CleaningTaskInspectionPointsCompanion row) =>
      into(cleaningTaskInspectionPoints).insertOnConflictUpdate(row);

  Future<List<CleaningTaskInspectionPoint>> inspectionPointsFor(String cleaningTaskId) {
    return (select(cleaningTaskInspectionPoints)
          ..where((t) => t.cleaningTaskId.equals(cleaningTaskId))
          ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
        .get();
  }

  Stream<List<CleaningTaskInspectionResponse>> watchResponsesFor(String cleaningTaskId) {
    return (select(cleaningTaskInspectionResponses)
          ..where((t) => t.cleaningTaskId.equals(cleaningTaskId)))
        .watch();
  }

  Future<void> recordInspectionResponse(
    CleaningTaskInspectionResponsesCompanion response,
  ) {
    return into(cleaningTaskInspectionResponses).insertOnConflictUpdate(response);
  }

  Future<void> startTask(String cleaningTaskId) {
    return (update(cleaningTasks)..where((t) => t.id.equals(cleaningTaskId))).write(
      CleaningTasksCompanion(
        status: const Value('in_progress'),
        hasPendingLocalChanges: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Completion (Section 21): Consumables used, Exception - free-text
  /// notes, see the class doc on [CleaningTasks].
  Future<void> submitCompletion({
    required String cleaningTaskId,
    String? consumablesNote,
    String? exceptionNote,
  }) {
    final now = DateTime.now();
    return (update(cleaningTasks)..where((t) => t.id.equals(cleaningTaskId))).write(
      CleaningTasksCompanion(
        status: const Value('completed'),
        completedAt: Value(now),
        lastCleanAt: Value(now),
        consumablesNote: Value(consumablesNote),
        exceptionNote: Value(exceptionNote),
        hasPendingLocalChanges: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> clearPendingFlag(String cleaningTaskId) {
    return (update(cleaningTasks)..where((t) => t.id.equals(cleaningTaskId))).write(
      const CleaningTasksCompanion(hasPendingLocalChanges: Value(false)),
    );
  }
}
