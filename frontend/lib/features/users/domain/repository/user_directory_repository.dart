import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/domain/entity/user_summary.dart';

/// Contract: the Admin's user list and activate/deactivate (`GET /users`, `PATCH /users/{id}/status`,
/// RIT-US-08).
abstract interface class UserDirectoryRepository {
  Future<Result<UserPage>> listUsers(UserListFilter filter);

  Future<Result<UserSummary>> setActive(String userId, {required bool active});
}
