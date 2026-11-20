import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/assets/presentation/asset_profile_screen.dart';
import '../../features/cleaning/presentation/cleaning_task_detail_screen.dart';
import '../../features/cleaning/presentation/cleaning_tasks_screen.dart';
import '../../features/fleet/presentation/my_vehicle_screen.dart';
import '../../features/identity/presentation/auth_controller.dart';
import '../../features/inspections/presentation/create_inspection_screen.dart';
import '../../features/inspections/presentation/inspections_screen.dart';
import '../../features/inventory/presentation/inventory_item_screen.dart';
import '../../features/washrooms/presentation/washroom_detail_screen.dart';
import '../../features/washrooms/presentation/washrooms_screen.dart';
import '../../features/identity/presentation/login_screen.dart';
import '../../features/location/presentation/site_selector_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/shift_handover/presentation/create_shift_handover_screen.dart';
import '../../features/shift_handover/presentation/shift_handover_screen.dart';
import '../../features/shift_roster/presentation/shift_roster_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/permits/presentation/create_permit_screen.dart';
import '../../features/permits/presentation/permit_detail_screen.dart';
import '../../features/permits/presentation/permits_screen.dart';
import '../../features/requests/presentation/create_request_screen.dart';
import '../../features/reservations/presentation/reservation_screen.dart';
import '../../features/reservations/presentation/space_reservation_detail_screen.dart';
import '../../features/requests/presentation/request_detail_screen.dart';
import '../../features/requests/presentation/requests_screen.dart';
import '../../features/safety/presentation/report_safety_issue_screen.dart';
import '../../features/safety/presentation/safety_home_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/work_orders/presentation/my_work_screen.dart';
import '../../features/work_orders/presentation/work_order_detail_screen.dart';
import '../../features/workplace/presentation/workplace_experience_screen.dart';
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
        path: '/safety-home',
        builder: (context, state) => const SafetyHomeScreen(),
      ),
      GoRoute(
        path: '/reservations',
        builder: (context, state) => const ReservationScreen(),
      ),
      GoRoute(
        path: '/reservations/:spaceId',
        builder: (context, state) => SpaceReservationDetailScreen(
          spaceId: state.pathParameters['spaceId']!,
        ),
      ),
      GoRoute(
        path: '/workplace',
        builder: (context, state) => const WorkplaceExperienceScreen(),
      ),
      GoRoute(
        path: '/permits',
        builder: (context, state) => const PermitsScreen(),
      ),
      GoRoute(
        path: '/permits/new',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreatePermitScreen(
            siteId: extra?['siteId'] as String,
            workOrderId: extra?['workOrderId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/permits/:id',
        builder: (context, state) => PermitDetailScreen(
          permitId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/my-vehicle',
        builder: (context, state) => const MyVehicleScreen(),
      ),
      GoRoute(
        path: '/inventory/:id',
        builder: (context, state) => InventoryItemScreen(
          itemId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/inspections',
        builder: (context, state) => const InspectionsScreen(),
      ),
      GoRoute(
        path: '/inspections/new',
        builder: (context, state) => const CreateInspectionScreen(),
      ),
      GoRoute(
        path: '/washrooms',
        builder: (context, state) => const WashroomsScreen(),
      ),
      GoRoute(
        path: '/washrooms/:id',
        builder: (context, state) => WashroomDetailScreen(
          washroomId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/cleaning-tasks',
        builder: (context, state) => const CleaningTasksScreen(),
      ),
      GoRoute(
        path: '/cleaning-tasks/:id',
        builder: (context, state) => CleaningTaskDetailScreen(
          cleaningTaskId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
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
