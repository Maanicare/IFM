import 'package:dio/dio.dart';

import '../../../core/db/app_database.dart';
import 'safety_repository.dart';

class HttpSafetyRepository implements SafetyRepository {
  HttpSafetyRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> pushIncident(String incidentId) async {
    final incident = await (_db.select(_db.incidents)
          ..where((t) => t.id.equals(incidentId)))
        .getSingleOrNull();
    if (incident == null) return;
    await _dio.post<void>('/v1/incidents', data: {
      'id': incident.id,
      'incident_number': incident.incidentNumber,
      'site_id': incident.siteId,
      'space_id': incident.spaceId,
      'type': incident.type,
      'severity': incident.severity,
      'occurred_at': incident.occurredAt.toIso8601String(),
      'reported_by': incident.reportedBy,
      'description': incident.description,
      'asset_id': incident.assetId,
      'injury': incident.injury,
      'immediate_action': incident.immediateAction,
    });
  }

  @override
  Future<void> pushHazard(String hazardId) async {
    final hazard = await (_db.select(_db.hazards)
          ..where((t) => t.id.equals(hazardId)))
        .getSingleOrNull();
    if (hazard == null) return;
    await _dio.post<void>('/v1/hazards', data: {
      'id': hazard.id,
      'site_id': hazard.siteId,
      'space_id': hazard.spaceId,
      'category': hazard.category,
      'description': hazard.description,
      'risk_probability': hazard.riskProbability,
      'risk_consequence': hazard.riskConsequence,
      'risk_score': hazard.riskScore,
      'reported_by': hazard.reportedBy,
    });
  }
}
