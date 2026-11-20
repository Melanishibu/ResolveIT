import 'package:go_router/go_router.dart';
import 'package:resolveit/features/auth/presentation/view/login_view.dart';

/// The auth routes outside the app shell: the login page.
List<RouteBase> authRoutes() => [
  GoRoute(
    path: LoginView.path,
    pageBuilder: (context, state) => const NoTransitionPage(child: LoginView()),
  ),
];
