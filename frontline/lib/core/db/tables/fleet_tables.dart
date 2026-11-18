import 'package:drift/drift.dart';

/// Vehicles (Section 48, Screen 48) - trimmed to what a driver's own
/// field app needs (their assigned vehicle's identity/compliance
/// dates), not the fleet-wide management view (Screen 47), which stays
/// a Main Application / Fleet Manager concern.
class Vehicles extends Table {
  TextColumn get id => text()();
  TextColumn get registration => text()();
  TextColumn get type => text()();
  TextColumn get make => text().nullable()();
  TextColumn get model => text().nullable()();
  RealColumn get odometer => real().nullable()();
  TextColumn get fuelType => text().nullable()();
  TextColumn get assignedDriverId => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get insuranceExpiry => dateTime().nullable()();
  DateTimeColumn get pucExpiry => dateTime().nullable()();
  DateTimeColumn get serviceDueDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Trips (Section 48). A driver starts a trip (capturing the start
/// odometer) and ends it later (end odometer, optional fuel used) -
/// GPS route capture (Section 48's `route` field) is a desktop/
/// telematics concern, not re-implemented here.
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get vehicleId => text().references(Vehicles, #id)();
  TextColumn get driverId => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  RealColumn get startOdometer => real()();
  RealColumn get endOdometer => real().nullable()();
  RealColumn get fuelUsed => real().nullable()();
  TextColumn get purpose => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
