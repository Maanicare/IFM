import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/inventory_dao.dart';
import 'parts_usage_controller.dart';

/// Section D's "parts used" block (Section 11: "Records ... parts used";
/// Section 29). Lets a technician record consumption against a work
/// order from a site-scoped stock picker, and shows what has already
/// been recorded.
class PartsUsedSection extends ConsumerWidget {
  const PartsUsedSection({
    super.key,
    required this.workOrderId,
    required this.siteId,
  });

  final String workOrderId;
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(_usageProvider(workOrderId)).value ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Parts used', style: Theme.of(context).textTheme.titleSmall),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add part'),
                  onPressed: () => _showAddPartSheet(context, ref),
                ),
              ],
            ),
            if (usage.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('No parts recorded yet.', style: TextStyle(color: Colors.grey)),
              )
            else
              for (final entry in usage)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.build_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${entry.item.name} (${entry.item.sku})')),
                      Text('${entry.transaction.quantity} ${entry.item.unit}'),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showAddPartSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddPartSheet(workOrderId: workOrderId, siteId: siteId),
    );
  }
}

final _usageProvider =
    StreamProvider.family<List<InventoryUsageEntry>, String>((ref, workOrderId) {
  final db = ref.watch(appDatabaseProvider);
  return db.inventoryDao.watchUsageWithItemNamesFor(workOrderId);
});

final _availableProvider =
    StreamProvider.family<List<InventoryItemWithBalance>, String>((ref, siteId) {
  final db = ref.watch(appDatabaseProvider);
  return db.inventoryDao.watchAvailableAtSite(siteId);
});

class _AddPartSheet extends ConsumerStatefulWidget {
  const _AddPartSheet({required this.workOrderId, required this.siteId});
  final String workOrderId;
  final String siteId;

  @override
  ConsumerState<_AddPartSheet> createState() => _AddPartSheetState();
}

class _AddPartSheetState extends ConsumerState<_AddPartSheet> {
  InventoryItemWithBalance? _selected;
  final _qtyController = TextEditingController(text: '1');
  bool _submitting = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final selected = _selected;
    final qty = double.tryParse(_qtyController.text);
    if (selected == null || qty == null || qty <= 0) return;

    setState(() => _submitting = true);
    try {
      await ref.read(partsUsageControllerProvider.notifier).recordUsage(
            workOrderId: widget.workOrderId,
            siteId: widget.siteId,
            itemId: selected.item.id,
            quantity: qty,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not record part: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(_availableProvider(widget.siteId)).value ?? const [];

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
            Text('Add part used', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<InventoryItemWithBalance>(
              initialValue: _selected,
              decoration: const InputDecoration(labelText: 'Part'),
              items: available
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text('${a.item.name} — ${a.quantityAvailable.toStringAsFixed(0)} ${a.item.unit} in stock'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selected = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Record part used'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
