/// Pushes field-reported soft-service inspections (Screen 23). This app
/// only ever creates these, never syncs a list down - review/closure of
/// corrective actions happens on the manager/desktop surface.
abstract interface class InspectionRepository {
  Future<void> pushInspection(String inspectionId);
}
