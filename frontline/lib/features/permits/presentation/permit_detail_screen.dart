import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../domain/permit_type.dart';
import 'permit_controller.dart';

/// SCREEN 37 - Permit to Work (detail). Display: Risk assessment;
/// Authorised persons; Start/end; Controls; Isolation; Approvals
/// (Issuer/Receiver + status).
class PermitDetailScreen extends ConsumerWidget {
  const PermitDetailScreen({super.key, required this.permitId});

  final String permitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permitAsync = ref.watch(_permitStreamProvider(permitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Permit to Work')),
      body: permitAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (permit) {
          if (permit == null) return const Center(child: Text('Not found.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(permit: permit),
              const SizedBox(height: 16),
              _DisplayCard(permit: permit),
              const SizedBox(height: 12),
              _PhotosSection(permitId: permit.id),
              const SizedBox(height: 16),
              _ActionBar(permit: permit),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.permit});
  final Permit permit;

  @override
  Widget build(BuildContext context) {
    final type = PermitType.values.byName(permit.permitType);
    final statusColor = switch (permit.status) {
      'active' => Colors.orange,
      'closed' => Colors.green,
      _ => Colors.grey,
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(permit.permitNumber, style: Theme.of(context).textTheme.titleLarge),
              Text(type.label),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Text(permit.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }
}

class _DisplayCard extends StatelessWidget {
  const _DisplayCard({required this.permit});
  final Permit permit;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd().add_Hm();
    final rows = <(String, String?)>[
      ('Start', fmt.format(permit.validFrom)),
      ('End', fmt.format(permit.validTo)),
      ('Issuer', permit.issuerName),
      ('Receiver', permit.receiverName),
      ('Authorised persons', permit.authorisedPersons),
      ('Vendor', permit.vendorName),
      ('Risk assessment', permit.riskAssessmentNote),
      ('Controls', permit.controlsNote),
      ('Isolation', permit.isolationNote),
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
                    SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey))),
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

class _PhotosSection extends ConsumerWidget {
  const _PhotosSection({required this.permitId});
  final String permitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(_attachmentsProvider(permitId)).value ?? const [];
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Risk assessment photo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final a in attachments)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(a.localPath), height: 160, fit: BoxFit.cover),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.permit});
  final Permit permit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    if (permit.status != 'active' ||
        accessContext == null ||
        !guard.can(accessContext, AppAction.managePermit, siteId: permit.siteId)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => ref.read(permitControllerProvider.notifier).closePermit(permit.id, siteId: permit.siteId),
        child: const Text('Close permit'),
      ),
    );
  }
}

final _permitStreamProvider = StreamProvider.family<Permit?, String>((ref, id) {
  return ref.watch(appDatabaseProvider).permitDao.watchById(id);
});

final _attachmentsProvider = StreamProvider.family<List<Attachment>, String>((ref, permitId) {
  return ref.watch(appDatabaseProvider).attachmentDao.watchFor('permit', permitId);
});
