import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import 'meter_reading_dialog.dart';

/// SCREEN 12 - Asset Profile. Pulls together everything the spec asks
/// for from local tables rather than the server shipping a single
/// pre-joined "profile" payload: Identification/Location/Operational/
/// Commercial come straight off [Assets], Maintenance (open WO, failure
/// history, MTBF/MTTR) is derived from this asset's own work-order
/// history, and Documents from the synced [AssetDocuments] cache.
class AssetProfileScreen extends ConsumerWidget {
  const AssetProfileScreen({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final assetAsync = ref.watch(_assetProvider(assetId));

    return Scaffold(
      appBar: AppBar(title: const Text('Asset profile')),
      body: assetAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (asset) {
          if (asset == null) return const Center(child: Text('Asset not found.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(asset: asset),
              const SizedBox(height: 16),
              _IdentificationSection(asset: asset),
              const SizedBox(height: 12),
              _LocationSection(asset: asset),
              const SizedBox(height: 12),
              _OperationalSection(db: db, asset: asset),
              const SizedBox(height: 12),
              _CommercialSection(asset: asset),
              const SizedBox(height: 12),
              _MaintenanceSection(db: db, asset: asset),
              const SizedBox(height: 12),
              _DocumentsSection(db: db, assetId: asset.id),
            ],
          );
        },
      ),
    );
  }
}

final _assetProvider = StreamProvider.family<Asset?, String>((ref, id) {
  return ref.watch(appDatabaseProvider).assetDao.watchById(id);
});

