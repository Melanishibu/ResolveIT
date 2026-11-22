import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/presentation/presenter/profile_state.dart';
import 'package:resolveit/features/users/providers.dart';

final profilePresenterProvider =
    NotifierProvider.autoDispose<ProfilePresenter, ProfileState>(
      ProfilePresenter.new,
    );

/// Presenter for the profile screen (RIT-US-27).
class ProfilePresenter extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    Future.microtask(load);
    return const ProfileState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await ref.read(profileInteractorProvider).loadProfile();
    if (!ref.mounted) return;
    state = switch (result) {
      Success(value: final profile) => state.copyWith(
        profile: profile,
        isLoading: false,
        clearFailure: true,
      ),
      Failure(failure: final failure) => state.copyWith(
        isLoading: false,
        failure: failure,
      ),
    };
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isSubmittingPassword: true,
      clearPasswordFailure: true,
      passwordSuccess: false,
    );
    final result = await ref.read(profileInteractorProvider).changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (!ref.mounted) return false;
    return switch (result) {
      Success() => () {
        state = state.copyWith(
          isSubmittingPassword: false,
          clearPasswordFailure: true,
          passwordSuccess: true,
        );
        return true;
      }(),
      Failure(failure: final failure) => () {
        state = state.copyWith(
          isSubmittingPassword: false,
          passwordFailure: failure,
          passwordSuccess: false,
        );
        return false;
      }(),
    };
  }
}
