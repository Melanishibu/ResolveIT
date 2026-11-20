import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/domain/new_user.dart';

/// Outbound port: user management for Admins (`POST /users`, RIT-US-06).
abstract interface class UserAdminGateway {
  Future<Result<CreatedUser>> createUser(NewUser user);
}