class _Header extends StatelessWidget {
  const _Header({required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(asset.name, style: Theme.of(context).textTheme.titleLarge),
              Text('${asset.assetCode} · ${asset.categoryId.toUpperCase()}'),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: PriorityColors.of(asset.criticality).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            asset.criticality.toUpperCase(),
            style: TextStyle(color: PriorityColors.of(asset.criticality), fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.rows});

  final String title;
  final List<(String, String?)> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => r.$2 != null && r.$2!.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final (label, value) in visible)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

class _IdentificationSection extends StatelessWidget {
  const _IdentificationSection({required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(title: 'Identification', rows: [
      ('Asset ID', asset.assetCode),
      ('QR code', asset.qrCode),
      ('Category', asset.categoryId),
      ('Manufacturer', asset.manufacturer),
      ('Model', asset.model),
      ('Serial no.', asset.serialNumber),
    ]);
  }
}

class _LocationSection extends ConsumerWidget {
  const _LocationSection({required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(_assetLocationProvider(asset));
    return locationAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (loc) => _SectionCard(title: 'Location', rows: [
        ('Site', loc.siteName),
        ('Building', loc.buildingName),
        ('Floor', loc.floorName),
        ('Space', loc.spaceName),
      ]),
    );
  }
}

class _AssetLocation {
  const _AssetLocation({this.siteName, this.buildingName, this.floorName, this.spaceName});
  final String? siteName;
  final String? buildingName;
  final String? floorName;
  final String? spaceName;
}

final _assetLocationProvider = FutureProvider.family<_AssetLocation, Asset>((ref, asset) async {
  final db = ref.watch(appDatabaseProvider);
  final site = await db.locationDao.siteById(asset.siteId);
  if (asset.spaceId == null) {
    return _AssetLocation(siteName: site?.name);
  }
  final space = await db.locationDao.spaceById(asset.spaceId!);
  final floor = space != null ? await db.locationDao.floorById(space.floorId) : null;
  final building = floor != null ? await db.locationDao.buildingById(floor.buildingId) : null;
  return _AssetLocation(
    siteName: site?.name,
    buildingName: building?.name,
    floorName: floor?.name,
    spaceName: space?.name,
  );
});

class _OperationalSection extends ConsumerWidget {
  const _OperationalSection({required this.db, required this.asset});
  final AppDatabase db;
  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meters = ref.watch(_metersProvider(asset.id)).value ?? const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operational', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _Row('Status', asset.status.replaceAll('_', ' ')),
            _Row('Criticality', asset.criticality),
            if (asset.healthScore != null)
              _Row('Health score', '${(asset.healthScore! * 100).round()}%'),
            if (meters.isNotEmpty) ...[
              const Divider(height: 20),
              Text('Meters', style: Theme.of(context).textTheme.labelMedium),
              for (final meter in meters)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(meter.meterType.replaceAll('_', ' ')),
                  subtitle: Text(meter.currentValue != null
                      ? '${meter.currentValue} ${meter.unit}'
                      : 'No reading yet'),
                  trailing: TextButton(
                    onPressed: () => showMeterReadingDialog(context, ref, meter: meter),
                    child: const Text('Record'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

final _metersProvider = FutureProvider.family<List<AssetMeter>, String>((ref, assetId) {
  return ref.watch(appDatabaseProvider).assetDao.metersFor(assetId);
});

class _CommercialSection extends StatelessWidget {
  const _CommercialSection({required this.asset});
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return _SectionCard(title: 'Commercial', rows: [
      ('Purchase date', asset.purchaseDate != null ? fmt.format(asset.purchaseDate!) : null),
      ('Purchase cost', asset.purchaseCost != null ? currency.format(asset.purchaseCost) : null),
      ('Vendor', asset.vendorName),
      ('Warranty until', asset.warrantyEndDate != null ? fmt.format(asset.warrantyEndDate!) : null),
      ('AMC until', asset.amcEndDate != null ? fmt.format(asset.amcEndDate!) : null),
    ]);
  }
}

class _MaintenanceSection extends ConsumerWidget {
  const _MaintenanceSection({required this.db, required this.asset});
  final AppDatabase db;
  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetId = asset.id;
    final fmt = DateFormat.yMMMd();
    final historyAsync = ref.watch(_woHistoryProvider(assetId));

    return historyAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
      error: (e, _) => Text('Could not load maintenance history: $e'),
      data: (history) {
        final open = history.where((w) => !_terminal.contains(w.status)).toList();
        final failures = history
            .where((w) => w.type == 'reactive' && w.actualStart != null && _terminal.contains(w.status))
            .toList()
          ..sort((a, b) => a.actualStart!.compareTo(b.actualStart!));

        final mttrMinutes = failures.where((w) => w.actualMinutes != null).map((w) => w.actualMinutes!);
        final mttr = mttrMinutes.isEmpty ? null : mttrMinutes.reduce((a, b) => a + b) / mttrMinutes.length;

        double? mtbfDays;
        if (failures.length > 1) {
          final gaps = <double>[];
          for (var i = 1; i < failures.length; i++) {
            gaps.add(failures[i].actualStart!.difference(failures[i - 1].actualStart!).inHours / 24.0);
          }
          mtbfDays = gaps.reduce((a, b) => a + b) / gaps.length;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Maintenance', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (asset.lastServiceDate != null)
                  Row(children: [
                    const SizedBox(width: 120, child: Text('Last service', style: TextStyle(color: Colors.grey))),
                    Expanded(child: Text(fmt.format(asset.lastServiceDate!))),
                  ]),
                if (asset.nextServiceDate != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const SizedBox(width: 120, child: Text('Next service', style: TextStyle(color: Colors.grey))),
                    Expanded(child: Text(fmt.format(asset.nextServiceDate!))),
                  ]),
                ],
                const SizedBox(height: 4),
                Row(children: [
                  const SizedBox(width: 120, child: Text('Open WO', style: TextStyle(color: Colors.grey))),
                  Expanded(child: Text(open.isEmpty ? 'None' : open.map((w) => w.woNumber).join(', '))),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const SizedBox(width: 120, child: Text('Failures', style: TextStyle(color: Colors.grey))),
                  Expanded(child: Text('${failures.length} recorded')),
                ]),
                if (mttr != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const SizedBox(width: 120, child: Text('MTTR', style: TextStyle(color: Colors.grey))),
                    Expanded(child: Text('${(mttr / 60).toStringAsFixed(1)} h average repair time')),
                  ]),
                ],
                if (mtbfDays != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const SizedBox(width: 120, child: Text('MTBF', style: TextStyle(color: Colors.grey))),
                    Expanded(child: Text('${mtbfDays.toStringAsFixed(1)} days between failures')),
                  ]),
                ],
                if (failures.isNotEmpty) ...[
                  const Divider(height: 20),
                  Text('Failure history', style: Theme.of(context).textTheme.labelMedium),
                  for (final w in failures.reversed)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        '• ${w.woNumber} — ${w.problemDescription ?? w.failureCode ?? 'No description'}'
                        '${w.actualStart != null ? ' (${DateFormat.yMMMd().format(w.actualStart!)})' : ''}',
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

const _terminal = {'closed', 'cancelled', 'rejected', 'duplicate', 'verified', 'work_completed'};

final _woHistoryProvider = FutureProvider.family<List<WorkOrder>, String>((ref, assetId) {
  return ref.watch(appDatabaseProvider).workOrderDao.forAsset(assetId);
});

class _DocumentsSection extends ConsumerWidget {
  const _DocumentsSection({required this.db, required this.assetId});
  final AppDatabase db;
  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(_documentsProvider(assetId));
    final docs = docsAsync.value ?? const [];
    if (docs.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final doc in docs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_iconFor(doc.documentType)),
                title: Text(doc.title),
                subtitle: Text(doc.documentType),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => launchUrl(Uri.parse(doc.url), mode: LaunchMode.externalApplication),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'manual' => Icons.menu_book_outlined,
        'warranty' => Icons.verified_outlined,
        'drawing' => Icons.architecture_outlined,
        'sop' => Icons.checklist_outlined,
        'certificate' => Icons.workspace_premium_outlined,
        _ => Icons.description_outlined,
      };
}

final _documentsProvider = FutureProvider.family<List<AssetDocument>, String>((ref, assetId) {
  return ref.watch(appDatabaseProvider).assetDao.documentsFor(assetId);
});
