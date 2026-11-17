import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../identity/presentation/auth_controller.dart';
import '../../sla/presentation/sla_chip.dart';
import '../domain/work_order_status.dart';
import 'safety_gate_sheet.dart';
import 'work_order_actions_controller.dart';

/// SCREEN 10 - Technician My Work: Now / Next / Later, with one-swipe
/// accept/start actions available from the detail screen. Exposed as a
/// top-level provider so the Home screen's summary card can reuse the
/// same live stream without a second DB subscription.
final myWorkStreamProvider = StreamProvider<List<WorkOrder>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();
  return db.workOrderDao.watchAssignedTo(user.id);
});

class MyWorkScreen extends ConsumerWidget {
  const MyWorkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workOrdersAsync = ref.watch(myWorkStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Work')),
      body: workOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load work: $e')),
        data: (workOrders) {
          if (workOrders.isEmpty) {
            return const Center(child: Text('No jobs assigned right now.'));
          }
          final now = _section(workOrders, 'now');
          final next = _section(workOrders, 'next');
          final later = _section(workOrders, 'later');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (now.isNotEmpty) _SectionHeader('Now'),
              ...now.map((w) => _JobCard(workOrder: w)),
              if (next.isNotEmpty) _SectionHeader('Next'),
              ...next.map((w) => _JobCard(workOrder: w)),
              if (later.isNotEmpty) _SectionHeader('Later'),
              ...later.map((w) => _JobCard(workOrder: w)),
            ],
          );
        },
      ),
    );
  }

  /// Buckets by urgency + schedule proximity: anything critical/high or
  /// already in progress is "now"; scheduled within the next 2 hours is
  /// "next"; everything else is "later".
  List<WorkOrder> _section(List<WorkOrder> all, String section) {
    final nowTime = DateTime.now();
    return all.where((w) {
      final isActive = w.status == 'checked_in' ||
          w.status == 'in_progress' ||
          w.priority == 'critical';
      final untilStart = w.scheduledStart?.difference(nowTime);
      // Only a *future* start within the window counts as "starting soon" -
      // a negative duration (schedule already passed) must not satisfy
      // "< 2 hours" and get bucketed ahead of jobs that are actually next.
      final startsSoon = untilStart != null &&
          !untilStart.isNegative &&
          untilStart < const Duration(hours: 2);
      switch (section) {
        case 'now':
          return isActive;
        case 'next':
          return !isActive && startsSoon;
        default:
          return !isActive && !startsSoon;
      }
    }).toList();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.workOrder});
  final WorkOrder workOrder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/work-orders/${workOrder.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: PriorityColors.of(workOrder.priority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workOrder.woNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SlaChip(
                    target: workOrder.slaResolutionTarget,
                    pauseDuration: Duration(seconds: workOrder.slaPauseSeconds),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(workOrder.problemDescription ?? 'No description'),
              const SizedBox(height: 6),
              Text(
                workOrder.status.replaceAll('_', ' '),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );

    final label = switch (workOrder.status) {
      WorkOrderStatus.assigned => 'Accept',
      WorkOrderStatus.accepted => 'Start route',
      WorkOrderStatus.checkedIn => 'Start work',
      _ => null,
    };
    if (label == null) return card;

    return Dismissible(
      key: ValueKey(workOrder.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.check, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        final actions = ref.read(workOrderActionsControllerProvider.notifier);
        switch (workOrder.status) {
          case WorkOrderStatus.assigned:
            await actions.accept(workOrder.id);
          case WorkOrderStatus.accepted:
            await actions.startRoute(workOrder.id);
          case WorkOrderStatus.checkedIn:
            await startWorkWithSafetyGate(context, ref, actions, workOrder.id);
        }
        return false; // status changed in place; the card isn't removed from the list.
      },
      child: card,
    );
  }
}
