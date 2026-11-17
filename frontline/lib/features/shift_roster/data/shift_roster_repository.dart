/// Syncs today's shift roster for a site (Screen 25) and pushes
/// self-service attendance changes (mark absent / request relief).
abstract interface class ShiftRosterRepository {
  Future<void> syncForSite(String siteId);

  Future<void> pushAttendanceChange({
    required String rosterEntryId,
    required String status,
  });
}
