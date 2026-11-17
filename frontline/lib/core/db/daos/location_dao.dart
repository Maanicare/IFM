import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/location_tables.dart';

part 'location_dao.g.dart';

@DriftAccessor(tables: [Sites, Buildings, Floors, Spaces])
class LocationDao extends DatabaseAccessor<AppDatabase>
    with _$LocationDaoMixin {
  LocationDao(super.db);

  Future<List<Site>> allSites() => select(sites).get();

  Future<Site?> siteById(String id) =>
      (select(sites)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Sites a user is assigned to (Screen 02: Role/Site Selector), in the
  /// order their access grant lists them rather than alphabetically, so a
  /// "primary" site configured first stays first in the picker.
  Future<List<Site>> sitesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (select(sites)..where((t) => t.id.isIn(ids))).get();
    final byId = {for (final s in rows) s.id: s};
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  Future<List<Building>> buildingsForSite(String siteId) =>
      (select(buildings)..where((t) => t.siteId.equals(siteId))).get();

  Future<Building?> buildingById(String id) =>
      (select(buildings)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Floor>> floorsForBuilding(String buildingId) =>
      (select(floors)..where((t) => t.buildingId.equals(buildingId))).get();

  Future<Floor?> floorById(String id) =>
      (select(floors)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Space>> spacesForFloor(String floorId) =>
      (select(spaces)..where((t) => t.floorId.equals(floorId))).get();

  Future<Space?> spaceById(String id) =>
      (select(spaces)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Resolves a scanned QR/barcode against a space code (Screen 11: Scan
  /// "can identify ... Space").
  Future<Space?> spaceByCode(String spaceCode) =>
      (select(spaces)..where((t) => t.spaceCode.equals(spaceCode))).getSingleOrNull();

  Future<void> upsertSite(SitesCompanion row) =>
      into(sites).insertOnConflictUpdate(row);
  Future<void> upsertBuilding(BuildingsCompanion row) =>
      into(buildings).insertOnConflictUpdate(row);
  Future<void> upsertFloor(FloorsCompanion row) =>
      into(floors).insertOnConflictUpdate(row);
  Future<void> upsertSpace(SpacesCompanion row) =>
      into(spaces).insertOnConflictUpdate(row);
}
