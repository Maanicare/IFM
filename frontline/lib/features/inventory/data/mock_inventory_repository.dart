import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/fixtures/fixture_loader.dart';
import 'inventory_repository.dart';

class MockInventoryRepository implements InventoryRepository {
  MockInventoryRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> syncCatalogueForSite(String siteId) async {
    final items = await FixtureLoader.loadJson(
      'assets/fixtures/inventory_items.json',
    ) as List;
    final balances = await FixtureLoader.loadJson(
      'assets/fixtures/inventory_balances.json',
    ) as List;

    await _db.transaction(() async {
      for (final i in items.cast<Map<String, dynamic>>()) {
        await _db.inventoryDao.upsertItemFromServer(InventoryItemsCompanion.insert(
          id: i['id'] as String,
          sku: i['sku'] as String,
          name: i['name'] as String,
          category: Value(i['category'] as String?),
          unit: i['unit'] as String,
          unitCost: Value((i['unitCost'] as num?)?.toDouble()),
          reorderLevel: Value((i['reorderLevel'] as num?)?.toDouble()),
          minLevel: Value((i['minLevel'] as num?)?.toDouble()),
          warehouseName: Value(i['warehouseName'] as String?),
          supplierName: Value(i['supplierName'] as String?),
          expiryDate: Value(FixtureLoader.resolveOffset(i, 'expiry')),
          serialOrBatch: Value(i['serialOrBatch'] as String?),
        ));
      }
      for (final b in balances.cast<Map<String, dynamic>>()) {
        if (b['siteId'] != siteId) continue;
        await _db.inventoryDao.upsertBalanceFromServer(InventoryBalancesCompanion.insert(
          itemId: b['itemId'] as String,
          siteId: b['siteId'] as String,
          quantity: Value((b['quantity'] as num).toDouble()),
          reservedQuantity: Value((b['reservedQuantity'] as num?)?.toDouble() ?? 0),
        ));
      }
    });
  }

  @override
  Future<void> pushIssue({
    required String transactionId,
    required String itemId,
    required String workOrderId,
    required double quantity,
    required String userId,
    required DateTime timestamp,
  }) async {
    // Mock mode has no backend - the local write (performed by the caller
    // before this method runs) is the entire effect.
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> pushTransaction(String transactionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
