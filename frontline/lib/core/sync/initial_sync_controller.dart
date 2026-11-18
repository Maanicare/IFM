import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/assets/data/asset_repository_provider.dart';
import '../../features/checklists/data/checklist_repository_provider.dart';
import '../../features/fleet/data/fleet_repository_provider.dart';
import '../../features/identity/presentation/auth_controller.dart';
import '../../features/inventory/data/inventory_repository_provider.dart';
import '../../features/location/data/location_repository_provider.dart';
import '../../features/requests/data/request_repository_provider.dart';
import '../../features/shift_handover/data/shift_handover_repository_provider.dart';
import '../../features/shift_roster/data/shift_roster_repository_provider.dart';
import '../../features/work_orders/data/work_order_repository_provider.dart';
import '../config/app_config.dart';
import '../db/app_database.dart';
import '../logging/app_logger.dart';

part 'initial_sync_controller.g.dart';

/// Pulls down everything the frontline app needs to work offline the
/// instant a session is established: location hierarchy, assets,
/// checklist templates, assigned work orders and open requests for the
/// user's primary site. Runs once per login; the [SyncAutoRunner] and
/// pull-to-refresh actions keep things fresh after that.
@Riverpod(keepAlive: true)
class InitialSyncController extends _$InitialSyncController {
  static const _tag = 'InitialSync';

  @override
  void build() {
    ref.listen(authControllerProvider, (previous, next) {
      final user = next.value;
      final wasLoggedOut = previous?.value == null;
      if (user != null && wasLoggedOut) {
        _runFor(user.id, user.organisationId, user.siteIds.firstOrNull);
      }
    });
  }

  Future<void> _runFor(String userId, String organisationId, String? siteId) async {
    try {
      await ref
          .read(locationRepositoryProvider)
          .syncHierarchyForOrganisation(organisationId);

      // Keyed by driver, not site - a driver's assigned vehicle isn't a
      // site-scoped resource the way assets/requests are. Harmless no-op
      // for any user with no vehicle assigned.
      await ref.read(fleetRepositoryProvider).syncAssignedVehicle(userId);

      if (siteId != null) {
        await Future.wait([
          ref.read(assetRepositoryProvider).syncAssetsForSite(siteId),
          ref.read(checklistRepositoryProvider).syncTemplates(),
          ref.read(requestRepositoryProvider).syncRequestsForSite(siteId),
          ref
              .read(workOrderRepositoryProvider)
              .syncAssignedWorkOrders(userId: userId, siteId: siteId),
          ref.read(inventoryRepositoryProvider).syncCatalogueForSite(siteId),
          ref.read(shiftHandoverRepositoryProvider).syncLatestForSite(siteId),
          ref.read(shiftRosterRepositoryProvider).syncForSite(siteId),
        ]);
      }
      if (AppConfig.useMock) {
        await _seedMockNotifications(userId);
      }
      AppLogger.instance.info(_tag, 'Initial sync complete for $userId');
    } catch (e, st) {
      AppLogger.instance.error(_tag, 'Initial sync failed', error: e, stackTrace: st);
    }
  }

  /// Mock mode has no backend to push real notifications from, so a couple
  /// of representative ones are seeded locally - matching the demo work
  /// order fixtures - purely so the Notifications screen has something to
  /// show while testing. Upserted by id, so re-login doesn't duplicate them.
  Future<void> _seedMockNotifications(String userId) async {
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    await db.notificationDao.add(AppNotificationsCompanion.insert(
      id: 'seed-sla-breach-wo-1001',
      title: 'SLA breached',
      body: 'WO-2026-1001 (Pump P-104) breached its resolution SLA.',
      category: 'sla_breach',
      relatedEntityType: const Value('work_order'),
      relatedEntityId: const Value('wo-1001'),
      createdAt: now.subtract(const Duration(minutes: 5)),
    ));
    await db.notificationDao.add(AppNotificationsCompanion.insert(
      id: 'seed-sync-conflict-wo-1003',
      title: 'Sync conflict',
      body: 'WO-2026-1003 was already verified by a supervisor before your update could sync.',
      category: 'sync_conflict',
      relatedEntityType: const Value('work_order'),
      relatedEntityId: const Value('wo-1003'),
      createdAt: now.subtract(const Duration(hours: 2)),
    ));
    await db.notificationDao.add(AppNotificationsCompanion.insert(
      id: 'seed-safety-wet-floor',
      title: 'Safety alert',
      body: 'Wet floor hazard reported near Floor 8 pantry - cordoned off, awaiting mop-up.',
      category: 'safety',
      relatedEntityType: const Value('space'),
      relatedEntityId: const Value('spc-01'),
      createdAt: now.subtract(const Duration(minutes: 30)),
    ));
    await db.notificationDao.add(AppNotificationsCompanion.insert(
      id: 'seed-assignment-wo-1002',
      title: 'New job assigned',
      body: 'WO-2026-1002 — Quarterly PM for AHU-04 — has been assigned to you.',
      category: 'assignment',
      relatedEntityType: const Value('work_order'),
      relatedEntityId: const Value('wo-1002'),
      createdAt: now.subtract(const Duration(days: 1)),
    ));
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
