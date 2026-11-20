import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/permit_tables.dart';

part 'permit_dao.g.dart';

@DriftAccessor(tables: [Permits])
class PermitDao extends DatabaseAccessor<AppDatabase> with _$PermitDaoMixin {
  PermitDao(super.db);

  Stream<List<Permit>> watchForSite(String siteId) {
    return (select(permits)
          ..where((t) => t.siteId.equals(siteId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Screen 09 (Work Order Detail) Section C: the permit tied to this
  /// work order, if one has been issued.
  Stream<Permit?> watchForWorkOrder(String workOrderId) {
    return (select(permits)
          ..where((t) => t.workOrderId.equals(workOrderId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Stream<Permit?> watchById(String id) =>
      (select(permits)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<Permit?> byId(String id) =>
      (select(permits)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insert(PermitsCompanion row) => into(permits).insert(row);

  Future<void> closePermit(String id) {
    return (update(permits)..where((t) => t.id.equals(id))).write(
      PermitsCompanion(status: const Value('closed'), closedAt: Value(DateTime.now())),
    );
  }
}
