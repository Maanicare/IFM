import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../location/presentation/current_site_provider.dart';

/// SCREEN 43 - Reservation (available spaces). "Floor map" isn't shown -
/// this app has no floor-plan/CAD data (that's Screen 18's Web/BIM
/// concern) - this is a plain list instead.
class ReservationScreen extends ConsumerWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Available spaces')),
      body: siteId == null
          ? const Center(child: Text('No site selected.'))
          : _SpaceList(siteId: siteId),
    );
  }
}

class _SpaceList extends ConsumerWidget {
  const _SpaceList({required this.siteId});
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(_reservableSpacesProvider(siteId));

    return spacesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load spaces: $e')),
      data: (spaces) {
        if (spaces.isEmpty) {
          return const Center(child: Text('No reservable spaces at this site.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: spaces.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final space = spaces[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.meeting_room_outlined),
                title: Text(space.name),
                subtitle: Text([
                  if (space.capacity != null) 'Capacity ${space.capacity}',
                  if (space.equipmentNote != null) space.equipmentNote!,
                ].join(' · ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/reservations/${space.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

final _reservableSpacesProvider = FutureProvider.family<List<Space>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).locationDao.reservableSpacesAtSite(siteId);
});
