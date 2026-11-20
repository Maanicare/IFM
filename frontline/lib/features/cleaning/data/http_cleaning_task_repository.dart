import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'cleaning_task_repository.dart';

class HttpCleaningTaskRepository implements CleaningTaskRepository {
  HttpCleaningTaskRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> syncAssignedTasks({required String userId, required String siteId}) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/sites/$siteId/cleaning-tasks',
      queryParameters: {'assigned_user_id': userId},
    );
    final list = response.data ?? const [];

    await _db.transaction(() async {
      for (final t in list.cast<Map<String, dynamic>>()) {
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
          scheduledDate: t['scheduledDate'] != null
              ? DateTime.parse(t['scheduledDate'] as String)
              : DateTime.now(),
          lastCleanAt: Value(
            t['lastCleanAt'] != null ? DateTime.parse(t['lastCleanAt'] as String) : null,
          ),
          updatedAt: DateTime.now(),
        ));

        final points = t['inspectionPoints'] as List<dynamic>? ?? const [];
        for (final p in points.cast<Map<String, dynamic>>()) {
          await _db.cleaningTaskDao.upsertInspectionPoint(
            CleaningTaskInspectionPointsCompanion.insert(
              id: p['id'] as String,
              cleaningTaskId: t['id'] as String,
              sequence: (p['sequence'] as num).toInt(),
              description: p['description'] as String,
            ),
          );
        }
      }
    });
  }

  @override
  Future<void> pushCompletion(String cleaningTaskId) async {
    final task = await _db.cleaningTaskDao.byId(cleaningTaskId);
    if (task == null) return;
    await _dio.patch<void>('/v1/cleaning-tasks/$cleaningTaskId/completion', data: {
      'status': task.status,
      'completed_at': task.completedAt?.toIso8601String(),
      'consumables_note': task.consumablesNote,
      'exception_note': task.exceptionNote,
    });
    await _db.cleaningTaskDao.clearPendingFlag(cleaningTaskId);
  }
}
