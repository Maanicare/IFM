import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/daos/inventory_dao.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/theme/app_theme.dart';
import '../../identity/presentation/auth_controller.dart';
import '../../location/presentation/current_site_provider.dart';
import '../../work_orders/domain/work_order_status.dart';
import '../../work_orders/presentation/my_work_screen.dart' show myWorkStreamProvider;

/// SCREEN 03 - Personal Home. Shows only what this shift needs right now:
/// urgent work, pending work, alerts and quick actions - deliberately not
/// the executive metrics a manager role would see (Section 8).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final workOrders = ref.watch(myWorkStreamProvider).value ?? const [];
    final urgentCount = workOrders
        .where((w) => w.priority == 'critical' || w.priority == 'high')
        .length;
    final unreadNotifications =
        ref.watch(_unreadNotificationCountProvider).value ?? 0;
    final siteId = ref.watch(currentSiteIdProvider).value;
    final language = ref.watch(appLocaleProvider).value ?? 'en';
    String t(String key) => AppStrings.of(key, language);

    // Same tab visibility rule the shell uses (Section 8: a role with no
    // work-order/request actions shouldn't see shortcuts to screens it
    // can't do anything on either).
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    final tabs = accessContext != null
        ? guard.visibleTabs(accessContext)
        : const [AppTab.home, AppTab.more];
    final showMyWork = tabs.contains(AppTab.myWork);
    final showScan = tabs.contains(AppTab.scan);
    final showRequests = tabs.contains(AppTab.requests);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.name.split(' ').first ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (showMyWork) ...[
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${workOrders.length} ${t('jobsAssigned')}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            urgentCount > 0
                                ? '$urgentCount need urgent attention'
                                : t('nothingUrgent'),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => context.go('/my-work'),
                      child: Text(t('viewAction')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _StartTaskButton(workOrders: workOrders),
            const SizedBox(height: 16),
          ],
          // Site + shift together, as two compact chips - previously
          // two separate small grey text lines that read as leftover
          // debug text rather than a deliberate part of the screen.
          if (siteId != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SiteStatusChip(siteId: siteId, canSwitch: (user?.siteIds.length ?? 0) > 1),
                ),
                const SizedBox(width: 12),
                const Expanded(child: _CurrentShiftChip()),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (siteId != null &&
              accessContext != null &&
              guard.can(accessContext, AppAction.verifyWorkOrder)) ...[
            _PendingApprovalsRow(siteId: siteId),
            const SizedBox(height: 16),
          ],
          if (showRequests || showScan)
            Row(
              children: [
                if (showRequests)
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: t('reportIssue'),
                      onTap: () => context.push('/requests/new'),
                    ),
                  ),
                if (showRequests && showScan) const SizedBox(width: 12),
                if (showScan)
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.qr_code_scanner,
                      label: t('scanAsset'),
                      onTap: () => context.go('/scan'),
                    ),
                  ),
              ],
            ),
          if (siteId != null) ...[
            const SizedBox(height: 16),
            _SafetyAlertsRow(),
            const SizedBox(height: 12),
            _CriticalAssetsRow(siteId: siteId),
            const SizedBox(height: 12),
            _RequiredPartsRow(siteId: siteId),
          ],
        ],
      ),
    );
  }
}

/// Shared compact "fact" card for the site-status/shift pair - gives
/// both a matching boxed look instead of each being a bare line of
/// grey text that read as leftover debug output.
class _HomeChip extends StatelessWidget {
  const _HomeChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(sublabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Screen 03: "Site status" - the current site's operational state.
/// Also the one and only place Home surfaces "which site am I on" -
/// doubling that up with a second, differently-styled site label in
/// the AppBar (the previous design) read as two unrelated pieces of
/// UI rather than one coherent control, so switching lives here too
/// when the user has more than one site.
class _SiteStatusChip extends ConsumerWidget {
  const _SiteStatusChip({required this.siteId, required this.canSwitch});
  final String siteId;
  final bool canSwitch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final site = ref.watch(_siteNameProvider(siteId)).value;
    if (site == null) return const SizedBox.shrink();
    final isActive = site.operationalStatus == 'active';

    return _HomeChip(
      onTap: canSwitch ? () => context.push('/site-selector') : null,
      icon: isActive ? Icons.check_circle_outline : Icons.error_outline,
      iconColor: isActive ? Colors.green : Colors.orange,
      label: site.name,
      sublabel: isActive ? 'Operational' : site.operationalStatus,
      trailing: canSwitch ? Icon(Icons.swap_horiz, size: 16, color: Colors.grey.shade500) : null,
    );
  }
}

/// Screen 03: "Current shift" - today's own roster entry, if any.
class _CurrentShiftChip extends ConsumerWidget {
  const _CurrentShiftChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider).value;
    final userId = ref.watch(authControllerProvider).value?.id;
    if (siteId == null || userId == null) return const SizedBox.shrink();

    final shift = ref.watch(_myShiftProvider((siteId: siteId, userId: userId))).value;
    if (shift == null) return const SizedBox.shrink();

    String formatTime(DateTime t) => TimeOfDay.fromDateTime(t).format(context);

