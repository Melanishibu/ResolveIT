import 'package:go_router/go_router.dart';
import 'package:resolveit/features/auth/presentation/view/login_view.dart';
import 'package:resolveit/features/auth/presentation/view/set_password_view.dart';

/// The auth routes outside the app shell: the login page and the set-password page (RIT-US-07).
List<RouteBase> authRoutes() => [
  GoRoute(
    path: LoginView.path,
    pageBuilder: (context, state) => const NoTransitionPage(child: LoginView()),
  ),
  GoRoute(
    path: SetPasswordView.path,
    pageBuilder: (context, state) => NoTransitionPage(
      child: SetPasswordView(token: state.uri.queryParameters['token'] ?? ''),
    ),
  ),
];

/// Pages anyone may open without a session.
const publicAuthPaths = {LoginView.path, SetPasswordView.path};
