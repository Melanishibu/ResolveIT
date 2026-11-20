import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/application/ports/current_user_gateway.dart';
import 'package:resolveit/features/identity/domain/current_user.dart';

/// Use case: load the signed-in user (drives the role-based menu and the avatar).
final class LoadCurrentUser {
  const LoadCurrentUser(this._gateway);

  final CurrentUserGateway _gateway;

  Future<Result<CurrentUser>> call() => _gateway.currentUser();
}
