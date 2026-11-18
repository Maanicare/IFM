import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/fixtures/fixture_loader.dart';
import '../../../core/util/id_generator.dart';
import 'request_repository.dart';

class MockRequestRepository implements RequestRepository {
  MockRequestRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> syncRequestsForSite(String siteId) async {
    final list =
        await FixtureLoader.loadJson('assets/fixtures/requests.json') as List;

    await _db.transaction(() async {
      for (final r in list.cast<Map<String, dynamic>>()) {
        if (r['siteId'] != siteId) continue;
        await _db.requestDao.upsertFromServer(ServiceRequestsCompanion.insert(
          id: r['id'] as String,
          requestNumber: r['requestNumber'] as String,
          requesterId: Value(r['requesterId'] as String?),
          siteId: r['siteId'] as String,
          spaceId: Value(r['spaceId'] as String?),
          assetId: Value(r['assetId'] as String?),
          categoryId: r['categoryId'] as String,
          title: r['title'] as String,
          description: Value(r['description'] as String?),
          priority: r['priority'] as String,
          status: r['status'] as String,
          source: r['source'] as String,
          createdAt: FixtureLoader.resolveOffset(r, 'createdAt') ??
              DateTime.now(),
          responseDueAt: Value(FixtureLoader.resolveOffset(r, 'responseDue')),
          resolutionDueAt:
              Value(FixtureLoader.resolveOffset(r, 'resolutionDue')),
        ));
      }
    });
  }

  @override
  Future<String> createRequest({
    required String siteId,
    String? spaceId,
    String? assetId,
    required String categoryId,
    required String title,
    String? description,
    required String priority,
    required String requesterId,
    required String source,
    int? affectedPeopleCount,
    bool safetyConcern = false,
  }) async {
    final id = IdGenerator.newId();
    final now = DateTime.now();
    await _db.requestDao.insertLocal(ServiceRequestsCompanion.insert(
      id: id,
      requestNumber: 'LOCAL-${id.substring(0, 8).toUpperCase()}',
      requesterId: Value(requesterId),
      siteId: siteId,
      spaceId: Value(spaceId),
      assetId: Value(assetId),
      categoryId: categoryId,
      title: title,
      description: Value(description),
      priority: priority,
      status: 'new',
      source: source,
      createdAt: now,
      affectedPeopleCount: Value(affectedPeopleCount),
      safetyConcern: Value(safetyConcern),
    ));
    return id;
  }

  @override
  Future<void> pushNewRequest(String requestId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> pushUpdate(String requestId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
