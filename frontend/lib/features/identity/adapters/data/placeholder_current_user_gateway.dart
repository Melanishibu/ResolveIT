import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/application/ports/current_user_gateway.dart';
import 'package:resolveit/features/identity/domain/current_user.dart';
import 'package:resolveit/features/identity/domain/role.dart';

/// Placeholder until US-04 (AB#13) adds `GET /auth/me`.
///
/// It only selects which menu the shell shows; it grants no access. Remove it, together with
/// `DEV_ROLE`, once the real gateway exists.
final class PlaceholderCurrentUserGateway implements CurrentUserGateway {
  const PlaceholderCurrentUserGateway(this._role);

  final Role _role;

  @override
  Future<Result<CurrentUser>> currentUser() async => Success(
    CurrentUser(id: 'dev-user', displayName: 'Dev User', role: _role),
  );
}
