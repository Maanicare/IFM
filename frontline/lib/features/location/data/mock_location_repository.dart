import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/fixtures/fixture_loader.dart';
import 'location_repository.dart';

/// Reads `assets/fixtures/locations.json` and seeds the local hierarchy
/// tables. Safe to call repeatedly - every row is an upsert.
class MockLocationRepository implements LocationRepository {
  MockLocationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> syncHierarchyForOrganisation(String organisationId) async {
    final data = await FixtureLoader.loadJson('assets/fixtures/locations.json')
        as Map<String, dynamic>;

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
          region: Value(site['region'] as String?),
          portfolioName: Value(site['portfolioName'] as String?),
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
