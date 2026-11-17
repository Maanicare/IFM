import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'location_repository.dart';

/// Live implementation backed by the Maanicare IFM REST API. Mirrors
/// [MockLocationRepository]'s upsert behaviour exactly so the UI layer is
/// identical regardless of `USE_MOCK`.
class HttpLocationRepository implements LocationRepository {
  HttpLocationRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> syncHierarchyForOrganisation(String organisationId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/organisations/$organisationId/location-hierarchy',
    );
    final data = response.data!;

    await _db.transaction(() async {
      for (final site in (data['sites'] as List).cast<Map<String, dynamic>>()) {
        await _db.locationDao.upsertSite(SitesCompanion.insert(
          id: site['id'] as String,
          code: site['code'] as String,
          name: site['name'] as String,
          timezone: site['timezone'] as String,
          latitude: Value((site['latitude'] as num?)?.toDouble()),
          longitude: Value((site['longitude'] as num?)?.toDouble()),
          operationalStatus: site['operationalStatus'] as String,
        ));
      }
      for (final b in (data['buildings'] as List).cast<Map<String, dynamic>>()) {
        await _db.locationDao.upsertBuilding(BuildingsCompanion.insert(
          id: b['id'] as String,
          siteId: b['siteId'] as String,
          name: b['name'] as String,
          floors: Value((b['floors'] as num?)?.toInt()),
        ));
      }
      for (final f in (data['floors'] as List).cast<Map<String, dynamic>>()) {
        await _db.locationDao.upsertFloor(FloorsCompanion.insert(
          id: f['id'] as String,
          buildingId: f['buildingId'] as String,
          name: f['name'] as String,
          floorNumber: Value(f['floorNumber'] as String?),
        ));
      }
      for (final s in (data['spaces'] as List).cast<Map<String, dynamic>>()) {
        await _db.locationDao.upsertSpace(SpacesCompanion.insert(
          id: s['id'] as String,
          floorId: s['floorId'] as String,
          spaceCode: s['spaceCode'] as String,
          name: s['name'] as String,
          spaceType: s['spaceType'] as String,
          criticality: Value(s['criticality'] as String? ?? 'normal'),
        ));
      }
    });
  }
}
