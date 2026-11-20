import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../location/presentation/current_site_provider.dart';
import '../domain/permit_type.dart';

/// SCREEN 37 - Permit to Work (list).
class PermitsScreen extends ConsumerWidget {
  const PermitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Permits to Work')),
      floatingActionButton: siteId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/permits/new', extra: {'siteId': siteId}),
              icon: const Icon(Icons.add),
              label: const Text('Issue permit'),
            ),
      body: siteId == null
          ? const Center(child: Text('No site selected.'))
          : _PermitList(siteId: siteId),
    );
  }
}

class _PermitList extends ConsumerWidget {
  const _PermitList({required this.siteId});
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permits = ref.watch(_permitsProvider(siteId)).value ?? const [];
    if (permits.isEmpty) {
      return const Center(child: Text('No permits issued yet.'));
    }
    final fmt = DateFormat.yMMMd().add_Hm();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: permits.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final permit = permits[index];
        final type = PermitType.values.byName(permit.permitType);
        final statusColor = switch (permit.status) {
          'active' => Colors.orange,
          'closed' => Colors.green,
          _ => Colors.grey,
        };

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/permits/${permit.id}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(permit.permitNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(permit.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(type.label),
                  Text(
                    '${fmt.format(permit.validFrom)} → ${fmt.format(permit.validTo)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final _permitsProvider = StreamProvider.family<List<Permit>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).permitDao.watchForSite(siteId);
});
