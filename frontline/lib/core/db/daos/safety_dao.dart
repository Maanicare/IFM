import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/safety_tables.dart';

part 'safety_dao.g.dart';

@DriftAccessor(tables: [Incidents, Hazards])
class SafetyDao extends DatabaseAccessor<AppDatabase> with _$SafetyDaoMixin {
  SafetyDao(super.db);

  Future<void> insertIncident(IncidentsCompanion row) =>
      into(incidents).insert(row);

  Future<void> upsertIncidentFromServer(IncidentsCompanion row) =>
      into(incidents).insertOnConflictUpdate(row);

  Stream<List<Incident>> watchIncidentsForSite(String siteId) {
    return (select(incidents)
          ..where((t) => t.siteId.equals(siteId))
          ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
        .watch();
  }

  Future<void> insertHazard(HazardsCompanion row) =>
      into(hazards).insert(row);

  Future<void> upsertHazardFromServer(HazardsCompanion row) =>
      into(hazards).insertOnConflictUpdate(row);

  Stream<List<Hazard>> watchHazardsForSite(String siteId) {
    return (select(hazards)
          ..where((t) => t.siteId.equals(siteId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }
}
