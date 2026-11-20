import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../requests/presentation/request_controller.dart';

/// SCREEN 22 - Washroom Experience (detail). Display fields plus the
/// spec's "QR Options" - each one creates a Create Request entry
/// against this washroom's space (see the doc comment on `Washrooms`
/// in washroom_tables.dart for why this doesn't have its own separate
/// reporting model).
class WashroomDetailScreen extends ConsumerWidget {
  const WashroomDetailScreen({super.key, required this.washroomId});

  final String washroomId;

  static const _qrOptions = [
    ('Cleaning', 'housekeeping', Icons.cleaning_services_outlined),
    ('Tissue', 'washroom_tissue', Icons.receipt_long_outlined),
    ('Soap', 'washroom_soap', Icons.soap_outlined),
    ('Odour', 'washroom_odour', Icons.air_outlined),
    ('Plumbing', 'plumbing', Icons.plumbing_outlined),
    ('Other', 'general', Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final washroomAsync = ref.watch(_washroomStreamProvider(washroomId));
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Washroom')),
      body: washroomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (washroom) {
          if (washroom == null) return const Center(child: Text('Not found.'));
          final space = ref.watch(_spaceProvider(washroom.spaceId)).value;
          final complaints = ref.watch(_complaintsProvider(washroom.spaceId)).value ?? const [];
          final fmt = DateFormat.yMMMd().add_Hm();
          final canReport = accessContext != null &&
              guard.can(accessContext, AppAction.createServiceRequest, siteId: washroom.siteId);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(space?.name ?? washroom.spaceId, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _StatusCard(washroom: washroom, fmt: fmt),
              const SizedBox(height: 12),
              if (complaints.isNotEmpty) _ComplaintsCard(complaints: complaints),
              if (complaints.isNotEmpty) const SizedBox(height: 12),
              if (canReport) _QrOptionsCard(washroom: washroom),
            ],
          );
        },
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.washroom, required this.fmt});
  final Washroom washroom;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row('Cleaning status', washroom.cleaningStatus.replaceAll('_', ' ')),
            if (washroom.lastAttendedAt != null) _Row('Last attended', fmt.format(washroom.lastAttendedAt!)),
            if (washroom.nextDueAt != null) _Row('Next due', fmt.format(washroom.nextDueAt!)),
            _Row('Tissue', washroom.tissueStatus),
            _Row('Soap', washroom.soapStatus),
            if (washroom.sensorAlertNote != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.sensors, size: 14, color: Colors.orange.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          washroom.sensorAlertNote!,
                          style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ComplaintsCard extends StatelessWidget {
  const _ComplaintsCard({required this.complaints});
  final List<ServiceRequest> complaints;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Complaints (${complaints.length})', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final r in complaints)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: InkWell(
                  onTap: () => context.push('/requests/${r.id}'),
                  child: Text('• ${r.title} (${r.status.replaceAll('_', ' ')})'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QrOptionsCard extends ConsumerStatefulWidget {
  const _QrOptionsCard({required this.washroom});
  final Washroom washroom;

  @override
  ConsumerState<_QrOptionsCard> createState() => _QrOptionsCardState();
}

class _QrOptionsCardState extends ConsumerState<_QrOptionsCard> {
  bool _submitting = false;

  Future<void> _report(String label, String categoryId) async {
    setState(() => _submitting = true);
    try {
      await ref.read(requestControllerProvider.notifier).createRequest(
            siteId: widget.washroom.siteId,
            spaceId: widget.washroom.spaceId,
            categoryId: categoryId,
            title: 'Washroom: $label',
            priority: 'medium',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reported: $label')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report an issue', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, categoryId, icon) in WashroomDetailScreen._qrOptions)
                  OutlinedButton.icon(
                    icon: Icon(icon, size: 18),
                    label: Text(label),
                    onPressed: _submitting ? null : () => _report(label, categoryId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final _washroomStreamProvider = StreamProvider.family<Washroom?, String>((ref, id) {
  return ref.watch(appDatabaseProvider).washroomDao.watchById(id);
});

final _spaceProvider = FutureProvider.family<Space?, String>((ref, spaceId) {
  return ref.watch(appDatabaseProvider).locationDao.spaceById(spaceId);
});

final _complaintsProvider = StreamProvider.family<List<ServiceRequest>, String>((ref, spaceId) {
  return ref.watch(appDatabaseProvider).requestDao.watchOpenAtSpace(spaceId);
});
