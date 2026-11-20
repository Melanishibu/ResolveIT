import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/shell/app_shell_view.dart';
import 'package:resolveit/app/shell/navigation_menu.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/errors/error_panel.dart';
import 'package:resolveit/core/presentation/widgets/placeholder_page.dart';
import 'package:resolveit/l10n/app_localizations.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

/// Every menu destination is a placeholder page inside the shell until its story arrives.
GoRouter buildAppRouter({String initialLocation = '/dashboard'}) => GoRouter(
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
