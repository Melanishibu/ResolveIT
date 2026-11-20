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
import 'package:resolveit/features/identity/identity.dart';
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
/// - signed out → `/login` (dev routes stay reachable in debug builds);
/// - signed in on `/login` → the dashboard;
/// - signed in on a page that isn't in the role's menu → the "not allowed" page;
/// - still loading or backend unreachable → stay (the shell shows loading or the error panel).
/// The backend enforces every rule; the router only keeps users on pages their role may use.
String? sessionRedirect(AsyncValue<CurrentUser?> session, String path) {
  if (session.isLoading || !session.hasValue) return null;
  final user = session.value;
  if (user == null) {
    if (path != LoginView.path && !path.startsWith('/dev/')) {
      return LoginView.path;
    }
    return null;
  }
  if (path == LoginView.path) return MenuDestination.dashboard.path;
  final destination = MenuDestination.forLocation(path);
  if (destination != null && !menuFor(user.role).contains(destination)) {
    return NotAllowedView.path;
  }
  return null;
}

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
    GoRoute(
      path: LoginView.path,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginView()),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShellView(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: NotAllowedView.path,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NotAllowedView()),
        ),
        for (final destination in MenuDestination.values)
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
