import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/features/identity/adapters/data/api_identity_gateway.dart';
import 'package:resolveit/features/identity/adapters/data/api_user_admin_gateway.dart';
import 'package:resolveit/features/identity/application/interactors/create_user.dart';
import 'package:resolveit/features/identity/application/ports/user_admin_gateway.dart';
import 'package:resolveit/features/identity/application/interactors/load_current_user.dart';
import 'package:resolveit/features/identity/application/interactors/log_in.dart';
import 'package:resolveit/features/identity/application/interactors/log_out.dart';
import 'package:resolveit/features/identity/application/ports/current_user_gateway.dart';
import 'package:resolveit/features/identity/application/ports/session_gateway.dart';

/// The HTTP client of the identity API. The composition root (`lib/app/app.dart`) binds it to the
/// shared API client; features never import the composition root.
final identityHttpClientProvider = Provider<Dio>(
  (ref) => throw StateError(
    'identityHttpClientProvider is bound by the composition root (ResolveItApp)',
  ),
);

/// One API adapter serves both identity ports (AB#13).
final apiIdentityGatewayProvider = Provider<ApiIdentityGateway>(
  (ref) => ApiIdentityGateway(ref.watch(identityHttpClientProvider)),
);

/// Who is signed in (`GET /auth/me`). Tests override it with a fake.
final currentUserGatewayProvider = Provider<CurrentUserGateway>(
  (ref) => ref.watch(apiIdentityGatewayProvider),
);

/// Log in and log out. Tests override it with a fake.
final sessionGatewayProvider = Provider<SessionGateway>(
  (ref) => ref.watch(apiIdentityGatewayProvider),
);

final loadCurrentUserProvider = Provider<LoadCurrentUser>(
  (ref) => LoadCurrentUser(ref.watch(currentUserGatewayProvider)),
);

final logInProvider = Provider<LogIn>(
  (ref) => LogIn(ref.watch(sessionGatewayProvider)),
);

final logOutProvider = Provider<LogOut>(
  (ref) => LogOut(ref.watch(sessionGatewayProvider)),
);

/// User management for Admins (RIT-US-06). Tests override it with a fake.
final userAdminGatewayProvider = Provider<UserAdminGateway>(
  (ref) => ApiUserAdminGateway(ref.watch(identityHttpClientProvider)),
);

final createUserProvider = Provider<CreateUser>(
  (ref) => CreateUser(ref.watch(userAdminGatewayProvider)),
);
