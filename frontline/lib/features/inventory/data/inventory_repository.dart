/// Syncs the inventory catalogue/balances (Section 37) needed for the
/// "parts used" flow, and pushes technician-recorded consumption.
abstract interface class InventoryRepository {
  Future<void> syncCatalogueForSite(String siteId);

  /// Pushes a parts-consumption entry already written locally and
  /// outboxed by the caller before this is invoked.
  Future<void> pushIssue({
    required String transactionId,
    required String itemId,
    required String workOrderId,
    required double quantity,
    required String userId,
    required DateTime timestamp,
  });

  /// Screen 33 (Stock Transaction): pushes a Receive/Transfer/Return/
  /// Repair/Scrap/Adjustment entry already written locally.
  Future<void> pushTransaction(String transactionId);
}
