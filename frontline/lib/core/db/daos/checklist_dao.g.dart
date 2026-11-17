// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_dao.dart';

// ignore_for_file: type=lint
mixin _$ChecklistDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChecklistsTable get checklists => attachedDatabase.checklists;
  $ChecklistItemsTable get checklistItems => attachedDatabase.checklistItems;
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $ServiceRequestsTable get serviceRequests => attachedDatabase.serviceRequests;
  $AssetsTable get assets => attachedDatabase.assets;
  $WorkOrdersTable get workOrders => attachedDatabase.workOrders;
  $ChecklistResponsesTable get checklistResponses =>
      attachedDatabase.checklistResponses;
  ChecklistDaoManager get managers => ChecklistDaoManager(this);
}

class ChecklistDaoManager {
  final _$ChecklistDaoMixin _db;
  ChecklistDaoManager(this._db);
  $$ChecklistsTableTableManager get checklists =>
      $$ChecklistsTableTableManager(_db.attachedDatabase, _db.checklists);
  $$ChecklistItemsTableTableManager get checklistItems =>
      $$ChecklistItemsTableTableManager(
        _db.attachedDatabase,
        _db.checklistItems,
      );
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
  $$ChecklistResponsesTableTableManager get checklistResponses =>
      $$ChecklistResponsesTableTableManager(
        _db.attachedDatabase,
        _db.checklistResponses,
      );
}
