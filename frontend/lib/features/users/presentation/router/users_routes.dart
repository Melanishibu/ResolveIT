import 'package:go_router/go_router.dart';
import 'package:resolveit/features/users/presentation/view/create_user_view.dart';
import 'package:resolveit/features/users/presentation/view/user_list_view.dart';

/// The user-management routes inside the app shell. Admin only: the role guard maps them to User
/// Management (AB#48, AB#50).
List<RouteBase> usersRoutes() => [
  GoRoute(
    path: UserListView.path,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: UserListView()),
  ),
  GoRoute(
    path: CreateUserView.path,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: CreateUserView()),
  ),
];
