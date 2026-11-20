// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'washroom_dao.dart';

// ignore_for_file: type=lint
mixin _$WashroomDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $WashroomsTable get washrooms => attachedDatabase.washrooms;
  WashroomDaoManager get managers => WashroomDaoManager(this);
}

class WashroomDaoManager {
  final _$WashroomDaoMixin _db;
  WashroomDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$BuildingsTableTableManager get buildings =>
      $$BuildingsTableTableManager(_db.attachedDatabase, _db.buildings);
  $$FloorsTableTableManager get floors =>
      $$FloorsTableTableManager(_db.attachedDatabase, _db.floors);
  $$SpacesTableTableManager get spaces =>
      $$SpacesTableTableManager(_db.attachedDatabase, _db.spaces);
  $$WashroomsTableTableManager get washrooms =>
      $$WashroomsTableTableManager(_db.attachedDatabase, _db.washrooms);
}
