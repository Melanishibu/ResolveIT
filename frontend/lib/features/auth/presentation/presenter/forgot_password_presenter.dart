import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/providers.dart';

final class ForgotPasswordState {
  const ForgotPasswordState({
    this.isLoading = false,
    this.done = false,
    this.failure,
    this.emailRequired = false,
  });

  final bool isLoading;
  final bool done;
  final ApiFailure? failure;
  final bool emailRequired;
}

final forgotPasswordPresenterProvider =
    NotifierProvider.autoDispose<ForgotPasswordPresenter, ForgotPasswordState>(
      ForgotPasswordPresenter.new,
    );

class ForgotPasswordPresenter extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  Future<void> submit(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      state = const ForgotPasswordState(emailRequired: true);
      return;
    }
    state = const ForgotPasswordState(isLoading: true);
    final result = await ref
        .read(passwordInteractorProvider)
        .requestPasswordReset(trimmed);
    if (!ref.mounted) return;
    state = switch (result) {
      Success() => const ForgotPasswordState(done: true),
      Failure(:final failure) => ForgotPasswordState(failure: failure),
    };
  }

  void emailChanged() {
    if (state.emailRequired || state.failure != null) {
      state = const ForgotPasswordState();
    }
  }
}
