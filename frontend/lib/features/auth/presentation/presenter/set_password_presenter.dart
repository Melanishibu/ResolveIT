import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/entity/new_password.dart';
import 'package:resolveit/features/auth/providers.dart';

/// State of the set-password screen (RIT-US-07).
final class SetPasswordState {
  const SetPasswordState({
    this.problems = const {},
    this.isSubmitting = false,
    this.failure,
    this.done = false,
  });

  final Set<NewPasswordProblem> problems;
  final bool isSubmitting;

  /// The backend refused (shown through the structured error panel).
  final ApiFailure? failure;

  /// The password was set: the screen confirms and goes to the login page.
  final bool done;
}

final setPasswordPresenterProvider =
    NotifierProvider.autoDispose<SetPasswordPresenter, SetPasswordState>(
      SetPasswordPresenter.new,
    );

class SetPasswordPresenter extends Notifier<SetPasswordState> {
  @override
  SetPasswordState build() => const SetPasswordState();

  Future<void> submit(NewPassword input) async {
    final problems = input.problems;
    if (problems.isNotEmpty) {
      state = SetPasswordState(problems: problems);
      return;
    }
    state = const SetPasswordState(isSubmitting: true);
    final result = await ref
        .read(passwordInteractorProvider)
        .setPassword(input);
    if (!ref.mounted) return;
    state = switch (result) {
      Success() => const SetPasswordState(done: true),
      Failure(:final failure) => SetPasswordState(failure: failure),
    };
  }

  /// The user typed into a field: the form's messages go away until the next submit.
  void edited() {
    if (state.problems.isEmpty) return;
    state = SetPasswordState(failure: state.failure);
  }
}
