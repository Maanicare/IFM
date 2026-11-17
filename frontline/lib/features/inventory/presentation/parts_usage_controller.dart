import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'parts_usage_controller.g.dart';

/// Records a part consumed against a work order (Section 29: "parts
/// consumed"; Section 37: `inventory_transactions`). Writes the
/// transaction, decrements the local site balance, and enqueues the push
/// - same evidence-before-claims transactional pattern used for checklist
/// responses and status transitions elsewhere in this app.
@riverpod
class PartsUsageController extends _$PartsUsageController {
  @override
  void build() {}

  Future<void> recordUsage({
    required String workOrderId,
    required String siteId,
    required String itemId,
    required double quantity,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.recordPartsUsage, siteId: siteId);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.inventoryDao.recordIssue(
        InventoryTransactionsCompanion.insert(
          id: id,
          itemId: itemId,
          workOrderId: Value(workOrderId),
          transactionType: const Value('issue'),
          quantity: quantity,
          userId: accessContext.userId,
          timestamp: now,
        ),
        siteId: siteId,
      );
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'inventory_transaction',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({
          'itemId': itemId,
          'workOrderId': workOrderId,
          'quantity': quantity,
          'userId': accessContext.userId,
          'timestamp': now.toIso8601String(),
        }),
        createdBy: accessContext.userId,
      );
    });
  }
}
