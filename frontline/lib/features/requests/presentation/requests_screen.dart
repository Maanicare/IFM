import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../identity/presentation/auth_controller.dart';

/// SCREEN 05 - Request List, trimmed to the current site for the
/// frontline context (full cross-site filters belong to the manager/
/// desktop surface, Section 14).
class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final siteId = user?.siteIds.isNotEmpty == true ? user!.siteIds.first : null;
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Requests')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/requests/new'),
        child: const Icon(Icons.add),
      ),
      body: siteId == null
          ? const Center(child: Text('No site assigned.'))
          : StreamBuilder<List<ServiceRequest>>(
              stream: db.requestDao.watchForSite(siteId),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? const [];
                if (requests.isEmpty) {
                  return const Center(child: Text('No requests yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = requests[index];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: PriorityColors.of(r.priority),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(r.title),
                        subtitle: Text('${r.requestNumber} · ${r.status.replaceAll('_', ' ')}'),
                        onTap: () => context.push('/requests/${r.id}'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
