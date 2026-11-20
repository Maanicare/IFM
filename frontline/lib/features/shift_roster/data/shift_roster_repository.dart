/// Syncs today's shift roster for a site (Screen 25) and pushes
/// self-service attendance changes (mark absent / request relief).
abstract interface class ShiftRosterRepository {
  Future<void> syncForSite(String siteId);

  Future<void> pushAttendanceChange({
    required String rosterEntryId,
    required String status,
  });

  /// Screen 25 action: "Swap" - pushes both sides of a shift-time swap.
  Future<void> pushSwap({required String entryIdA, required String entryIdB});

  /// Screen 25 action: "Replace".
  Future<void> pushReplacement(String rosterEntryId);
}
