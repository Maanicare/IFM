/// Backs Journey 1 ("Employee reports an issue") and the Request List/
/// Detail screens (Sections 9, SCREEN 05-07).
abstract interface class RequestRepository {
  Future<void> syncRequestsForSite(String siteId);

  /// Creates a new request. Writes locally immediately (so the requester
  /// gets an instant ticket number even offline) and returns the
  /// client-generated id; the outbox entry carries the push to the server.
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
  });

  Future<void> pushNewRequest(String requestId);
}
