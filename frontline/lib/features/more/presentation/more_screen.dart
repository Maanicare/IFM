import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/biometrics/biometric_auth_service.dart';
import '../../../core/biometrics/biometric_preference.dart';
import '../../../core/db/app_database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/sync/sync_engine.dart';
import '../../identity/presentation/auth_controller.dart';
import '../../location/presentation/current_site_provider.dart';

/// SCREEN 54-adjacent "More" tab: profile, sync status/conflicts, and the
/// diagnostics export hook (Section: NDJSON logger) - everything that
/// doesn't deserve its own bottom-nav slot in the flat frontline
/// navigation (Section 14).
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final pendingCount = ref.watch(_pendingProvider).value ?? 0;
    final conflictCount = ref.watch(_conflictProvider).value ?? 0;
    final currentSiteId = ref.watch(currentSiteIdProvider).value;
    final currentSite = currentSiteId == null
        ? null
        : ref.watch(_siteProvider(currentSiteId)).value;
    final biometricPref = ref.watch(biometricPreferenceProvider).value;
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    bool can(AppAction action) => accessContext != null && guard.can(accessContext, action);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.name ?? ''),
            subtitle: Text('${user?.designation ?? ''} · ${user?.role.name ?? ''}'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.apartment_outlined),
            title: Text(currentSite?.name ?? 'No site selected'),
            subtitle: const Text('Current site'),
            trailing: (user?.siteIds.length ?? 0) > 1
                ? TextButton(
                    onPressed: () => context.push('/site-selector'),
                    child: const Text('Change'),
                  )
                : null,
          ),
          if (can(AppAction.manageShiftHandover)) ...[
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Shift handover'),
              subtitle: const Text('Outgoing briefing / incoming acknowledgement'),
              onTap: () => context.push('/shift-handover'),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Shift roster'),
              subtitle: const Text("Today's schedule, attendance"),
              onTap: () => context.push('/shift-roster'),
            ),
          ],
          if (can(AppAction.reportIncident))
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report safety issue'),
              subtitle: const Text('Incident, hazard or near miss'),
              onTap: () => context.push('/report-safety-issue'),
            ),
          if (can(AppAction.manageCleaningTask)) ...[
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Cleaning tasks'),
              subtitle: const Text('Assigned areas, inspection checklist'),
              onTap: () => context.push('/cleaning-tasks'),
            ),
            ListTile(
              leading: const Icon(Icons.wc_outlined),
              title: const Text('Washrooms'),
              subtitle: const Text('Cleaning status, consumables, complaints'),
              onTap: () => context.push('/washrooms'),
            ),
          ],
          if (can(AppAction.manageFleetTrip))
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('My vehicle'),
              subtitle: const Text('Vehicle details, start/end trip'),
              onTap: () => context.push('/my-vehicle'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync now'),
            subtitle: Text('$pendingCount change${pendingCount == 1 ? '' : 's'} pending'),
            trailing: FilledButton(
              onPressed: () => ref.read(syncEngineProvider).drainQueue(),
              child: const Text('Sync'),
            ),
          ),
          if (conflictCount > 0)
            ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              title: Text('$conflictCount sync issue${conflictCount == 1 ? '' : 's'}'),
              subtitle: const Text('Some changes need your review before they can sync.'),
            ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric login'),
            subtitle: Text(
              biometricPref?.enabled == true
                  ? 'Enabled - you can log in without a password next time'
                  : 'Use fingerprint/face unlock instead of password',
            ),
            value: biometricPref?.enabled ?? false,
            onChanged: (enable) => _toggleBiometric(context, ref, enable, user?.email),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Send diagnostics'),
            subtitle: const Text('Share app logs with support'),
            onTap: () => AppLogger.instance.shareDiagnostics(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out'),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

/// Enabling biometric login (Screen 01) confirms the device actually
/// supports it with one real prompt before saving the preference -
/// otherwise the toggle would silently promise something unusable on
/// the next login attempt.
Future<void> _toggleBiometric(
  BuildContext context,
  WidgetRef ref,
  bool enable,
  String? identifier,
) async {
  if (!enable) {
    await ref.read(biometricPreferenceProvider.notifier).disable();
    return;
  }
  if (identifier == null) return;

  final supported = await BiometricAuthService.isDeviceSupported();
  if (!supported) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This device does not support biometric authentication.')),
      );
    }
    return;
  }
  final confirmed = await BiometricAuthService.authenticate(
    reason: 'Confirm it\'s you to enable biometric login',
  );
  if (confirmed) {
    await ref.read(biometricPreferenceProvider.notifier).enable(identifier);
  }
}

final _pendingProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).outboxDao.watchPendingCount();
});

final _conflictProvider = FutureProvider<int>((ref) async {
  final conflicts = await ref.watch(appDatabaseProvider).outboxDao.conflicts();
  return conflicts.length;
});

final _siteProvider = FutureProvider.family<Site?, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).locationDao.siteById(siteId);
});
