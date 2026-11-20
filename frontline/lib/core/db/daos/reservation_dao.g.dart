// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_dao.dart';

// ignore_for_file: type=lint
mixin _$ReservationDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $ReservationsTable get reservations => attachedDatabase.reservations;
  ReservationDaoManager get managers => ReservationDaoManager(this);
}

class ReservationDaoManager {
  final _$ReservationDaoMixin _db;
  ReservationDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$BuildingsTableTableManager get buildings =>
      $$BuildingsTableTableManager(_db.attachedDatabase, _db.buildings);
  $$FloorsTableTableManager get floors =>
      $$FloorsTableTableManager(_db.attachedDatabase, _db.floors);
  $$SpacesTableTableManager get spaces =>
      $$SpacesTableTableManager(_db.attachedDatabase, _db.spaces);
  $$ReservationsTableTableManager get reservations =>
      $$ReservationsTableTableManager(_db.attachedDatabase, _db.reservations);
}
