import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/domain/entity/user_summary.dart';
import 'package:resolveit/features/users/domain/repository/user_directory_repository.dart';

/// Use case: load one page of the user list.
final class ListUsers {
  const ListUsers(this._repository);

  final UserDirectoryRepository _repository;

  Future<Result<UserPage>> call(UserListFilter filter) =>
      _repository.listUsers(filter);
}

/// Use case: activate or deactivate a user (the backend refuses self-deactivation).
final class ChangeUserStatus {
  const ChangeUserStatus(this._repository);

  final UserDirectoryRepository _repository;

  Future<Result<UserSummary>> call(String userId, {required bool active}) =>
      _repository.setActive(userId, active: active);
}

/// Use case: resend invitation email (RIT-US-22).
final class ResendInvitation {
  const ResendInvitation(this._repository);

  final UserDirectoryRepository _repository;

  Future<Result<UserSummary>> call(String userId) =>
      _repository.resendInvitation(userId);
}
