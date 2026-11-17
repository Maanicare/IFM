import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'inventory_repository.dart';

class HttpInventoryRepository implements InventoryRepository {
  HttpInventoryRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> syncCatalogueForSite(String siteId) async {
    final response = await _dio
        .get<List<dynamic>>('/v1/sites/$siteId/inventory-balances');
    final list = response.data ?? const [];

    await _db.transaction(() async {
      for (final b in list.cast<Map<String, dynamic>>()) {
        final item = b['item'] as Map<String, dynamic>;
        await _db.inventoryDao.upsertItemFromServer(InventoryItemsCompanion.insert(
          id: item['id'] as String,
          sku: item['sku'] as String,
          name: item['name'] as String,
          category: Value(item['category'] as String?),
          unit: item['unit'] as String,
          unitCost: Value((item['unitCost'] as num?)?.toDouble()),
          reorderLevel: Value((item['reorderLevel'] as num?)?.toDouble()),
        ));
        await _db.inventoryDao.upsertBalanceFromServer(InventoryBalancesCompanion.insert(
          itemId: item['id'] as String,
          siteId: siteId,
          quantity: Value((b['quantity'] as num).toDouble()),
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
    await _dio.post<void>('/v1/inventory/transactions', data: {
      'id': transactionId,
      'item_id': itemId,
      'work_order_id': workOrderId,
      'transaction_type': 'issue',
      'quantity': quantity,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
    });
  }
}
