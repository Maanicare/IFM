import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/fleet_tables.dart';

part 'fleet_dao.g.dart';

@DriftAccessor(tables: [Vehicles, Trips])
class FleetDao extends DatabaseAccessor<AppDatabase> with _$FleetDaoMixin {
  FleetDao(super.db);

  Future<void> upsertVehicleFromServer(VehiclesCompanion row) =>
      into(vehicles).insertOnConflictUpdate(row);

  Stream<Vehicle?> watchAssignedVehicle(String driverId) {
    return (select(vehicles)
          ..where((t) => t.assignedDriverId.equals(driverId))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> insertTrip(TripsCompanion row) => into(trips).insert(row);

  Future<void> updateTripEnd({
    required String tripId,
    required DateTime endTime,
    required double endOdometer,
    double? fuelUsed,
  }) {
    return (update(trips)..where((t) => t.id.equals(tripId))).write(
      TripsCompanion(
        endTime: Value(endTime),
        endOdometer: Value(endOdometer),
        fuelUsed: Value(fuelUsed),
      ),
    );
  }

  /// The driver's open (not-yet-ended) trip, if any - a driver can only
  /// run one trip at a time.
  Stream<Trip?> watchOpenTrip(String driverId) {
    return (select(trips)
          ..where((t) => t.driverId.equals(driverId) & t.endTime.isNull())
          ..limit(1))
        .watchSingleOrNull();
  }

  Stream<List<Trip>> watchTripsForDriver(String driverId) {
    return (select(trips)
          ..where((t) => t.driverId.equals(driverId))
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .watch();
  }

  Future<void> upsertTripFromServer(TripsCompanion row) =>
      into(trips).insertOnConflictUpdate(row);
}
