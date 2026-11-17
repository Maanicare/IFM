/// Syncs checklist templates (Section 35) into the local cache, and pushes
/// completed [ChecklistResponses] rows that the sync engine pulls off the
/// outbox.
abstract interface class ChecklistRepository {
  Future<void> syncTemplates();

  Future<void> pushResponse({
    required String workOrderId,
    required String itemId,
    required String responseJson,
    required String capturedBy,
    required DateTime capturedAt,
  });
}
