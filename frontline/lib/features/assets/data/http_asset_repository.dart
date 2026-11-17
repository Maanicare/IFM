import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'asset_repository.dart';

class HttpAssetRepository implements AssetRepository {
  HttpAssetRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> syncAssetsForSite(String siteId) async {
    final response = await _dio
        .get<List<dynamic>>('/v1/sites/$siteId/assets');
    final list = response.data ?? const [];

    await _db.transaction(() async {
      for (final a in list.cast<Map<String, dynamic>>()) {
        await _db.assetDao.upsertFromServer(AssetsCompanion.insert(
          id: a['id'] as String,
          assetCode: a['assetCode'] as String,
          qrCode: a['qrCode'] as String,
          siteId: a['siteId'] as String,
          spaceId: Value(a['spaceId'] as String?),
          name: a['name'] as String,
          categoryId: a['categoryId'] as String,
          manufacturer: Value(a['manufacturer'] as String?),
          model: Value(a['model'] as String?),
          serialNumber: Value(a['serialNumber'] as String?),
          criticality: a['criticality'] as String,
          status: a['status'] as String,
          healthScore: Value((a['healthScore'] as num?)?.toDouble()),
          warrantyEndDate: Value(
            a['warrantyEndDate'] != null
                ? DateTime.parse(a['warrantyEndDate'] as String)
                : null,
          ),
          lastServiceDate: Value(
            a['lastServiceDate'] != null
                ? DateTime.parse(a['lastServiceDate'] as String)
                : null,
          ),
          repeatFailureCount:
              Value((a['repeatFailureCount'] as num?)?.toInt() ?? 0),
          purchaseDate: Value(
            a['purchaseDate'] != null ? DateTime.parse(a['purchaseDate'] as String) : null,
          ),
          purchaseCost: Value((a['purchaseCost'] as num?)?.toDouble()),
          vendorName: Value(a['vendorName'] as String?),
          amcEndDate: Value(
            a['amcEndDate'] != null ? DateTime.parse(a['amcEndDate'] as String) : null,
          ),
          nextServiceDate: Value(
            a['nextServiceDate'] != null ? DateTime.parse(a['nextServiceDate'] as String) : null,
          ),
        ));

        final documents = (a['documents'] as List?) ?? const [];
        for (final d in documents.cast<Map<String, dynamic>>()) {
          await _db.assetDao.upsertDocumentFromServer(AssetDocumentsCompanion.insert(
            id: d['id'] as String,
            assetId: a['id'] as String,
            documentType: d['documentType'] as String,
            title: d['title'] as String,
            url: d['url'] as String,
          ));
        }

        final meters = (a['meters'] as List?) ?? const [];
        for (final m in meters.cast<Map<String, dynamic>>()) {
          await _db.assetDao.upsertMeterFromServer(AssetMetersCompanion.insert(
            id: m['id'] as String,
            assetId: a['id'] as String,
            meterType: m['meterType'] as String,
            unit: m['unit'] as String,
            currentValue: Value((m['currentValue'] as num?)?.toDouble()),
            updatedAt: Value(DateTime.now()),
          ));
        }
      }
    });
  }

  @override
  Future<void> pushMeterReading({
    required String meterId,
    required double value,
    required DateTime capturedAt,
    required String capturedBy,
    String? workOrderId,
  }) async {
    await _dio.post<void>('/v1/meters/$meterId/readings', data: {
      'value': value,
      'captured_at': capturedAt.toIso8601String(),
      'captured_by': capturedBy,
      'source': 'manual',
      'work_order_id': ?workOrderId,
    });
  }
}
