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
          if ((user?.siteIds.length ?? 0) > 1) const _SiteSwitcherAction(),
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

/// Only rendered for a user assigned to more than one site - shows which
/// site is currently active and opens Screen 02 to switch (Section 6:
/// e.g. a Regional Head covering several sites).
class _SiteSwitcherAction extends ConsumerWidget {
  const _SiteSwitcherAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider).value;
    final siteAsync = siteId == null
        ? null
        : ref.watch(_siteNameProvider(siteId));

    return TextButton.icon(
      onPressed: () => context.push('/site-selector'),
      icon: const Icon(Icons.apartment_outlined, size: 18),
      label: Text(
        siteAsync?.value?.name ?? 'Select site',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

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
