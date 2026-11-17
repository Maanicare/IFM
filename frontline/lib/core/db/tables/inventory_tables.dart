import 'package:drift/drift.dart';

import 'location_tables.dart';
import 'work_order_tables.dart';

/// Inventory masters (Section 37). Trimmed to what a technician's "parts
/// used" flow needs: an item catalogue and a per-site balance. Warehouse
/// transfer/receive/repair flows live in the manager/store surfaces, not
/// this mobile app - only `issue` (consumption against a work order) is
/// relevant here.
class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get sku => text()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get unit => text()();
  RealColumn get unitCost => real().nullable()();
  RealColumn get reorderLevel => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// On-hand quantity per item per site (Section 37: `inventory_balances`).
class InventoryBalances extends Table {
  TextColumn get itemId => text().references(InventoryItems, #id)();
  TextColumn get siteId => text().references(Sites, #id)();
  RealColumn get quantity => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {itemId, siteId};
}

/// Parts consumption against a work order (Section 37: `inventory_
/// transactions`, `transaction_type = 'issue'`). Reason is implicit (the
/// linked work order); a free-text reason is still required for any
/// non-issue adjustment, but adjustment/transfer/repair flows are out of
/// scope for the mobile app.
class InventoryTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(InventoryItems, #id)();
  TextColumn get workOrderId => text().nullable().references(WorkOrders, #id)();
  TextColumn get transactionType =>
      text().withDefault(const Constant('issue'))();
  RealColumn get quantity => real()();
  TextColumn get userId => text()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
