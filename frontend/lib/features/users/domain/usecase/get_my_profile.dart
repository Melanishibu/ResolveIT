import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/domain/entity/user_profile.dart';
import 'package:resolveit/features/users/domain/repository/user_profile_repository.dart';

/// Loads the current user's profile (RIT-US-27).
final class GetMyProfileUseCase {
  const GetMyProfileUseCase(this._repository);

  final UserProfileRepository _repository;

  Future<Result<UserProfile>> call() => _repository.getMyProfile();
}
