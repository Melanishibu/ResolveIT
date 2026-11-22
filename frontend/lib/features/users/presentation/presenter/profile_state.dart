import 'package:flutter/foundation.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/features/users/domain/entity/user_profile.dart';

/// State of the profile screen (RIT-US-27).
@immutable
final class ProfileState {
  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.failure,
    this.isSubmittingPassword = false,
    this.passwordFailure,
    this.passwordSuccess = false,
  });

  final UserProfile? profile;
  final bool isLoading;
  final ApiFailure? failure;
  final bool isSubmittingPassword;
  final ApiFailure? passwordFailure;
  final bool passwordSuccess;

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    ApiFailure? failure,
    bool clearFailure = false,
    bool? isSubmittingPassword,
    ApiFailure? passwordFailure,
    bool clearPasswordFailure = false,
    bool? passwordSuccess,
  }) => ProfileState(
    profile: profile ?? this.profile,
    isLoading: isLoading ?? this.isLoading,
    failure: clearFailure ? null : (failure ?? this.failure),
    isSubmittingPassword: isSubmittingPassword ?? this.isSubmittingPassword,
    passwordFailure:
        clearPasswordFailure ? null : (passwordFailure ?? this.passwordFailure),
    passwordSuccess: passwordSuccess ?? this.passwordSuccess,
  );
}
