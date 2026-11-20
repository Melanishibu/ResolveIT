import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/repository/current_user_repository.dart';
import 'package:resolveit/features/auth/domain/entity/current_user.dart';

/// Use case: load the signed-in user (drives the role-based menu and the avatar).
final class LoadCurrentUser {
  const LoadCurrentUser(this._repository);

  final CurrentUserRepository _repository;

  Future<Result<CurrentUser>> call() => _repository.currentUser();
}
