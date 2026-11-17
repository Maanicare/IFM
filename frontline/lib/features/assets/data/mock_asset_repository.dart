import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/fixtures/fixture_loader.dart';
import 'asset_repository.dart';

class MockAssetRepository implements AssetRepository {
  MockAssetRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> syncAssetsForSite(String siteId) async {
    final list = await FixtureLoader.loadJson('assets/fixtures/assets.json')
        as List;

    await _db.transaction(() async {
      for (final a in list.cast<Map<String, dynamic>>()) {
        if (a['siteId'] != siteId) continue;
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
          repeatFailureCount: Value((a['repeatFailureCount'] as num?)?.toInt() ?? 0),
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
      }
    });

    final documents = await FixtureLoader.loadJson(
      'assets/fixtures/asset_documents.json',
    ) as List;
    await _db.transaction(() async {
      for (final d in documents.cast<Map<String, dynamic>>()) {
        await _db.assetDao.upsertDocumentFromServer(AssetDocumentsCompanion.insert(
          id: d['id'] as String,
          assetId: d['assetId'] as String,
          documentType: d['documentType'] as String,
          title: d['title'] as String,
          url: d['url'] as String,
        ));
      }
    });

    final meters = await FixtureLoader.loadJson(
      'assets/fixtures/asset_meters.json',
    ) as List;
    await _db.transaction(() async {
      for (final m in meters.cast<Map<String, dynamic>>()) {
        await _db.assetDao.upsertMeterFromServer(AssetMetersCompanion.insert(
          id: m['id'] as String,
          assetId: m['assetId'] as String,
          meterType: m['meterType'] as String,
          unit: m['unit'] as String,
          currentValue: Value((m['currentValue'] as num?)?.toDouble()),
          updatedAt: Value(DateTime.now()),
        ));
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
    // Mock mode has no backend to push to - the local write (performed by
    // the caller before this method runs) is the entire effect. We just
    // simulate network latency so the sync UI behaves realistically.
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
