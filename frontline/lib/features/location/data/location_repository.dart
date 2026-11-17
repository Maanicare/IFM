/// Syncs the Site -> Building -> Floor -> Space hierarchy (Section 27) into
/// the local Drift cache. UI reads this data reactively straight from
/// [LocationDao]; the repository's only job is to keep the cache fresh.
abstract interface class LocationRepository {
  Future<void> syncHierarchyForOrganisation(String organisationId);
}
