/// Syncs the asset register and meters (Sections 32-33) into the local
/// cache so Scan (SCREEN 11) and Asset Profile (SCREEN 12) work offline.
abstract interface class AssetRepository {
  Future<void> syncAssetsForSite(String siteId);

  /// Pushes a technician-captured meter reading. Used by the sync engine;
  /// the reading itself is already written locally and outboxed by the
  /// caller before this is invoked.
  Future<void> pushMeterReading({
    required String meterId,
    required double value,
    required DateTime capturedAt,
    required String capturedBy,
    String? workOrderId,
  });
}
