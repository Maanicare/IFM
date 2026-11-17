import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../identity/presentation/auth_controller.dart';
import '../../location/presentation/current_site_provider.dart';
import 'shift_handover_controller.dart';

/// SCREEN 26 - Shift Handover (incoming side + entry point for starting
/// a new one). Shows the most recent handover for the current site and
/// requires an explicit acknowledgement before it's considered read -
/// a technician should never be able to claim later "nobody told me".
class ShiftHandoverScreen extends ConsumerWidget {
  const ShiftHandoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider).value;
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Shift handover')),
      floatingActionButton: siteId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/shift-handover/new', extra: siteId),
              icon: const Icon(Icons.add),
              label: const Text('New handover'),
            ),
      body: siteId == null
          ? const Center(child: Text('No site selected.'))
          : _LatestHandover(siteId: siteId, currentUserId: user?.id),
    );
  }
}

class _LatestHandover extends ConsumerWidget {
  const _LatestHandover({required this.siteId, required this.currentUserId});

  final String siteId;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handoverAsync = ref.watch(_latestHandoverProvider(siteId));

    return handoverAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load handover: $e')),
      data: (handover) {
        if (handover == null) {
          return const Center(child: Text('No handover recorded for this site yet.'));
        }

        final acknowledged = handover.acknowledgedBy != null;
        final isOwnHandover = handover.createdBy == currentUserId;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            if (!acknowledged && !isOwnHandover)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Read this before starting your shift, then acknowledge below.'),
                    ),
                  ],
                ),
              ),
            Text(
              'Handover from previous shift',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _Section(label: 'Open jobs', value: handover.openJobsNote),
            _Section(label: 'Equipment issue', value: handover.equipmentIssueNote),
            _Section(label: 'Temporary fix in place', value: handover.temporaryFixNote),
            _Section(label: 'Vendor expected', value: handover.vendorExpectedNote),
            _Section(label: 'Safety concern', value: handover.safetyConcernNote, isWarning: true),
            _Section(label: 'Client commitment made', value: handover.clientCommitmentNote),
            _Section(label: 'Material shortage', value: handover.materialShortageNote),
            _Section(label: 'Special instruction', value: handover.specialInstructionNote),
            const SizedBox(height: 16),
            if (acknowledged)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text('Acknowledged', style: TextStyle(color: Colors.green.shade700)),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Acknowledge handover'),
                  onPressed: () => ref
                      .read(shiftHandoverControllerProvider.notifier)
                      .acknowledge(handover.id, siteId: siteId),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.value, this.isWarning = false});

  final String label;
  final String? value;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isWarning ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isWarning) const Icon(Icons.warning_amber, size: 16, color: Colors.red),
                if (isWarning) const SizedBox(width: 6),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(value!),
          ],
        ),
      ),
    );
  }
}

final _latestHandoverProvider =
    StreamProvider.family<ShiftHandover?, String>((ref, siteId) {
  final db = ref.watch(appDatabaseProvider);
  return db.shiftHandoverDao.watchLatestForSite(siteId);
});
