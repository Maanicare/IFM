/// Syncs washroom status (Screen 22) for a site - read-only on this
/// device, configured/updated server-side (presumably from Screen 21's
/// cleaning-task completions and sensor feeds where available).
abstract interface class WashroomRepository {
  Future<void> syncForSite(String siteId);
}
