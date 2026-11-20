import 'package:dio/dio.dart';

import '../../../core/db/app_database.dart';
import 'visitor_repository.dart';

class HttpVisitorRepository implements VisitorRepository {
  HttpVisitorRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> pushVisit(String visitId) async {
    final v = await _db.visitorDao.byId(visitId);
    if (v == null) return;
    await _dio.post<void>('/v1/visits', data: {
      'id': v.id,
      'site_id': v.siteId,
      'visitor_name': v.visitorName,
      'visitor_mobile': v.visitorMobile,
      'visitor_email': v.visitorEmail,
      'company': v.company,
      'host_name': v.hostName,
      'purpose': v.purpose,
      'vehicle_number': v.vehicleNumber,
      'id_verified': v.idVerified,
      'id_type_note': v.idTypeNote,
      'access_requirements_note': v.accessRequirementsNote,
      'actual_arrival': v.actualArrival?.toIso8601String(),
      'status': v.status,
      'pass_id': v.passId,
    });
  }

  @override
  Future<void> pushCheckOut(String visitId) async {
    await _dio.patch<void>('/v1/visits/$visitId/check-out');
  }
}
