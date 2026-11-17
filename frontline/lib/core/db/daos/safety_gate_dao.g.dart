// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_gate_dao.dart';

// ignore_for_file: type=lint
mixin _$SafetyGateDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $ServiceRequestsTable get serviceRequests => attachedDatabase.serviceRequests;
  $AssetsTable get assets => attachedDatabase.assets;
  $WorkOrdersTable get workOrders => attachedDatabase.workOrders;
  $SafetyGateResponsesTable get safetyGateResponses =>
      attachedDatabase.safetyGateResponses;
  SafetyGateDaoManager get managers => SafetyGateDaoManager(this);
}

class SafetyGateDaoManager {
  final _$SafetyGateDaoMixin _db;
  SafetyGateDaoManager(this._db);
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
  $$SafetyGateResponsesTableTableManager get safetyGateResponses =>
      $$SafetyGateResponsesTableTableManager(
        _db.attachedDatabase,
        _db.safetyGateResponses,
      );
}
