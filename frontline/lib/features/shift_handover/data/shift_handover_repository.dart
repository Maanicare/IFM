/// Syncs the latest shift handover for a site (Screen 26) and pushes
/// locally-created handovers/acknowledgements.
abstract interface class ShiftHandoverRepository {
  Future<void> syncLatestForSite(String siteId);

  Future<void> pushNewHandover(String handoverId);

  Future<void> pushAcknowledgement({
    required String handoverId,
    required String acknowledgedBy,
    required DateTime acknowledgedAt,
  });
}
