import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/domain/entity/user_summary.dart';
import 'package:resolveit/features/users/domain/usecase/manage_users.dart';

/// Coordinates the user-list screen's use cases (RIT-US-08).
final class UserListInteractor {
  const UserListInteractor(
    this._listUsers,
    this._changeStatus,
    this._resendInvitation,
  );

  final ListUsers _listUsers;
  final ChangeUserStatus _changeStatus;
  final ResendInvitation _resendInvitation;

  Future<Result<UserPage>> load(UserListFilter filter) => _listUsers(filter);

  Future<Result<UserSummary>> setActive(
    String userId, {
    required bool active,
  }) => _changeStatus(userId, active: active);

  Future<Result<UserSummary>> resendInvitation(String userId) =>
      _resendInvitation(userId);
}
