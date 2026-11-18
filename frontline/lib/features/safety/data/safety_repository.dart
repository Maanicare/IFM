/// Pushes field-reported incidents and hazards (Sections 41-42). This
/// app only ever creates these, never syncs an incident/hazard list
/// down - investigation/closure happens on the manager/desktop surface.
abstract interface class SafetyRepository {
  Future<void> pushIncident(String incidentId);
  Future<void> pushHazard(String hazardId);
}
