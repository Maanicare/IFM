import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/reservation_tables.dart';

part 'reservation_dao.g.dart';

@DriftAccessor(tables: [Reservations])
class ReservationDao extends DatabaseAccessor<AppDatabase> with _$ReservationDaoMixin {
  ReservationDao(super.db);

  /// Reservations for a space on a given day, earliest first - used
  /// both to show "Available spaces" (what's free right now) and the
  /// space's existing bookings.
  Stream<List<Reservation>> watchForSpace(String spaceId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(reservations)
          ..where((t) =>
              t.spaceId.equals(spaceId) &
              t.status.equals('confirmed') &
              t.startTime.isBiggerOrEqualValue(start) &
              t.startTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch();
  }

  Stream<List<Reservation>> watchForOrganiser(String organiserId) {
    return (select(reservations)
          ..where((t) => t.organiserId.equals(organiserId) & t.status.equals('confirmed'))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch();
  }

  Future<Reservation?> byId(String id) =>
      (select(reservations)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insert(ReservationsCompanion row) => into(reservations).insert(row);

  Future<void> cancel(String id) {
    return (update(reservations)..where((t) => t.id.equals(id))).write(
      const ReservationsCompanion(status: Value('cancelled')),
    );
  }

  Future<void> checkIn(String id) {
    return (update(reservations)..where((t) => t.id.equals(id))).write(
      const ReservationsCompanion(checkedIn: Value(true)),
    );
  }
}
