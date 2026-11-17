import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/request_tables.dart';

part 'request_dao.g.dart';

@DriftAccessor(tables: [ServiceRequests])
class RequestDao extends DatabaseAccessor<AppDatabase>
    with _$RequestDaoMixin {
  RequestDao(super.db);

  Stream<List<ServiceRequest>> watchForSite(String siteId) {
    return (select(serviceRequests)
          ..where((t) => t.siteId.equals(siteId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<ServiceRequest?> byId(String id) =>
      (select(serviceRequests)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsertFromServer(ServiceRequestsCompanion row) =>
      into(serviceRequests).insertOnConflictUpdate(row);

  Future<void> insertLocal(ServiceRequestsCompanion row) =>
      into(serviceRequests).insert(row);
}
