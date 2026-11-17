import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/inventory_dao.dart';
import '../../location/presentation/current_site_provider.dart';

/// SCREEN 11 - Scan. Resolves a QR/barcode against the local cache across
/// everything this mobile app actually manages - Asset, Space, Inventory
/// item (Section: "Can Identify: Asset; Space; Inventory item; Vehicle;
/// Equipment; Room") - checked in that order since a shared code space
/// across entity types is a real-world risk; fleet vehicles are out of
/// scope for this app (Section 70: Fleet is a P2/desktop module with no
/// local vehicle cache here), so that one case is not attempted.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    _handled = true;

    final db = ref.read(appDatabaseProvider);

    final asset = await db.assetDao.byQrCode(code);
    if (asset != null) {
      if (mounted) {
        await showModalBottomSheet<void>(
          context: context,
          builder: (context) => _AssetResultSheet(asset: asset),
        );
      }
      _handled = false;
      return;
    }

    final space = await db.locationDao.spaceByCode(code);
    if (space != null) {
      if (mounted) {
        await showModalBottomSheet<void>(
          context: context,
          builder: (context) => _SpaceResultSheet(space: space),
        );
      }
      _handled = false;
      return;
    }

    final item = await db.inventoryDao.byQrOrSku(code);
    if (item != null) {
      final siteId = ref.read(currentSiteIdProvider).value;
      final withBalance = siteId != null
          ? await db.inventoryDao.withBalanceAtSite(item.id, siteId)
          : InventoryItemWithBalance(item: item, quantityAvailable: 0);
      if (mounted) {
        await showModalBottomSheet<void>(
          context: context,
          builder: (context) => _InventoryResultSheet(entry: withBalance!),
        );
      }
      _handled = false;
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nothing found for code "$code".')),
    );
    _handled = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _AssetResultSheet extends StatelessWidget {
  const _AssetResultSheet({required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(asset.name, style: Theme.of(context).textTheme.titleLarge),
            Text('${asset.assetCode} · ${asset.manufacturer ?? ''} ${asset.model ?? ''}'),
            const SizedBox(height: 8),
            Text('Status: ${asset.status} · Criticality: ${asset.criticality}'),
            if (asset.healthScore != null)
              Text('Health score: ${(asset.healthScore! * 100).round()}%'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/assets/${asset.id}');
                },
                child: const Text('View full profile'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/requests/new', extra: {'assetId': asset.id, 'spaceId': asset.spaceId});
                },
                child: const Text('Report an issue for this asset'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceResultSheet extends StatelessWidget {
  const _SpaceResultSheet({required this.space});
  final Space space;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.room_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(space.name, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            Text('${space.spaceCode} · ${space.spaceType.replaceAll('_', ' ')}'),
            const SizedBox(height: 8),
            Text('Criticality: ${space.criticality}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/requests/new', extra: {'spaceId': space.id});
                },
                child: const Text('Report an issue for this space'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryResultSheet extends StatelessWidget {
  const _InventoryResultSheet({required this.entry});
  final InventoryItemWithBalance entry;

  @override
  Widget build(BuildContext context) {
    final lowStock = entry.item.reorderLevel != null &&
        entry.quantityAvailable <= entry.item.reorderLevel!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.item.name, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            Text('${entry.item.sku} · ${entry.item.category ?? ''}'),
            const SizedBox(height: 8),
            Text(
              'In stock at this site: ${entry.quantityAvailable.toStringAsFixed(0)} ${entry.item.unit}',
              style: TextStyle(color: lowStock ? Colors.orange.shade800 : null, fontWeight: lowStock ? FontWeight.bold : null),
            ),
            if (lowStock)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Below reorder level.', style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            Text(
              'To record this part against a job, open the work order and use "Add part".',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
