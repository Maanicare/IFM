// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_dao.dart';

// ignore_for_file: type=lint
mixin _$RequestDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $ServiceRequestsTable get serviceRequests => attachedDatabase.serviceRequests;
  RequestDaoManager get managers => RequestDaoManager(this);
}

class RequestDaoManager {
  final _$RequestDaoMixin _db;
  RequestDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$BuildingsTableTableManager get buildings =>
      $$BuildingsTableTableManager(_db.attachedDatabase, _db.buildings);
  $$FloorsTableTableManager get floors =>
      $$FloorsTableTableManager(_db.attachedDatabase, _db.floors);
  $$SpacesTableTableManager get spaces =>
      $$SpacesTableTableManager(_db.attachedDatabase, _db.spaces);
  $$ServiceRequestsTableTableManager get serviceRequests =>
      $$ServiceRequestsTableTableManager(
        _db.attachedDatabase,
        _db.serviceRequests,
      );
}
