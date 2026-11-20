/// Pushes field-issued permits (Screen 37). This app only ever creates
/// and closes them, never syncs a list down - full permit
/// administration (templates, authorised-persons registers) is a
/// manager/desktop concern.
abstract interface class PermitRepository {
  Future<void> pushPermit(String permitId);
  Future<void> pushClose(String permitId);
}
