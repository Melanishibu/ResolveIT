import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/dev/component_gallery_view.dart';
import 'package:resolveit/app/shell/app_shell_view.dart';
import 'package:resolveit/app/shell/navigation_menu.dart';
import 'package:resolveit/app/shell/not_allowed_view.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/dashboard/dashboard.dart';
import 'package:resolveit/features/incident/incident.dart';
import 'package:resolveit/features/users/users.dart';
import 'package:resolveit/l10n/app_localizations.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // The router re-checks its redirect whenever the session changes (login, logout).
  final session = ValueNotifier<AsyncValue<CurrentUser?>>(const AsyncLoading());
  ref.listen(
    sessionProvider,
    (_, next) => session.value = next,
    fireImmediately: true,
  );
  // `kDebugMode` is a compile-time constant: in release builds the dev routes, and with them
  // the component gallery, are not compiled into the app at all (US-28, AB#170).
  final router = buildAppRouter(
    devRoutes: kDebugMode ? devComponentRoutes() : const [],
    session: session,
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});

/// Debug-only routes: the component gallery at [ComponentGalleryView.path].
List<RouteBase> devComponentRoutes() => [
  GoRoute(
    path: ComponentGalleryView.path,
    builder: (context, state) => const ComponentGalleryView(),
  ),
];

/// Where the session state sends the user (AB#13, AB#14):
/// - signed out → `/login` (the public auth pages and, in debug builds, the dev routes stay reachable);
/// - signed in on `/login` → the dashboard;
/// - signed in on a page the role may not open → the "not allowed" page. [mayOpen] decides, from the
///   permission table, not from the menu: the Admin may open Create Incident without a menu entry
///   (bug AB#181);
/// - still loading or backend unreachable → stay (the shell shows loading or the error panel).
/// The backend enforces every rule; the router only keeps users on pages their role may use.
final _incidentDetailsPath = RegExp(r'^/incidents/[^/]+$');

String? sessionRedirect(AsyncValue<CurrentUser?> session, String path) {
  if (session.isLoading || !session.hasValue) return null;
  final user = session.value;
  if (user == null) {
    if (!publicAuthPaths.contains(path) && !path.startsWith('/dev/')) {
      return LoginView.path;
    }
    return null;
  }
  if (path == LoginView.path) return MenuDestination.dashboard.path;
  // One incident: every signed-in role may try; the backend answers 403 or 404 (AB#38).
  if (_incidentDetailsPath.hasMatch(path) && path != '/incidents/new') {
    return null;
  }
  final destination = MenuDestination.forLocation(path);
  if (destination != null && !mayOpen(user.role, destination)) {
    return NotAllowedView.path;
  }
  return null;
}

/// The feature screens inside the shell (each feature's `presentation/router`).
List<RouteBase> get _shellFeatureRoutes => [
  ...usersRoutes(),
  ...incidentRoutes(),
  ...dashboardRoutes(),
];

/// Paths served by a feature screen; their menu destinations get no placeholder page.
Set<String> get _shellFeaturePaths => {
  for (final route in _shellFeatureRoutes)
    if (route is GoRoute) route.path,
};

/// Every menu destination is a placeholder page inside the shell until its story arrives.
/// [devRoutes] are added only by the debug composition root (see [appRouterProvider]).
/// Without [session] (tests of routing alone) no session redirect applies.
GoRouter buildAppRouter({
  String initialLocation = '/dashboard',
  List<RouteBase> devRoutes = const [],
  ValueListenable<AsyncValue<CurrentUser?>>? session,
}) => GoRouter(
  initialLocation: initialLocation,
  refreshListenable: session,
  redirect: (context, state) {
    final path = state.uri.path;
    if (path == '/') return MenuDestination.dashboard.path;
    return session == null ? null : sessionRedirect(session.value, path);
  },
  routes: [
    ...authRoutes(),
    ShellRoute(
      builder: (context, state, child) =>
          AppShellView(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: NotAllowedView.path,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NotAllowedView()),
        ),
        ..._shellFeatureRoutes,
        // Destinations without a feature screen yet show a placeholder page.
        for (final destination in MenuDestination.values)
          if (!_shellFeaturePaths.contains(destination.path))
            GoRoute(
              path: destination.path,
              pageBuilder: (context, state) => NoTransitionPage(
                child: PlaceholderPage(
                  title: destination.label(AppLocalizations.of(context)),
                ),
              ),
            ),
      ],
    ),
    ...devRoutes,
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: ErrorPanel(
        failure: ApiFailure(
          code: 'RESOURCE_NOT_FOUND',
          params: {'path': state.uri.path},
        ),
      ),
    ),
  ),
);
