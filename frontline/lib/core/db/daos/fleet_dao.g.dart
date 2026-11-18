// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_dao.dart';

// ignore_for_file: type=lint
mixin _$FleetDaoMixin on DatabaseAccessor<AppDatabase> {
  $VehiclesTable get vehicles => attachedDatabase.vehicles;
  $TripsTable get trips => attachedDatabase.trips;
  FleetDaoManager get managers => FleetDaoManager(this);
}

class FleetDaoManager {
  final _$FleetDaoMixin _db;
  FleetDaoManager(this._db);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db.attachedDatabase, _db.vehicles);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db.attachedDatabase, _db.trips);
}
