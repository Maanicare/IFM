import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/inventory_dao.dart';
import '../../../core/nfc/nfc_service.dart';
import '../../location/presentation/current_site_provider.dart';

/// SCREEN 11 - Scan. Resolves a QR/barcode/NFC tag against the local
/// cache across everything this mobile app actually manages - Asset,
/// Space, Inventory item, Vehicle (Section: "Can Identify: Asset; Space;
/// Inventory item; Vehicle; Equipment; Room") - checked in that order
/// since a shared code space across entity types is a real-world risk.
/// "Equipment" and "Room" are not separate data models in this schema -
/// they're covered by Asset and Space respectively. NFC reads the tag's
/// raw UID (see `NfcService`'s doc comment for why) through the same
/// lookup/result-sheet path as a scanned code. Washroom (Screen 22's own
/// "QR Options") is also resolved here, checked against its own distinct
/// `qrCode` (not a Space's `spaceCode`) so a washroom QR opens its
/// richer status/report screen instead of the plain Space sheet.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  bool _nfcScanning = false;

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
    await _resolveCode(code);
    _handled = false;
  }

  Future<void> _onScanNfc() async {
    final available = await NfcService.isAvailable();
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device.')),
      );
      return;
    }
    setState(() => _nfcScanning = true);
    try {
      final tagId = await NfcService.scanTagId();
      if (tagId != null) await _resolveCode(tagId);
    } finally {
      if (mounted) setState(() => _nfcScanning = false);
    }
  }

  Future<void> _resolveCode(String code) async {
    final db = ref.read(appDatabaseProvider);

    final asset = await db.assetDao.byQrCode(code);
    if (asset != null) {
      if (mounted) {
        await showModalBottomSheet<void>(
          context: context,
          builder: (context) => _AssetResultSheet(asset: asset),
        );
      }
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
      return;
    }

    final washroom = await db.washroomDao.byQrCode(code);
    if (washroom != null) {
      if (mounted) context.push('/washrooms/${washroom.id}');
      return;
    }

    final vehicle = await db.fleetDao.byRegistration(code);
    if (vehicle != null) {
      if (mounted) {
        await showModalBottomSheet<void>(
          context: context,
          builder: (context) => _VehicleResultSheet(vehicle: vehicle),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nothing found for code "$code".')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: FilledButton.icon(
                onPressed: _nfcScanning ? null : _onScanNfc,
                icon: _nfcScanning
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.nfc),
                label: Text(_nfcScanning ? 'Hold device near tag...' : 'Scan NFC tag'),
              ),
            ),
          ),
        ],
      ),
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

class _VehicleResultSheet extends StatelessWidget {
  const _VehicleResultSheet({required this.vehicle});
  final Vehicle vehicle;

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
                const Icon(Icons.local_shipping_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(vehicle.registration, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            Text('${vehicle.type} · ${vehicle.make ?? ''} ${vehicle.model ?? ''}'),
            const SizedBox(height: 8),
            Text('Status: ${vehicle.status}'),
            if (vehicle.odometer != null)
              Text('Odometer: ${vehicle.odometer!.toStringAsFixed(0)} km'),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/inventory/${entry.item.id}');
                },
                child: const Text('View item details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
