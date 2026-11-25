import 'package:go_router/go_router.dart';
import 'package:resolveit/features/dashboard/presentation/view/dashboard_view.dart';

/// The dashboard route inside the app shell (RIT-US-21); every signed-in role has it.
List<RouteBase> dashboardRoutes() => [
  GoRoute(
    path: DashboardView.path,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: DashboardView()),
  ),
];
