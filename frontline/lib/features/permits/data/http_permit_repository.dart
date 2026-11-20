import 'package:dio/dio.dart';

import '../../../core/db/app_database.dart';
import 'permit_repository.dart';

class HttpPermitRepository implements PermitRepository {
  HttpPermitRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> pushPermit(String permitId) async {
    final permit = await _db.permitDao.byId(permitId);
    if (permit == null) return;
    await _dio.post<void>('/v1/permits', data: {
      'id': permit.id,
      'permit_number': permit.permitNumber,
      'site_id': permit.siteId,
      'work_order_id': permit.workOrderId,
      'permit_type': permit.permitType,
      'vendor_name': permit.vendorName,
      'valid_from': permit.validFrom.toIso8601String(),
      'valid_to': permit.validTo.toIso8601String(),
      'risk_assessment_note': permit.riskAssessmentNote,
      'authorised_persons': permit.authorisedPersons,
      'controls_note': permit.controlsNote,
      'isolation_note': permit.isolationNote,
      'issuer_name': permit.issuerName,
      'receiver_name': permit.receiverName,
      'status': permit.status,
    });
  }

  @override
  Future<void> pushClose(String permitId) async {
    await _dio.patch<void>('/v1/permits/$permitId/close');
  }
}
