import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/exceptions.dart';
import 'work_order_repository.dart';

class HttpWorkOrderRepository implements WorkOrderRepository {
  HttpWorkOrderRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> syncAssignedWorkOrders({
    required String userId,
    required String siteId,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/v1/sites/$siteId/work-orders',
      queryParameters: {'assigned_user_id': userId},
    );
    final list = response.data ?? const [];

    await _db.transaction(() async {
      for (final w in list.cast<Map<String, dynamic>>()) {
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
          scheduledStart: Value(
            w['scheduledStart'] != null
                ? DateTime.parse(w['scheduledStart'] as String)
                : null,
          ),
          scheduledEnd: Value(
            w['scheduledEnd'] != null
                ? DateTime.parse(w['scheduledEnd'] as String)
                : null,
          ),
          estimatedMinutes: Value((w['estimatedMinutes'] as num?)?.toInt()),
          problemDescription: Value(w['problemDescription'] as String?),
          checklistId: Value(w['checklistId'] as String?),
          slaResponseTarget: Value(
            w['slaResponseTarget'] != null
                ? DateTime.parse(w['slaResponseTarget'] as String)
                : null,
          ),
          slaResolutionTarget: Value(
            w['slaResolutionTarget'] != null
                ? DateTime.parse(w['slaResolutionTarget'] as String)
                : null,
          ),
          serverVersion: Value((w['serverVersion'] as num?)?.toInt() ?? 1),
          updatedAt: DateTime.now(),
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
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/v1/work-orders/$workOrderId/status',
        data: {
          'status': newStatus,
          'reason': reason,
          'base_server_version': baseServerVersion,
          'changed_by': changedBy,
          'actual_start': actualStart?.toIso8601String(),
          'actual_end': actualEnd?.toIso8601String(),
          'actual_minutes': actualMinutes,
          'latitude': latitude,
          'longitude': longitude,
          'location_source': locationSource,
        },
      );
      final newVersion = response.data?['serverVersion'] as int? ??
          (baseServerVersion ?? 0) + 1;
      return PushResult(newServerVersion: newVersion);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final remote = e.response?.data as Map<String, dynamic>? ?? const {};
        throw SyncConflictError(
          message: remote['message'] as String? ??
              'This work order changed on the server before your update '
                  'could be applied.',
          entityType: 'work_order',
          entityId: workOrderId,
          localPayload: {'status': newStatus, 'reason': reason},
          remotePayload: remote,
        );
      }
      rethrow;
    }
  }
}
