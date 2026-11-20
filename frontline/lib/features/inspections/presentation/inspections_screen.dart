import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../location/presentation/current_site_provider.dart';
import '../domain/soft_service_template.dart';

/// SCREEN 23 - Soft Service Inspection (list). Past inspections at the
/// current site, most recent first.
class InspectionsScreen extends ConsumerWidget {
  const InspectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Soft Service Inspections')),
      floatingActionButton: siteId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/inspections/new'),
              icon: const Icon(Icons.add),
              label: const Text('New inspection'),
            ),
      body: siteId == null
          ? const Center(child: Text('No site selected.'))
          : _InspectionList(siteId: siteId),
    );
  }
}

class _InspectionList extends ConsumerWidget {
  const _InspectionList({required this.siteId});
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspections = ref.watch(_inspectionsProvider(siteId)).value ?? const [];
    if (inspections.isEmpty) {
      return const Center(child: Text('No inspections recorded yet.'));
    }
    final fmt = DateFormat.yMMMd().add_Hm();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: inspections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final inspection = inspections[index];
        final template = SoftServiceTemplate.values.byName(inspection.template);
        final scoreColor = inspection.score >= 80
            ? Colors.green
            : (inspection.score >= 50 ? Colors.orange : Colors.red);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      inspection.score.toStringAsFixed(0),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scoreColor),
                    ),
                    const Text('score', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(fmt.format(inspection.inspectedAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      if (inspection.nonConformanceNote != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            inspection.nonConformanceNote!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final _inspectionsProvider = StreamProvider.family<List<SoftServiceInspection>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).softServiceInspectionDao.watchForSite(siteId);
});
