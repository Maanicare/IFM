import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../location/presentation/current_site_provider.dart';
import '../domain/stock_transaction_type.dart';
import 'stock_transaction_controller.dart';

/// SCREEN 32 - Inventory Item. Quantity/Reserved/Available are shown for
/// the technician's current site only - this app tracks one balance per
/// item per site, not a multi-warehouse breakdown (see the doc comment
/// on `InventoryItems` in inventory_tables.dart).
class InventoryItemScreen extends ConsumerWidget {
  const InventoryItemScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(_itemStreamProvider(itemId));
    final siteId = ref.watch(currentSiteIdProvider).value;
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    final canRecordTransaction = siteId != null &&
        accessContext != null &&
        guard.can(accessContext, AppAction.recordPartsUsage, siteId: siteId);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory item')),
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (item) {
          if (item == null) return const Center(child: Text('Not found.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleLarge),
              Text('${item.sku}${item.category != null ? ' · ${item.category}' : ''}'),
              const SizedBox(height: 16),
              if (siteId != null) _BalanceCard(item: item, siteId: siteId),
              const SizedBox(height: 12),
              _FieldsCard(item: item),
              const SizedBox(height: 12),
              if (siteId != null) _HistorySection(itemId: item.id),
              const SizedBox(height: 16),
              if (canRecordTransaction)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Record stock transaction'),
                    onPressed: () => _showRecordTransactionSheet(context, ref, item.id, siteId),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.item, required this.siteId});
  final InventoryItem item;
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(_balanceProvider((itemId: item.id, siteId: siteId))).value;
    final quantity = balance?.quantity ?? 0;
    final reserved = balance?.reservedQuantity ?? 0;
    final available = quantity - reserved;
    final lowStock = item.reorderLevel != null && available <= item.reorderLevel!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(child: _Stat(label: 'Quantity', value: quantity, unit: item.unit)),
            Expanded(child: _Stat(label: 'Reserved', value: reserved, unit: item.unit)),
            Expanded(
              child: _Stat(
                label: 'Available',
                value: available,
                unit: item.unit,
                color: lowStock ? Colors.orange.shade800 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.unit, this.color});
  final String label;
  final double value;
  final String unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(0),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _FieldsCard extends StatelessWidget {
  const _FieldsCard({required this.item});
  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final rows = <(String, String?)>[
      ('Unit', item.unit),
      ('Warehouse', item.warehouseName),
      ('Min level', item.minLevel?.toStringAsFixed(0)),
      ('Reorder level', item.reorderLevel?.toStringAsFixed(0)),
      ('Supplier', item.supplierName),
      ('Cost', item.unitCost != null ? currency.format(item.unitCost) : null),
      ('Expiry', item.expiryDate != null ? fmt.format(item.expiryDate!) : null),
      ('Serial/batch', item.serialOrBatch),
    ].where((r) => r.$2 != null).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
                    Expanded(child: Text(value!)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends ConsumerWidget {
  const _HistorySection({required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(_transactionsProvider(itemId)).value ?? const [];
    if (transactions.isEmpty) return const SizedBox.shrink();
    final fmt = DateFormat.yMMMd().add_Hm();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction history', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final txn in transactions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${txn.transactionType[0].toUpperCase()}${txn.transactionType.substring(1)} '
                            '${txn.quantity > 0 ? '+' : ''}${txn.quantity.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (txn.reason != null)
                            Text(txn.reason!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(fmt.format(txn.timestamp), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showRecordTransactionSheet(
  BuildContext context,
  WidgetRef ref,
  String itemId,
  String siteId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RecordTransactionSheet(itemId: itemId, siteId: siteId),
  );
}

class _RecordTransactionSheet extends ConsumerStatefulWidget {
  const _RecordTransactionSheet({required this.itemId, required this.siteId});
  final String itemId;
  final String siteId;

  @override
  ConsumerState<_RecordTransactionSheet> createState() => _RecordTransactionSheetState();
}

class _RecordTransactionSheetState extends ConsumerState<_RecordTransactionSheet> {
  StockTransactionType _type = StockTransactionType.receive;
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantity = double.tryParse(_quantityController.text);
    final reason = _reasonController.text.trim();
    if (quantity == null || quantity == 0 || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a non-zero quantity and a reason.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(stockTransactionControllerProvider.notifier).record(
            itemId: widget.itemId,
            siteId: widget.siteId,
            type: _type,
            quantity: quantity,
            reason: reason,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not record: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record stock transaction', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<StockTransactionType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: StockTransactionType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity',
                helperText: _type == StockTransactionType.adjustment
                    ? 'Enter positive to increase, negative to decrease'
                    : null,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason (required)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _itemStreamProvider = StreamProvider.family<InventoryItem?, String>((ref, id) {
  return ref.watch(appDatabaseProvider).inventoryDao.watchById(id);
});

final _balanceProvider =
    FutureProvider.family<InventoryBalance?, ({String itemId, String siteId})>((ref, args) async {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.inventoryBalances)
        ..where((t) => t.itemId.equals(args.itemId) & t.siteId.equals(args.siteId)))
      .getSingleOrNull();
});

final _transactionsProvider =
    StreamProvider.family<List<InventoryTransaction>, String>((ref, itemId) {
  return ref.watch(appDatabaseProvider).inventoryDao.watchTransactionsFor(itemId);
});
