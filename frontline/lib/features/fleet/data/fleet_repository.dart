/// Syncs the driver's assigned vehicle (Section 48, Screen 48) and
/// pushes trip start/end records. Fleet-wide management (Screen 47) is
/// a Main Application / Fleet Manager concern, not this app's job.
abstract interface class FleetRepository {
  Future<void> syncAssignedVehicle(String driverId);

  Future<void> pushTrip(String tripId);
}
