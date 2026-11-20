import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/dev/component_gallery_view.dart';
import 'package:resolveit/app/shell/app_shell_view.dart';
import 'package:resolveit/app/shell/navigation_menu.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/l10n/app_localizations.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // `kDebugMode` is a compile-time constant: in release builds the dev routes, and with them
  // the component gallery, are not compiled into the app at all (US-28, AB#170).
  final router = buildAppRouter(
    devRoutes: kDebugMode ? devComponentRoutes() : const [],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Debug-only routes: the component gallery at [ComponentGalleryView.path].
List<RouteBase> devComponentRoutes() => [
  GoRoute(
    path: ComponentGalleryView.path,
    builder: (context, state) => const ComponentGalleryView(),
  ),
];

/// Every menu destination is a placeholder page inside the shell until its story arrives.
/// [devRoutes] are added only by the debug composition root (see [appRouterProvider]).
GoRouter buildAppRouter({
  String initialLocation = '/dashboard',
  List<RouteBase> devRoutes = const [],
}) => GoRouter(
  initialLocation: initialLocation,
  redirect: (context, state) =>
      state.uri.path == '/' ? MenuDestination.dashboard.path : null,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShellView(location: state.uri.path, child: child),
      routes: [
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
