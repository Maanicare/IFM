import 'reservation_repository.dart';

class MockReservationRepository implements ReservationRepository {
  @override
  Future<void> pushReservation(String reservationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> pushCancel(String reservationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> pushCheckIn(String reservationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
