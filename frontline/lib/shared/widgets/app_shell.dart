import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/app_strings.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/rbac/action.dart';
import '../../core/rbac/current_access_context_provider.dart';
import '../../core/rbac/policy_guard.dart';

/// Persistent shell around the flat frontline tabs (Section 14) - which
/// tabs actually render is role-driven ([PolicyGuard.visibleTabs]), not
/// a fixed five for everyone: a role with no work-order actions at all
/// has no "My Work"/"Scan" to show, matching Section 8's role-specific
/// home experiences.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _allTabDefs = {
    AppTab.home: _TabDef('/home', Icons.home_outlined, Icons.home, 'navHome'),
    AppTab.myWork: _TabDef('/my-work', Icons.assignment_outlined, Icons.assignment, 'navMyWork'),
    AppTab.scan: _TabDef('/scan', Icons.qr_code_scanner, Icons.qr_code_scanner, 'navScan'),
    AppTab.requests: _TabDef('/requests', Icons.list_alt_outlined, Icons.list_alt, 'navRequests'),
    AppTab.more: _TabDef('/more', Icons.more_horiz, Icons.more_horiz, 'navMore'),
  };

  int _indexForLocation(String location, List<String> tabPaths) {
    final index = tabPaths.indexWhere((t) => location.startsWith(t));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    // No access context means something upstream is wrong (this shell
    // only ever mounts for a logged-in user) - fail toward the minimum
    // safe nav rather than crashing.
    final visibleTabs = accessContext != null
        ? guard.visibleTabs(accessContext)
        : const [AppTab.home, AppTab.more];
    final tabPaths = [for (final tab in visibleTabs) _allTabDefs[tab]!.path];

    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location, tabPaths);
    final isOnline = ref.watch(isOnlineProvider).value ?? true;
    final pendingCount = ref.watch(_pendingOutboxCountProvider).value ?? 0;
    final language = ref.watch(appLocaleProvider).value ?? 'en';
    String t(String key) => AppStrings.of(key, language);

    // The device back button must never exit from a non-Home tab - it
    // should feel like "go home", matching the flat frontline navigation
    // model (Section 14). Only from Home does back offer to exit, and
    // only after an explicit confirmation, so a stray back-press never
    // drops a technician out of an in-progress job by accident.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (currentIndex != 0) {
          context.go(tabPaths.first);
          return;
        }
        final shouldExit = await _confirmExit(context, t);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Column(
          children: [
            if (!isOnline) _OfflineBanner(text: t('offlineBanner')),
            if (isOnline && pendingCount > 0) _SyncingBanner(pendingCount: pendingCount),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) => context.go(tabPaths[index]),
          destinations: [
            for (final tab in visibleTabs)
              NavigationDestination(
                icon: Icon(_allTabDefs[tab]!.icon),
                selectedIcon: Icon(_allTabDefs[tab]!.selectedIcon),
                label: t(_allTabDefs[tab]!.labelKey),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context, String Function(String) t) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('exitTitle')),
        content: Text(t('exitBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t('exitCancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t('exitConfirm')),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _TabDef {
  const _TabDef(this.path, this.icon, this.selectedIcon, this.labelKey);
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
}

final _pendingOutboxCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.outboxDao.watchPendingCount();
});

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade800,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _SyncingBanner extends StatelessWidget {
  const _SyncingBanner({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        'Syncing $pendingCount change${pendingCount == 1 ? '' : 's'}...',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
      ),
    );
  }
}
