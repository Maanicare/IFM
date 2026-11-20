import 'package:dio/dio.dart';

import '../../../core/db/app_database.dart';
import 'reservation_repository.dart';

class HttpReservationRepository implements ReservationRepository {
  HttpReservationRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> pushReservation(String reservationId) async {
    final r = await _db.reservationDao.byId(reservationId);
    if (r == null) return;
    await _dio.post<void>('/v1/reservations', data: {
      'id': r.id,
      'space_id': r.spaceId,
      'organiser_id': r.organiserId,
      'organiser_name': r.organiserName,
      'start_time': r.startTime.toIso8601String(),
      'end_time': r.endTime.toIso8601String(),
      'attendee_count': r.attendeeCount,
      'purpose': r.purpose,
      'invitees_note': r.inviteesNote,
      'services_note': r.servicesNote,
      'status': r.status,
    });
  }

  @override
  Future<void> pushCancel(String reservationId) async {
    await _dio.patch<void>('/v1/reservations/$reservationId/cancel');
  }

  @override
  Future<void> pushCheckIn(String reservationId) async {
    await _dio.patch<void>('/v1/reservations/$reservationId/check-in');
  }
}
