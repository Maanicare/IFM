import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/assets/presentation/asset_profile_screen.dart';
import '../../features/fleet/presentation/my_vehicle_screen.dart';
import '../../features/identity/presentation/auth_controller.dart';
import '../../features/identity/presentation/login_screen.dart';
import '../../features/location/presentation/site_selector_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/shift_handover/presentation/create_shift_handover_screen.dart';
import '../../features/shift_handover/presentation/shift_handover_screen.dart';
import '../../features/shift_roster/presentation/shift_roster_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/requests/presentation/create_request_screen.dart';
import '../../features/requests/presentation/request_detail_screen.dart';
import '../../features/requests/presentation/requests_screen.dart';
import '../../features/safety/presentation/report_safety_issue_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/work_orders/presentation/my_work_screen.dart';
import '../../features/work_orders/presentation/work_order_detail_screen.dart';
import '../../shared/widgets/app_shell.dart';

part 'app_router.g.dart';

/// Frontline navigation (Section 14): a flat five-tab shell - Home, My
/// Work, Scan, Requests, More - deliberately much simpler than the
/// enterprise 19-item navigation used by management/desktop surfaces.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      if (authState.isLoading) return null;
      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/my-work', builder: (context, state) => const MyWorkScreen()),
          GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
          GoRoute(path: '/requests', builder: (context, state) => const RequestsScreen()),
          GoRoute(path: '/more', builder: (context, state) => const MoreScreen()),
        ],
      ),
      GoRoute(
        path: '/work-orders/:id',
        builder: (context, state) => WorkOrderDetailScreen(
          workOrderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/assets/:id',
        builder: (context, state) => AssetProfileScreen(
          assetId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/site-selector',
        builder: (context, state) => const SiteSelectorScreen(),
      ),
      GoRoute(
        path: '/shift-handover',
        builder: (context, state) => const ShiftHandoverScreen(),
      ),
      GoRoute(
        path: '/shift-roster',
        builder: (context, state) => const ShiftRosterScreen(),
      ),
      GoRoute(
        path: '/report-safety-issue',
        builder: (context, state) => const ReportSafetyIssueScreen(),
      ),
      GoRoute(
        path: '/my-vehicle',
        builder: (context, state) => const MyVehicleScreen(),
      ),
      GoRoute(
        path: '/shift-handover/new',
        builder: (context, state) => CreateShiftHandoverScreen(
          siteId: state.extra as String,
        ),
      ),
      GoRoute(
        path: '/requests/new',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreateRequestScreen(
            initialAssetId: extra?['assetId'] as String?,
            initialSpaceId: extra?['spaceId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/requests/:id',
        builder: (context, state) => RequestDetailScreen(
          requestId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
}

/// Bridges Riverpod's `ref.watch` (rebuild-on-change) model into the
/// `Listenable` go_router expects for `refreshListenable`, so navigation
/// reacts immediately to login/logout without polling.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}
