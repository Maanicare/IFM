import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/soft_service_inspection_tables.dart';

part 'soft_service_inspection_dao.g.dart';

@DriftAccessor(tables: [SoftServiceInspections])
class SoftServiceInspectionDao extends DatabaseAccessor<AppDatabase>
    with _$SoftServiceInspectionDaoMixin {
  SoftServiceInspectionDao(super.db);

  Stream<List<SoftServiceInspection>> watchForSite(String siteId) {
    return (select(softServiceInspections)
          ..where((t) => t.siteId.equals(siteId))
          ..orderBy([(t) => OrderingTerm.desc(t.inspectedAt)]))
        .watch();
  }

  Future<SoftServiceInspection?> byId(String id) =>
      (select(softServiceInspections)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insert(SoftServiceInspectionsCompanion row) =>
      into(softServiceInspections).insert(row);
}
