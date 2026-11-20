import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/inventory_tables.dart';

part 'inventory_dao.g.dart';

/// Backs the "Required parts" / "Parts used" block on the Work Order
/// Detail screen (Section 29: `work_orders` -> parts consumed; Section 37).
@DriftAccessor(tables: [InventoryItems, InventoryBalances, InventoryTransactions])
class InventoryDao extends DatabaseAccessor<AppDatabase>
    with _$InventoryDaoMixin {
  InventoryDao(super.db);

  /// Resolves a scanned QR/barcode against an inventory item SKU
  /// (Screen 11: Scan "can identify ... Inventory item").
  /// Section 63 (Universal Search) - only items actually stocked at
  /// [siteId], same reasoning as [watchAvailableAtSite].
  Future<List<InventoryItem>> searchAtSite(String siteId, String query) async {
    final like = '%$query%';
    final q = select(inventoryItems).join([
      innerJoin(
        inventoryBalances,
        inventoryBalances.itemId.equalsExp(inventoryItems.id) &
            inventoryBalances.siteId.equals(siteId),
      ),
    ])
      ..where(inventoryItems.name.like(like) | inventoryItems.sku.like(like))
      ..limit(20);
    final rows = await q.get();
    return rows.map((r) => r.readTable(inventoryItems)).toList();
  }

  Future<InventoryItem?> byQrOrSku(String code) =>
      (select(inventoryItems)..where((t) => t.sku.equals(code))).getSingleOrNull();

  Future<InventoryItem?> byId(String id) =>
      (select(inventoryItems)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<InventoryItem?> watchById(String id) =>
      (select(inventoryItems)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Transaction history for an item (Screen 32). Not site-scoped - a
  /// transaction row has no denormalised `siteId` of its own, so this
  /// returns the full history regardless of site. Fine for a
  /// single-site technician device; a multi-site one would see more
  /// than its own site's activity here.
  Stream<List<InventoryTransaction>> watchTransactionsFor(String itemId) {
    return (select(inventoryTransactions)
          ..where((t) => t.itemId.equals(itemId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  Future<InventoryItemWithBalance?> withBalanceAtSite(String itemId, String siteId) async {
    final item = await (select(inventoryItems)..where((t) => t.id.equals(itemId))).getSingleOrNull();
    if (item == null) return null;
    final balance = await (select(inventoryBalances)
          ..where((t) => t.itemId.equals(itemId) & t.siteId.equals(siteId)))
        .getSingleOrNull();
    return InventoryItemWithBalance(item: item, quantityAvailable: balance?.quantity ?? 0);
  }

  Future<void> upsertItemFromServer(InventoryItemsCompanion row) =>
      into(inventoryItems).insertOnConflictUpdate(row);

  Future<void> upsertBalanceFromServer(InventoryBalancesCompanion row) =>
      into(inventoryBalances).insertOnConflictUpdate(row);

  /// Items with a known on-hand balance at [siteId], for the "add part"
  /// picker - a technician should only be offered parts that are actually
  /// in stock at their site.
  Stream<List<InventoryItemWithBalance>> watchAvailableAtSite(String siteId) {
    final query = select(inventoryItems).join([
      innerJoin(
        inventoryBalances,
        inventoryBalances.itemId.equalsExp(inventoryItems.id) &
            inventoryBalances.siteId.equals(siteId),
      ),
    ]);
    return query.watch().map(
          (rows) => rows
              .map((r) => InventoryItemWithBalance(
                    item: r.readTable(inventoryItems),
                    quantityAvailable: r.readTable(inventoryBalances).quantity,
                  ))
              .toList(),
        );
  }

  /// Items below their reorder level at a site - backs the Home screen's
  /// "Required parts" row (Section 8: Technician Home).
  Stream<List<InventoryItemWithBalance>> watchLowStockAtSite(String siteId) {
    final query = select(inventoryItems).join([
      innerJoin(
        inventoryBalances,
        inventoryBalances.itemId.equalsExp(inventoryItems.id) &
            inventoryBalances.siteId.equals(siteId),
      ),
    ])
      ..where(inventoryItems.reorderLevel.isNotNull() &
          inventoryBalances.quantity.isSmallerOrEqual(inventoryItems.reorderLevel));
    return query.watch().map(
          (rows) => rows
              .map((r) => InventoryItemWithBalance(
                    item: r.readTable(inventoryItems),
                    quantityAvailable: r.readTable(inventoryBalances).quantity,
                  ))
              .toList(),
        );
  }

  Stream<List<InventoryTransaction>> watchUsageFor(String workOrderId) {
    return (select(inventoryTransactions)
          ..where((t) => t.workOrderId.equals(workOrderId))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .watch();
  }

  /// Usage joined with item name/unit, for display on the Work Order
  /// Detail screen without a separate per-row item lookup.
  Stream<List<InventoryUsageEntry>> watchUsageWithItemNamesFor(
    String workOrderId,
  ) {
    final query = select(inventoryTransactions).join([
      innerJoin(
        inventoryItems,
        inventoryItems.id.equalsExp(inventoryTransactions.itemId),
      ),
    ])
      ..where(inventoryTransactions.workOrderId.equals(workOrderId))
      ..orderBy([OrderingTerm.asc(inventoryTransactions.timestamp)]);
    return query.watch().map(
          (rows) => rows
              .map((r) => InventoryUsageEntry(
                    transaction: r.readTable(inventoryTransactions),
                    item: r.readTable(inventoryItems),
                  ))
              .toList(),
        );
  }

  /// Records consumption and decrements the local balance in one
  /// transaction, mirroring the optimistic-write pattern used for status
  /// transitions and checklist responses elsewhere in this app - the
  /// technician sees the part deducted immediately, offline or not.
  Future<void> recordIssue(InventoryTransactionsCompanion entry, {
    required String siteId,
  }) async {
    await transaction(() async {
      await into(inventoryTransactions).insert(entry);
      final existing = await (select(inventoryBalances)
            ..where((t) =>
                t.itemId.equals(entry.itemId.value) &
                t.siteId.equals(siteId)))
          .getSingleOrNull();
      final currentQty = existing?.quantity ?? 0;
      await into(inventoryBalances).insertOnConflictUpdate(
        InventoryBalancesCompanion(
          itemId: entry.itemId,
          siteId: Value(siteId),
          quantity: Value(currentQty - entry.quantity.value),
        ),
      );
    });
  }

  /// Screen 33 (Stock Transaction): Receive/Transfer/Return/Repair/
  /// Scrap/Adjustment, each applying a signed quantity delta to the
  /// site balance - positive for stock coming in (Receive, Return),
  /// negative for stock going out (Transfer, Repair, Scrap), either
  /// sign for Adjustment (a count correction). `Issue` keeps using
  /// [recordIssue] above, which this is deliberately kept separate
  /// from so the existing Work Order "Add part" flow (and its implicit,
  /// not-user-typed reason) is untouched.
  Future<void> recordTransaction({
    required String id,
    required String itemId,
    required String siteId,
    required String transactionType,
    required double signedQuantity,
    required String reason,
    required String userId,
  }) async {
    await transaction(() async {
      await into(inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
        id: id,
        itemId: itemId,
        transactionType: Value(transactionType),
        quantity: signedQuantity,
        reason: Value(reason),
        userId: userId,
        timestamp: DateTime.now(),
      ));
      final existing = await (select(inventoryBalances)
            ..where((t) => t.itemId.equals(itemId) & t.siteId.equals(siteId)))
          .getSingleOrNull();
      final currentQty = existing?.quantity ?? 0;
      await into(inventoryBalances).insertOnConflictUpdate(
        InventoryBalancesCompanion(
          itemId: Value(itemId),
          siteId: Value(siteId),
          quantity: Value(currentQty + signedQuantity),
        ),
      );
    });
  }
}

class InventoryItemWithBalance {
  InventoryItemWithBalance({required this.item, required this.quantityAvailable});
  final InventoryItem item;
  final double quantityAvailable;
}

class InventoryUsageEntry {
  InventoryUsageEntry({required this.transaction, required this.item});
  final InventoryTransaction transaction;
  final InventoryItem item;
}
