/// Pushes reservations made on this device (Screen 43). This app only
/// ever creates/cancels/checks in its own reservations and never syncs
/// other users' bookings down - "Available spaces" here only reflects
/// what this device knows about, not a live cross-device calendar.
abstract interface class ReservationRepository {
  Future<void> pushReservation(String reservationId);
  Future<void> pushCancel(String reservationId);
  Future<void> pushCheckIn(String reservationId);
}
