import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/features/identity/adapters/data/placeholder_current_user_gateway.dart';
import 'package:resolveit/features/identity/application/interactors/load_current_user.dart';
import 'package:resolveit/features/identity/application/ports/current_user_gateway.dart';
import 'package:resolveit/features/identity/domain/role.dart';

/// Dev-only role for the menu placeholder: `--dart-define=DEV_ROLE=ADMIN|SUPPORT_AGENT|EMPLOYEE`.
/// Unknown values fall back to ADMIN. Removed in US-04 (AB#13).
const _devRoleCode = String.fromEnvironment('DEV_ROLE', defaultValue: 'ADMIN');

final currentUserGatewayProvider = Provider<CurrentUserGateway>(
  (ref) =>
      PlaceholderCurrentUserGateway(Role.tryParse(_devRoleCode) ?? Role.admin),
);

final loadCurrentUserProvider = Provider<LoadCurrentUser>(
  (ref) => LoadCurrentUser(ref.watch(currentUserGatewayProvider)),
);
