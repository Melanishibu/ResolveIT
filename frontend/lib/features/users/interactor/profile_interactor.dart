import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/users/domain/entity/user_profile.dart';
import 'package:resolveit/features/users/domain/usecase/get_my_profile.dart';

/// Interactor for the profile flow (RIT-US-27): coordinates loading profile and changing password.
final class ProfileInteractor {
  const ProfileInteractor(this._getMyProfile, this._changePassword);

  final GetMyProfileUseCase _getMyProfile;
  final ChangePasswordUseCase _changePassword;

  Future<Result<UserProfile>> loadProfile() => _getMyProfile();

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
}
