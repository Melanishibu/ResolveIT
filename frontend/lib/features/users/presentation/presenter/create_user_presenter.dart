import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/providers.dart';
import 'package:resolveit/features/users/domain/entity/new_user.dart';

/// State of the create-user screen (RIT-US-06).
final class CreateUserState {
  const CreateUserState({
    this.missingFields = const {},
    this.isSubmitting = false,
    this.failure,
    this.created,
  });

  final Set<NewUserField> missingFields;
  final bool isSubmitting;

  /// The backend refused (shown through the structured error panel).
  final ApiFailure? failure;

  /// Set once the user was created: the screen confirms and goes back to the list.
  final CreatedUser? created;
}

final createUserPresenterProvider =
    NotifierProvider.autoDispose<CreateUserPresenter, CreateUserState>(
      CreateUserPresenter.new,
    );

class CreateUserPresenter extends Notifier<CreateUserState> {
  @override
  CreateUserState build() => const CreateUserState();

  Future<void> submit(NewUser user) async {
    final missing = user.missingFields;
    if (missing.isNotEmpty) {
      state = CreateUserState(missingFields: missing);
      return;
    }
    state = const CreateUserState(isSubmitting: true);
    final result = await ref
        .read(createUserInteractorProvider)
        .createUser(user);
    if (!ref.mounted) return;
    state = switch (result) {
      Success(:final value) => CreateUserState(created: value),
      Failure(:final failure) => CreateUserState(failure: failure),
    };
  }

  /// The Admin changed [field]: its required-field message goes away.
  void fieldChanged(NewUserField field) {
    if (!state.missingFields.contains(field)) return;
    state = CreateUserState(
      missingFields: {...state.missingFields}..remove(field),
      failure: state.failure,
    );
  }
}
