// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permit_dao.dart';

// ignore_for_file: type=lint
mixin _$PermitDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $ServiceRequestsTable get serviceRequests => attachedDatabase.serviceRequests;
  $AssetsTable get assets => attachedDatabase.assets;
  $WorkOrdersTable get workOrders => attachedDatabase.workOrders;
  $PermitsTable get permits => attachedDatabase.permits;
  PermitDaoManager get managers => PermitDaoManager(this);
}

class PermitDaoManager {
  final _$PermitDaoMixin _db;
  PermitDaoManager(this._db);
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
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$WorkOrdersTableTableManager get workOrders =>
      $$WorkOrdersTableTableManager(_db.attachedDatabase, _db.workOrders);
  $$PermitsTableTableManager get permits =>
      $$PermitsTableTableManager(_db.attachedDatabase, _db.permits);
}
