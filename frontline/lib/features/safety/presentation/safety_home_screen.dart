import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../inspections/presentation/inspection_controller.dart';
import '../../location/presentation/current_site_provider.dart';

/// SCREEN 34 - Safety Home. All tiles are computed client-side from the
/// same streams the Incident/Hazard/Inspection list screens already
/// watch - no separate aggregate-count query needed.
///
/// "PTW active" always reads 0 - Permit to Work (Screen 37) isn't built
/// in this app yet (see PENDING_FEATURES.md), so there is no Permits
/// table to count from. Shown honestly as "not available" rather than
/// a fake zero that looks like a real "no active permits" answer.
class SafetyHomeScreen extends ConsumerWidget {
  const SafetyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Safety')),
      body: siteId == null
          ? const Center(child: Text('No site selected.'))
          : _SafetyHomeBody(siteId: siteId),
    );
  }
}

class _SafetyHomeBody extends ConsumerWidget {
  const _SafetyHomeBody({required this.siteId});
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(_incidentsProvider(siteId)).value ?? const [];
    final hazards = ref.watch(_hazardsProvider(siteId)).value ?? const [];
    final inspections = ref.watch(_inspectionsProvider(siteId)).value ?? const [];
    final now = DateTime.now();

    final activeIncidents =
        incidents.where((i) => i.type != 'near_miss' && i.investigationStatus != 'closed').length;
    final nearMisses = incidents.where((i) => i.type == 'near_miss').length;
    final openHazards = hazards.where((h) => h.status == 'open').length;

    final overdueHazards = hazards
        .where((h) => h.status == 'open' && h.targetDate != null && h.targetDate!.isBefore(now))
        .length;
    final overdueInspectionTasks = inspections
        .where((i) =>
            !i.correctiveCompleted && i.correctiveDueDate != null && i.correctiveDueDate!.isBefore(now))
        .length;
    final correctiveActionsOverdue = overdueHazards + overdueInspectionTasks;

    final recentInspections = inspections.where((i) => now.difference(i.inspectedAt).inDays <= 30).toList();
    final avgInspectionScore = recentInspections.isEmpty
        ? null
        : recentInspections.map((i) => i.score).reduce((a, b) => a + b) / recentInspections.length;

    final lastInjury = incidents.where((i) => i.injury).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final daysWithoutLostTime = lastInjury.isEmpty ? null : now.difference(lastInjury.first.occurredAt).inDays;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _StatTile(
              label: 'Active incidents',
              value: '$activeIncidents',
              color: activeIncidents > 0 ? Colors.red : Colors.green,
              onTap: () => context.push('/report-safety-issue'),
            ),
            _StatTile(label: 'Open hazards', value: '$openHazards', color: openHazards > 0 ? Colors.orange : Colors.green),
            _StatTile(label: 'Near misses', value: '$nearMisses', color: Colors.blueGrey),
            const _StatTile(label: 'PTW active', value: 'N/A', color: Colors.grey, subtitle: 'Not yet available'),
            _StatTile(
              label: 'Corrective actions overdue',
              value: '$correctiveActionsOverdue',
              color: correctiveActionsOverdue > 0 ? Colors.red : Colors.green,
            ),
            _StatTile(
              label: 'Inspection score',
              value: avgInspectionScore != null ? avgInspectionScore.toStringAsFixed(0) : '—',
              color: avgInspectionScore == null
                  ? Colors.grey
                  : (avgInspectionScore >= 80 ? Colors.green : Colors.orange),
              onTap: () => context.push('/inspections'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  daysWithoutLostTime != null ? '$daysWithoutLostTime' : '—',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const Text('Days without a lost-time incident', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (overdueHazards + overdueInspectionTasks > 0)
          _OverdueCorrectiveActions(hazards: hazards, inspections: inspections, now: now, siteId: siteId),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color, this.subtitle, this.onTap});
  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen 34's overdue count expanded into an actionable list -
/// otherwise a technician sees "2 overdue" with no way to act on it.
class _OverdueCorrectiveActions extends ConsumerWidget {
  const _OverdueCorrectiveActions({
    required this.hazards,
    required this.inspections,
    required this.now,
    required this.siteId,
  });

  final List<Hazard> hazards;
  final List<SoftServiceInspection> inspections;
  final DateTime now;
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    final canComplete =
        accessContext != null && guard.can(accessContext, AppAction.manageCleaningTask, siteId: siteId);
    final fmt = DateFormat.yMMMd();

    final overdueHazards =
        hazards.where((h) => h.status == 'open' && h.targetDate != null && h.targetDate!.isBefore(now));
    final overdueInspections = inspections.where(
      (i) => !i.correctiveCompleted && i.correctiveDueDate != null && i.correctiveDueDate!.isBefore(now),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overdue corrective actions', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final h in overdueHazards)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                title: Text(h.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('Due ${fmt.format(h.targetDate!)}${h.ownerName != null ? ' · ${h.ownerName}' : ''}'),
              ),
            for (final i in overdueInspections)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.fact_check_outlined, color: Colors.orange, size: 20),
                title: Text(i.correctiveTaskNote ?? 'Corrective task', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  'Due ${fmt.format(i.correctiveDueDate!)}${i.correctiveOwnerName != null ? ' · ${i.correctiveOwnerName}' : ''}',
                ),
                trailing: canComplete
                    ? TextButton(
                        onPressed: () => ref
                            .read(inspectionControllerProvider.notifier)
                            .markCorrectiveComplete(i.id, siteId: siteId),
                        child: const Text('Done'),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

final _incidentsProvider = StreamProvider.family<List<Incident>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).safetyDao.watchIncidentsForSite(siteId);
});

final _hazardsProvider = StreamProvider.family<List<Hazard>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).safetyDao.watchHazardsForSite(siteId);
});

final _inspectionsProvider = StreamProvider.family<List<SoftServiceInspection>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).softServiceInspectionDao.watchForSite(siteId);
});
