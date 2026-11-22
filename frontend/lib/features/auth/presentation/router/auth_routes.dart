import 'package:go_router/go_router.dart';
import 'package:resolveit/features/auth/presentation/view/forgot_password_view.dart';
import 'package:resolveit/features/auth/presentation/view/login_view.dart';
import 'package:resolveit/features/auth/presentation/view/set_password_view.dart';

/// The auth routes outside the app shell: login, set-password, and forgot-password.
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
  GoRoute(
    path: ForgotPasswordView.path,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: ForgotPasswordView()),
  ),
];

/// Pages anyone may open without a session.
const publicAuthPaths = {
  LoginView.path,
  SetPasswordView.path,
  ForgotPasswordView.path,
};
