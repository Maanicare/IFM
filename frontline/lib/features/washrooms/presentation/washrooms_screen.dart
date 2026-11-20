import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../location/presentation/current_site_provider.dart';

/// SCREEN 22 - Washroom Experience (list). One entry per washroom at the
/// current site, status-first so a Housekeeping Supervisor sees what
/// needs attention without opening each one.
class WashroomsScreen extends ConsumerWidget {
  const WashroomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Washrooms')),
      body: siteId == null
          ? const Center(child: Text('No site selected.'))
          : _WashroomList(siteId: siteId),
    );
  }
}

class _WashroomList extends ConsumerWidget {
  const _WashroomList({required this.siteId});
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final washroomsAsync = ref.watch(_washroomsProvider(siteId));

    return washroomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load washrooms: $e')),
      data: (washrooms) {
        if (washrooms.isEmpty) {
          return const Center(child: Text('No washrooms configured for this site.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: washrooms.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _WashroomCard(washroom: washrooms[index]),
        );
      },
    );
  }
}

class _WashroomCard extends ConsumerWidget {
  const _WashroomCard({required this.washroom});
  final Washroom washroom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(_spaceProvider(washroom.spaceId)).value;
    final statusColor = switch (washroom.cleaningStatus) {
      'clean' => Colors.green,
      'needs_attention' => Colors.orange,
      'overdue' => Colors.red,
      _ => Colors.grey,
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/washrooms/${washroom.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(space?.name ?? washroom.spaceId, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(washroom.cleaningStatus.replaceAll('_', ' '), style: TextStyle(color: statusColor, fontSize: 12)),
                  ],
                ),
              ),
              if (washroom.sensorAlertNote != null)
                const Icon(Icons.sensors, size: 18, color: Colors.orange),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

final _washroomsProvider = StreamProvider.family<List<Washroom>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).washroomDao.watchForSite(siteId);
});

final _spaceProvider = FutureProvider.family<Space?, String>((ref, spaceId) {
  return ref.watch(appDatabaseProvider).locationDao.spaceById(spaceId);
});
