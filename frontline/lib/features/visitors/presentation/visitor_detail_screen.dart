import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import 'visitor_controller.dart';

/// SCREEN 44 - Visitor Management (detail). Output: Generate QR pass -
/// the visit's own `passId` encoded as a QR, scannable to look the
/// visit back up (no access-control/turnstile integration exists).
class VisitorDetailScreen extends ConsumerWidget {
  const VisitorDetailScreen({super.key, required this.visitId});

  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitAsync = ref.watch(_visitStreamProvider(visitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Visitor pass')),
      body: visitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (visit) {
          if (visit == null) return const Center(child: Text('Not found.'));
          final fmt = DateFormat.yMMMd().add_Hm();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: QrImageView(data: visit.passId, size: 180),
                    ),
                    const SizedBox(height: 8),
                    Text(visit.passId, style: const TextStyle(fontFamily: 'monospace', color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(visit.visitorName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _DetailsCard(visit: visit, fmt: fmt),
              const SizedBox(height: 16),
              _ActionBar(visit: visit),
            ],
          );
        },
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.visit, required this.fmt});
  final Visit visit;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      ('Status', visit.status.replaceAll('_', ' ')),
      ('Company', visit.company),
      ('Host', visit.hostName),
      ('Purpose', visit.purpose),
      ('Mobile', visit.visitorMobile),
      ('Email', visit.visitorEmail),
      ('Vehicle', visit.vehicleNumber),
      ('ID verified', visit.idVerified ? 'Yes${visit.idTypeNote != null ? " (${visit.idTypeNote})" : ""}' : 'No'),
      ('Access requirements', visit.accessRequirementsNote),
      ('Arrival', visit.actualArrival != null ? fmt.format(visit.actualArrival!) : null),
      ('Departure', visit.actualDeparture != null ? fmt.format(visit.actualDeparture!) : null),
    ].where((r) => r.$2 != null).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey))),
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

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.visit});
  final Visit visit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    if (visit.status != 'checked_in' ||
        accessContext == null ||
        !guard.can(accessContext, AppAction.manageVisitor, siteId: visit.siteId)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => ref.read(visitorControllerProvider.notifier).checkOut(visit.id, siteId: visit.siteId),
        child: const Text('Check out'),
      ),
    );
  }
}

final _visitStreamProvider = StreamProvider.family<Visit?, String>((ref, id) {
  return ref.watch(appDatabaseProvider).visitorDao.watchById(id);
});
