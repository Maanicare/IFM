import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/asset_tables.dart';

part 'asset_dao.g.dart';

/// Backs the Scan screen (Section: SCREEN 11) - resolving a scanned QR
/// code to full asset context entirely from the local cache.
@DriftAccessor(tables: [Assets, AssetMeters, MeterReadings, AssetDocuments])
class AssetDao extends DatabaseAccessor<AppDatabase> with _$AssetDaoMixin {
  AssetDao(super.db);

  /// Section 63 (Universal Search).
  Future<List<Asset>> searchAtSite(String siteId, String query) {
    final like = '%$query%';
    return (select(assets)
          ..where((t) =>
              t.siteId.equals(siteId) &
              (t.name.like(like) | t.assetCode.like(like)))
          ..limit(20))
        .get();
  }

  /// Screen 06 (Create Request): the "Asset" optional field's generic
  /// picker, for a request not raised from a Scan.
  Future<List<Asset>> forSite(String siteId) =>
      (select(assets)..where((t) => t.siteId.equals(siteId))).get();

  Future<Asset?> byQrCode(String qrCode) =>
      (select(assets)..where((t) => t.qrCode.equals(qrCode)))
          .getSingleOrNull();

  Future<Asset?> byId(String id) =>
      (select(assets)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Asset?> watchById(String id) =>
      (select(assets)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Assets that are down or flagged critical at a site - backs the Home
  /// screen's "Critical assets" row (Section 8: Technician Home).
  Stream<List<Asset>> watchCriticalAtSite(String siteId) {
    return (select(assets)
          ..where((t) =>
              t.siteId.equals(siteId) &
              (t.status.equals('down') | t.criticality.equals('critical'))))
        .watch();
  }

  Future<void> upsertFromServer(AssetsCompanion row) =>
      into(assets).insertOnConflictUpdate(row);

  Future<List<AssetMeter>> metersFor(String assetId) =>
      (select(assetMeters)..where((t) => t.assetId.equals(assetId))).get();

  Future<void> upsertMeterFromServer(AssetMetersCompanion row) =>
      into(assetMeters).insertOnConflictUpdate(row);

  /// Writes a technician-captured meter reading locally. The caller is
  /// responsible for enqueueing the matching outbox entry in the same
  /// repository-level transaction.
  Future<void> recordReading(MeterReadingsCompanion reading) =>
      into(meterReadings).insert(reading);

  /// Keeps the meter's own "current value" in sync with its latest
  /// reading, so the Asset Profile / Work Order screens can show it
  /// without a separate query against [MeterReadings] every time.
  Future<void> updateMeterCurrentValue({
    required String meterId,
    required double value,
    required DateTime updatedAt,
  }) {
    return (update(assetMeters)..where((t) => t.id.equals(meterId))).write(
      AssetMetersCompanion(
        currentValue: Value(value),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  /// Documents for the Asset Profile screen (Screen 12). Read-only -
  /// synced from the server, never authored on the device.
  Future<List<AssetDocument>> documentsFor(String assetId) =>
      (select(assetDocuments)..where((t) => t.assetId.equals(assetId))).get();

  Future<void> upsertDocumentFromServer(AssetDocumentsCompanion row) =>
      into(assetDocuments).insertOnConflictUpdate(row);
}
