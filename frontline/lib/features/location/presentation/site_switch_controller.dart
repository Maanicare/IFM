import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/logging/app_logger.dart';
import '../../assets/data/asset_repository_provider.dart';
import '../../identity/presentation/auth_controller.dart';
import '../../inventory/data/inventory_repository_provider.dart';
import '../../requests/data/request_repository_provider.dart';
import '../../shift_handover/data/shift_handover_repository_provider.dart';
import '../../shift_roster/data/shift_roster_repository_provider.dart';
import '../../work_orders/data/work_order_repository_provider.dart';

part 'site_switch_controller.g.dart';

/// Switching the active site (Screen 02: "Switch site") isn't just a UI
/// preference - everything the offline cache holds (assets, requests,
/// work orders, parts) was pulled for one site at [InitialSyncController]
/// time. Switching must re-pull for the newly-selected site so the rest
/// of the app (Create Request, My Work, Parts Used) is working against
/// the right data, not stale/missing data from the previous site.
@riverpod
class SiteSwitchController extends _$SiteSwitchController {
  static const _tag = 'SiteSwitch';

  @override
  void build() {}

  Future<void> switchTo(String siteId) async {
    final db = ref.read(appDatabaseProvider);
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    await db.identityDao.setCurrentSite(user.id, siteId);

    try {
      await Future.wait([
        ref.read(assetRepositoryProvider).syncAssetsForSite(siteId),
        ref.read(requestRepositoryProvider).syncRequestsForSite(siteId),
        ref
            .read(workOrderRepositoryProvider)
            .syncAssignedWorkOrders(userId: user.id, siteId: siteId),
        ref.read(inventoryRepositoryProvider).syncCatalogueForSite(siteId),
        ref.read(shiftHandoverRepositoryProvider).syncLatestForSite(siteId),
        ref.read(shiftRosterRepositoryProvider).syncForSite(siteId),
      ]);
      AppLogger.instance.info(_tag, 'Switched to site $siteId');
    } catch (e, st) {
      AppLogger.instance.error(_tag, 'Site switch sync failed', error: e, stackTrace: st);
    }
  }
}
