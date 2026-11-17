import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/app_database.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/app_strings.dart';
import '../../core/network/connectivity_service.dart';

/// Persistent shell around the five flat frontline tabs (Section 14),
/// plus a thin offline banner that appears the instant connectivity
/// drops - frontline staff should never wonder whether their taps are
/// being recorded.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = ['/home', '/my-work', '/scan', '/requests', '/more'];

  int _indexForLocation(String location) {
    final index = _tabs.indexWhere((t) => location.startsWith(t));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForLocation(location);
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
          context.go('/home');
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
          onDestinationSelected: (index) => context.go(_tabs[index]),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t('navHome')),
            NavigationDestination(icon: const Icon(Icons.assignment_outlined), selectedIcon: const Icon(Icons.assignment), label: t('navMyWork')),
            NavigationDestination(icon: const Icon(Icons.qr_code_scanner), label: t('navScan')),
            NavigationDestination(icon: const Icon(Icons.list_alt_outlined), selectedIcon: const Icon(Icons.list_alt), label: t('navRequests')),
            NavigationDestination(icon: const Icon(Icons.more_horiz), label: t('navMore')),
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
