import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'washroom_repository.dart';

class HttpWashroomRepository implements WashroomRepository {
  HttpWashroomRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> syncForSite(String siteId) async {
    final response = await _dio.get<List<dynamic>>('/v1/sites/$siteId/washrooms');
    final list = response.data ?? const [];

    await _db.transaction(() async {
      for (final w in list.cast<Map<String, dynamic>>()) {
        await _db.washroomDao.upsertFromServer(WashroomsCompanion.insert(
          id: w['id'] as String,
          siteId: w['siteId'] as String,
          spaceId: w['spaceId'] as String,
          qrCode: w['qrCode'] as String,
          cleaningStatus: Value(w['cleaningStatus'] as String? ?? 'clean'),
          lastAttendedAt: Value(
            w['lastAttendedAt'] != null ? DateTime.parse(w['lastAttendedAt'] as String) : null,
          ),
          nextDueAt: Value(
            w['nextDueAt'] != null ? DateTime.parse(w['nextDueAt'] as String) : null,
          ),
          tissueStatus: Value(w['tissueStatus'] as String? ?? 'ok'),
          soapStatus: Value(w['soapStatus'] as String? ?? 'ok'),
          sensorAlertNote: Value(w['sensorAlertNote'] as String?),
          updatedAt: DateTime.now(),
        ));
      }
    });
  }
}
