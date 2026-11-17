// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_dao.dart';

// ignore_for_file: type=lint
mixin _$InventoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $InventoryItemsTable get inventoryItems => attachedDatabase.inventoryItems;
  $SitesTable get sites => attachedDatabase.sites;
  $InventoryBalancesTable get inventoryBalances =>
      attachedDatabase.inventoryBalances;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $ServiceRequestsTable get serviceRequests => attachedDatabase.serviceRequests;
  $AssetsTable get assets => attachedDatabase.assets;
  $WorkOrdersTable get workOrders => attachedDatabase.workOrders;
  $InventoryTransactionsTable get inventoryTransactions =>
      attachedDatabase.inventoryTransactions;
  InventoryDaoManager get managers => InventoryDaoManager(this);
}

class InventoryDaoManager {
  final _$InventoryDaoMixin _db;
  InventoryDaoManager(this._db);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(
        _db.attachedDatabase,
        _db.inventoryItems,
      );
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$InventoryBalancesTableTableManager get inventoryBalances =>
      $$InventoryBalancesTableTableManager(
        _db.attachedDatabase,
        _db.inventoryBalances,
      );
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
  $$InventoryTransactionsTableTableManager get inventoryTransactions =>
      $$InventoryTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.inventoryTransactions,
      );
}
