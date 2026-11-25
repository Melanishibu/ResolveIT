import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/domain/entity/user_profile.dart';

/// Contract: read the current user's profile (`GET /users/me`, RIT-US-27).
abstract interface class UserProfileRepository {
  Future<Result<UserProfile>> getMyProfile();
}
