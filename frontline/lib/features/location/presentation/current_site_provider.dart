import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../identity/presentation/auth_controller.dart';

part 'current_site_provider.g.dart';

/// The site a multi-site user is currently operating against (Screen 02:
/// Role/Site Selector). Falls back to the first assigned site until the
/// technician has explicitly switched at least once, so every other
/// screen that needs "my site right now" (Create Request, My Work) has a
/// single source of truth rather than each re-deriving `siteIds.first`.
@riverpod
Stream<String?> currentSiteId(Ref ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return const Stream.empty();

  final db = ref.watch(appDatabaseProvider);
  return db.identityDao.watchCurrentUser().map((cached) {
    final selected = cached?.currentSiteId;
    if (selected != null && user.siteIds.contains(selected)) return selected;
    return user.siteIds.isNotEmpty ? user.siteIds.first : null;
  });
}
