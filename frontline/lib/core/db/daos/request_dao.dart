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

  Stream<ServiceRequest?> watchById(String id) =>
      (select(serviceRequests)..where((t) => t.id.equals(id)))
          .watchSingleOrNull();

  /// Screen 07 action: "Assign" - to a team/trade, not an individual
  /// (this app has no synced user directory).
  Future<void> assignTeam(String id, String team) {
    return (update(serviceRequests)..where((t) => t.id.equals(id))).write(
      ServiceRequestsCompanion(assignedTeam: Value(team)),
    );
  }

  /// Screen 07 action: "Escalate".
  Future<void> escalate(String id, {required String bumpedPriority}) {
    return (update(serviceRequests)..where((t) => t.id.equals(id))).write(
      ServiceRequestsCompanion(escalated: const Value(true), priority: Value(bumpedPriority)),
    );
  }

  /// Screen 07 action: "Change priority".
  Future<void> changePriority(String id, String priority) {
    return (update(serviceRequests)..where((t) => t.id.equals(id))).write(
      ServiceRequestsCompanion(priority: Value(priority)),
    );
  }

  /// Screen 07 action: "Cancel".
  Future<void> cancel(String id) {
    return (update(serviceRequests)..where((t) => t.id.equals(id))).write(
      const ServiceRequestsCompanion(status: Value('cancelled')),
    );
  }

  Future<void> upsertFromServer(ServiceRequestsCompanion row) =>
      into(serviceRequests).insertOnConflictUpdate(row);

  Future<void> insertLocal(ServiceRequestsCompanion row) =>
      into(serviceRequests).insert(row);

  /// Section 63 (Universal Search).
  Future<List<ServiceRequest>> searchAtSite(String siteId, String query) {
    final like = '%$query%';
    return (select(serviceRequests)
          ..where((t) =>
              t.siteId.equals(siteId) &
              (t.requestNumber.like(like) | t.title.like(like)))
          ..limit(20))
        .get();
  }
}
