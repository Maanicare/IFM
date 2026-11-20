import 'package:dio/dio.dart';

import '../../../core/db/app_database.dart';
import 'inspection_repository.dart';

class HttpInspectionRepository implements InspectionRepository {
  HttpInspectionRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> pushInspection(String inspectionId) async {
    final inspection = await _db.softServiceInspectionDao.byId(inspectionId);
    if (inspection == null) return;
    await _dio.post<void>('/v1/soft-service-inspections', data: {
      'id': inspection.id,
      'site_id': inspection.siteId,
      'space_id': inspection.spaceId,
      'template': inspection.template,
      'score': inspection.score,
      'non_conformance_note': inspection.nonConformanceNote,
      'corrective_task_note': inspection.correctiveTaskNote,
      'corrective_owner_name': inspection.correctiveOwnerName,
      'corrective_due_date': inspection.correctiveDueDate?.toIso8601String(),
      'inspected_by': inspection.inspectedBy,
      'inspected_at': inspection.inspectedAt.toIso8601String(),
    });
  }

  @override
  Future<void> pushCorrectiveComplete(String inspectionId) async {
    await _dio.patch<void>('/v1/soft-service-inspections/$inspectionId/corrective-complete');
  }
}
