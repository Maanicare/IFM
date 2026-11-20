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

  /// Screen 34: lets whoever owns a corrective task mark it done, so
  /// "Corrective actions overdue" doesn't count it forever once it's
  /// actually resolved.
  Future<void> markCorrectiveComplete(String id) {
    return (update(softServiceInspections)..where((t) => t.id.equals(id))).write(
      const SoftServiceInspectionsCompanion(correctiveCompleted: Value(true)),
    );
  }
}
