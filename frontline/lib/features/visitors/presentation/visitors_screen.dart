import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../location/presentation/current_site_provider.dart';

/// SCREEN 44 - Visitor Management (list).
class VisitorsScreen extends ConsumerWidget {
  const VisitorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Visitors')),
      floatingActionButton: siteId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/visitors/new'),
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Check in'),
            ),
      body: siteId == null
          ? const Center(child: Text('No site selected.'))
          : _VisitorList(siteId: siteId),
    );
  }
}

class _VisitorList extends ConsumerWidget {
  const _VisitorList({required this.siteId});
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(_visitsProvider(siteId)).value ?? const [];
    if (visits.isEmpty) {
      return const Center(child: Text('No visitors recorded yet.'));
    }
    final fmt = DateFormat.Hm();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: visits.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final v = visits[index];
        final statusColor = v.status == 'checked_in' ? Colors.green : Colors.grey;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(Icons.badge_outlined, color: statusColor),
            ),
            title: Text(v.visitorName),
            subtitle: Text(
              '${v.company ?? "—"} · Host: ${v.hostName}'
              '${v.actualArrival != null ? " · ${fmt.format(v.actualArrival!)}" : ""}',
            ),
            trailing: Text(
              v.status.replaceAll('_', ' '),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
            onTap: () => context.push('/visitors/${v.id}'),
          ),
        );
      },
    );
  }
}

final _visitsProvider = StreamProvider.family<List<Visit>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).visitorDao.watchForSite(siteId);
});
