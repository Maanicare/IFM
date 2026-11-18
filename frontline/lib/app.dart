import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/sync/initial_sync_controller.dart';
import 'core/sync/sync_engine.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Activates the two "always on" background controllers
/// ([InitialSyncController] and [SyncAutoRunner]) by watching them here,
/// so they start listening the moment the app boots rather than only
/// when some screen happens to reference them.
class OneMaanicareFrontlineApp extends ConsumerWidget {
  const OneMaanicareFrontlineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(initialSyncControllerProvider);
    ref.watch(syncAutoRunnerProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'OneMaanicare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
