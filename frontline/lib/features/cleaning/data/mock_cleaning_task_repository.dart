import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/fixtures/fixture_loader.dart';
import 'cleaning_task_repository.dart';

/// Backs Screen 21 from `assets/fixtures/cleaning_tasks.json` and
/// `assets/fixtures/cleaning_task_inspection_points.json`.
class MockCleaningTaskRepository implements CleaningTaskRepository {
  MockCleaningTaskRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> syncAssignedTasks({required String userId, required String siteId}) async {
    final tasks = await FixtureLoader.loadJson('assets/fixtures/cleaning_tasks.json') as List;

    await _db.transaction(() async {
      for (final t in tasks.cast<Map<String, dynamic>>()) {
        if (t['siteId'] != siteId || t['assignedUserId'] != userId) continue;

        await _db.cleaningTaskDao.upsertFromServer(CleaningTasksCompanion.insert(
          id: t['id'] as String,
          siteId: t['siteId'] as String,
          spaceId: t['spaceId'] as String,
          cleaningType: t['cleaningType'] as String,
          sopNote: Value(t['sopNote'] as String?),
          frequency: t['frequency'] as String,
          expectedMinutes: Value((t['expectedMinutes'] as num?)?.toInt()),
          assignedUserId: Value(t['assignedUserId'] as String?),
          materialsNote: Value(t['materialsNote'] as String?),
          photoRequired: Value(t['photoRequired'] as bool? ?? false),
          status: Value(t['status'] as String? ?? 'pending'),
          scheduledDate: FixtureLoader.resolveOffset(t, 'scheduledDate') ?? DateTime.now(),
          lastCleanAt: Value(FixtureLoader.resolveOffset(t, 'lastClean')),
          updatedAt: DateTime.now(),
        ));
      }
    });

    final points = await FixtureLoader.loadJson(
      'assets/fixtures/cleaning_task_inspection_points.json',
    ) as List;
    await _db.transaction(() async {
      for (final p in points.cast<Map<String, dynamic>>()) {
        final task = tasks.cast<Map<String, dynamic>>().firstWhere(
            (t) => t['id'] == p['cleaningTaskId'],
            orElse: () => const {});
        if (task['siteId'] != siteId || task['assignedUserId'] != userId) continue;

        await _db.cleaningTaskDao.upsertInspectionPoint(
          CleaningTaskInspectionPointsCompanion.insert(
            id: p['id'] as String,
            cleaningTaskId: p['cleaningTaskId'] as String,
            sequence: (p['sequence'] as num).toInt(),
            description: p['description'] as String,
          ),
        );
      }
    });
  }

  @override
  Future<void> pushCompletion(String cleaningTaskId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await _db.cleaningTaskDao.clearPendingFlag(cleaningTaskId);
  }
}
