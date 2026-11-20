import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/visitor_tables.dart';

part 'visitor_dao.g.dart';

@DriftAccessor(tables: [Visits])
class VisitorDao extends DatabaseAccessor<AppDatabase> with _$VisitorDaoMixin {
  VisitorDao(super.db);

  Stream<List<Visit>> watchForSite(String siteId) {
    return (select(visits)
          ..where((t) => t.siteId.equals(siteId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<Visit?> watchById(String id) =>
      (select(visits)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<Visit?> byId(String id) =>
      (select(visits)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Screen 11 (Scan): resolves a scanned visitor pass QR.
  Future<Visit?> byPassId(String passId) =>
      (select(visits)..where((t) => t.passId.equals(passId))).getSingleOrNull();

  Future<void> insert(VisitsCompanion row) => into(visits).insert(row);

  Future<void> checkOut(String id) {
    return (update(visits)..where((t) => t.id.equals(id))).write(
      VisitsCompanion(status: const Value('checked_out'), actualDeparture: Value(DateTime.now())),
    );
  }
}
