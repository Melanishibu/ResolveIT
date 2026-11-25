import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/domain/entity/new_user.dart';

/// Outbound port: user management for Admins (`POST /users`, RIT-US-06).
abstract interface class UserAdminRepository {
  Future<Result<CreatedUser>> createUser(NewUser user);
}
