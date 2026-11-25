import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/providers.dart';
import 'package:resolveit/features/auth/domain/entity/login_credentials.dart';
import 'package:resolveit/features/auth/presentation/presenter/login_state.dart';
import 'package:resolveit/features/auth/presentation/presenter/session_presenter.dart';

final loginPresenterProvider =
    NotifierProvider.autoDispose<LoginPresenter, LoginState>(
      LoginPresenter.new,
    );

/// Login screen logic: required-field check, the login call, and the session update.
class LoginPresenter extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> submit(LoginCredentials credentials) async {
    final missing = credentials.missingFields;
    if (missing.isNotEmpty) {
      state = LoginState(missingFields: missing);
      return;
    }
    state = const LoginState(isSubmitting: true);
    final result = await ref.read(authInteractorProvider).logIn(credentials);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = const LoginState();
        ref.read(sessionProvider.notifier).signedIn(value);
      case Failure(:final failure):
        state = LoginState(failure: failure);
    }
  }

  /// The user typed into [field]: its required-field message goes away.
  void fieldChanged(LoginField field) {
    if (!state.missingFields.contains(field)) return;
    state = LoginState(
      missingFields: {...state.missingFields}..remove(field),
      failure: state.failure,
    );
  }
}
