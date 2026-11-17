import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/util/id_generator.dart';
import 'request_repository.dart';

class HttpRequestRepository implements RequestRepository {
  HttpRequestRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> syncRequestsForSite(String siteId) async {
    final response =
        await _dio.get<List<dynamic>>('/v1/sites/$siteId/requests');
    final list = response.data ?? const [];

    await _db.transaction(() async {
      for (final r in list.cast<Map<String, dynamic>>()) {
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
          createdAt: DateTime.parse(r['createdAt'] as String),
          responseDueAt: Value(
            r['responseDueAt'] != null
                ? DateTime.parse(r['responseDueAt'] as String)
                : null,
          ),
          resolutionDueAt: Value(
            r['resolutionDueAt'] != null
                ? DateTime.parse(r['resolutionDueAt'] as String)
                : null,
          ),
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
    final request = await _db.requestDao.byId(requestId);
    if (request == null) return;
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/requests',
      data: {
        'client_id': request.id,
        'site_id': request.siteId,
        'space_id': request.spaceId,
        'asset_id': request.assetId,
        'category_id': request.categoryId,
        'title': request.title,
        'description': request.description,
        'priority': request.priority,
        'requester_id': request.requesterId,
        'source': request.source,
        'affected_people_count': request.affectedPeopleCount,
        'safety_concern': request.safetyConcern,
      },
    );
    final serverNumber = response.data?['requestNumber'] as String?;
    if (serverNumber != null) {
      await _db.requestDao.upsertFromServer(ServiceRequestsCompanion(
        id: Value(request.id),
        requestNumber: Value(serverNumber),
      ));
    }
  }
}
