import 'package:drift/drift.dart';

import 'location_tables.dart';
import 'work_order_tables.dart';

/// Inventory masters (Section 37). "Warehouse" is kept as a plain name
/// rather than a full `inventory_locations` table with its own
/// multi-location balance model - this app tracks one balance per
/// item per site ([InventoryBalances]), not a per-warehouse breakdown;
/// a true multi-warehouse model is a bigger change than this mobile
/// app's "what's on hand at my site" need justifies. Similarly,
/// "Serial/batch" is a single free-text value, not a per-unit
/// serialized-inventory tracking system.
class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get sku => text()();
  TextColumn get name => text()();
  TextColumn get category => text().nullable()();
  TextColumn get unit => text()();
  RealColumn get unitCost => real().nullable()();
  RealColumn get reorderLevel => real().nullable()();
  RealColumn get minLevel => real().nullable()();
  TextColumn get warehouseName => text().nullable()();
  TextColumn get supplierName => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get serialOrBatch => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// On-hand quantity per item per site (Section 37: `inventory_balances`).
/// `reservedQuantity` is tracked but nothing in this app currently
/// reserves stock (no quote/approval reservation workflow exists here);
/// it exists so "Reserved"/"Available" can be shown correctly once
/// something does write to it.
class InventoryBalances extends Table {
  TextColumn get itemId => text().references(InventoryItems, #id)();
  TextColumn get siteId => text().references(Sites, #id)();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  RealColumn get reservedQuantity => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {itemId, siteId};
}

/// Inventory transactions (Section 37). Types: Receive, Issue, Transfer,
/// Return, Repair, Scrap, Adjustment - all require a reason and user.
/// For `issue` recorded through a work order's "Add part" flow, the
/// reason is implicit (the linked work order) and not re-typed by the
/// technician; every other type is entered through the standalone
/// Stock Transaction screen and requires an explicit reason. `Transfer`
/// only decrements this site's balance - there is no second-location
/// balance to credit since this app has no multi-site destination
/// picker, so it's closer to "stock sent out" than a true transfer.
class InventoryTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(InventoryItems, #id)();
  TextColumn get workOrderId => text().nullable().references(WorkOrders, #id)();
  TextColumn get transactionType =>
      text().withDefault(const Constant('issue'))();
  RealColumn get quantity => real()();
  TextColumn get reason => text().nullable()();
  TextColumn get userId => text()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