    return _HomeChip(
      icon: Icons.schedule,
      iconColor: Colors.grey.shade600,
      label: '${formatTime(shift.shiftStart)} - ${formatTime(shift.shiftEnd)}',
      sublabel: shift.attendanceStatus,
    );
  }
}

final _myShiftProvider =
    StreamProvider.family<ShiftRosterEntry?, ({String siteId, String userId})>((ref, args) {
  return ref
      .watch(appDatabaseProvider)
      .shiftRosterDao
      .watchMyShiftToday(args.siteId, args.userId, DateTime.now());
});

/// Screen 03 action: "Start task" - jumps straight into the next
/// actionable job (critical/high priority first, else the earliest
/// scheduled) instead of making the technician open My Work and pick.
class _StartTaskButton extends StatelessWidget {
  const _StartTaskButton({required this.workOrders});
  final List<WorkOrder> workOrders;

  static const _actionableStatuses = {
    WorkOrderStatus.assigned,
    WorkOrderStatus.accepted,
    WorkOrderStatus.enRoute,
    WorkOrderStatus.checkedIn,
    WorkOrderStatus.inProgress,
  };

  @override
  Widget build(BuildContext context) {
    final actionable = workOrders.where((w) => _actionableStatuses.contains(w.status)).toList()
      ..sort((a, b) {
        final aCritical = a.priority == 'critical' || a.priority == 'high';
        final bCritical = b.priority == 'critical' || b.priority == 'high';
        if (aCritical != bCritical) return aCritical ? -1 : 1;
        final aStart = a.scheduledStart;
        final bStart = b.scheduledStart;
        if (aStart == null || bStart == null) return 0;
        return aStart.compareTo(bStart);
      });
    if (actionable.isEmpty) return const SizedBox.shrink();

    final next = actionable.first;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: Text('Start task: ${next.woNumber}'),
        onPressed: () => context.push('/work-orders/${next.id}'),
      ),
    );
  }
}

/// Screen 03: "Approvals" - work completed and awaiting this role's
/// sign-off. Only rendered for a role that can act on it (gated at the
/// call site by `verifyWorkOrder`).
class _PendingApprovalsRow extends ConsumerWidget {
  const _PendingApprovalsRow({required this.siteId});
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(_pendingApprovalCountProvider(siteId)).value ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return InkWell(
      onTap: () => context.go('/my-work'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.task_alt, color: Colors.blue.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count job${count == 1 ? '' : 's'} awaiting your approval',
                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _pendingApprovalCountProvider =
    StreamProvider.family<int, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).workOrderDao.watchPendingApprovalCountAtSite(siteId);
});

/// Section 8 (Technician Home): "safety alerts". Shown above the other
/// exception rows - a safety issue takes precedence over cost/asset
/// concerns per Section 12's manager-priority ordering, and the same
/// logic applies to what a technician sees first.
class _SafetyAlertsRow extends ConsumerWidget {
  const _SafetyAlertsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(_safetyAlertsProvider).value ?? const [];
    if (alerts.isEmpty) return const SizedBox.shrink();

    return InkWell(
      onTap: () => context.push('/notifications'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                alerts.length == 1 ? alerts.first.body : '${alerts.length} safety alerts',
                style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _safetyAlertsProvider = StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(appDatabaseProvider).notificationDao.watchUnreadByCategory('safety');
});

/// Section 8: "critical assets" - assets that are down or flagged
/// critical at the technician's current site.
class _CriticalAssetsRow extends ConsumerWidget {
  const _CriticalAssetsRow({required this.siteId});
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(_criticalAssetsProvider(siteId)).value ?? const [];
    if (assets.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.report_outlined, size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                Text('Critical assets', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            for (final asset in assets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(asset.name),
                subtitle: Text('${asset.assetCode} · ${asset.status.replaceAll('_', ' ')}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: PriorityColors.of(asset.criticality).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    asset.criticality,
                    style: TextStyle(color: PriorityColors.of(asset.criticality), fontSize: 11),
                  ),
                ),
                onTap: () => context.push('/assets/${asset.id}'),
              ),
          ],
        ),
      ),
    );
  }
}

final _criticalAssetsProvider =
    StreamProvider.family<List<Asset>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).assetDao.watchCriticalAtSite(siteId);
});

/// Section 8: "required parts" - items at or below their reorder level
/// at the technician's current site.
class _RequiredPartsRow extends ConsumerWidget {
  const _RequiredPartsRow({required this.siteId});
  final String siteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStock = ref.watch(_lowStockProvider(siteId)).value ?? const [];
    if (lowStock.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text('Required parts', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            for (final entry in lowStock)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text('${entry.item.name} (${entry.item.sku})')),
                    Text(
                      '${entry.quantityAvailable.toStringAsFixed(0)} ${entry.item.unit} left',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final _lowStockProvider =
    StreamProvider.family<List<InventoryItemWithBalance>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).inventoryDao.watchLowStockAtSite(siteId);
});

final _unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.notificationDao.watchUnreadCount();
});

final _siteNameProvider = FutureProvider.family<Site?, String>((ref, siteId) {
  final db = ref.watch(appDatabaseProvider);
  return db.locationDao.siteById(siteId);
});

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
