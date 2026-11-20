/// Pushes visitor check-ins/check-outs recorded on this device (Screen
/// 44). This app only ever creates and checks out its own visits, never
/// syncs a pre-registered expected-visitor list down - full visitor
/// pre-registration/host-notification is a manager/desktop concern.
abstract interface class VisitorRepository {
  Future<void> pushVisit(String visitId);
  Future<void> pushCheckOut(String visitId);
}
