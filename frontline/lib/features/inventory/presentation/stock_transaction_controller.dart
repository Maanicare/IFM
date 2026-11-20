import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';
import '../domain/stock_transaction_type.dart';

part 'stock_transaction_controller.g.dart';

/// Screen 33 - Stock Transaction: Receive/Transfer/Return/Repair/Scrap/
/// Adjustment, each requiring a reason (Section: "Requirement: Require
/// reason and user"). `Issue` stays on [PartsUsageController]'s
/// work-order-scoped flow, not this one.
@riverpod
class StockTransactionController extends _$StockTransactionController {
  @override
  void build() {}

  Future<void> record({
    required String itemId,
    required String siteId,
    required StockTransactionType type,
    required double quantity,
    required String reason,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.recordPartsUsage, siteId: siteId);
    if (reason.trim().isEmpty) {
      throw ArgumentError('A reason is required for every stock transaction.');
    }

    final id = IdGenerator.newId();
    final signedQuantity = type.isInbound ? quantity.abs() : -quantity.abs();

    await db.transaction(() async {
      await db.inventoryDao.recordTransaction(
        id: id,
        itemId: itemId,
        siteId: siteId,
        transactionType: type.wireValue,
        signedQuantity: type == StockTransactionType.adjustment ? quantity : signedQuantity,
        reason: reason.trim(),
        userId: accessContext.userId,
      );
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'inventory_stock_transaction',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({'transactionId': id}),
        createdBy: accessContext.userId,
      );
    });
  }
}
