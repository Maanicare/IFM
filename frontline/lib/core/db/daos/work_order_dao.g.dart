// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkOrderDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $ServiceRequestsTable get serviceRequests => attachedDatabase.serviceRequests;
  $AssetsTable get assets => attachedDatabase.assets;
  $WorkOrdersTable get workOrders => attachedDatabase.workOrders;
  $WorkOrderStatusHistoryTable get workOrderStatusHistory =>
      attachedDatabase.workOrderStatusHistory;
  $WorkOrderPlannedPartsTable get workOrderPlannedParts =>
      attachedDatabase.workOrderPlannedParts;
  WorkOrderDaoManager get managers => WorkOrderDaoManager(this);
}

class WorkOrderDaoManager {
  final _$WorkOrderDaoMixin _db;
  WorkOrderDaoManager(this._db);
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
  $$WorkOrderStatusHistoryTableTableManager get workOrderStatusHistory =>
      $$WorkOrderStatusHistoryTableTableManager(
        _db.attachedDatabase,
        _db.workOrderStatusHistory,
      );
  $$WorkOrderPlannedPartsTableTableManager get workOrderPlannedParts =>
      $$WorkOrderPlannedPartsTableTableManager(
        _db.attachedDatabase,
        _db.workOrderPlannedParts,
      );
}
