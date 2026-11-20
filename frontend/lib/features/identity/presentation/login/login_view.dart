import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/identity/domain/login_credentials.dart';
import 'package:resolveit/features/identity/presentation/login/login_presenter.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The login screen (`/login`, RIT-US-04): email, password with show/hide, Log in.
///
/// Built only from the shared UI components (US-28). Refusals are shown through [ErrorPanel],
/// which never says whether the email or the password was wrong (the backend message doesn't).
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  static const path = '/login';

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() => ref
      .read(loginPresenterProvider.notifier)
      .submit(LoginCredentials(email: _email.text, password: _password.text));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginPresenterProvider);
    final presenter = ref.read(loginPresenterProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final failure = state.failure;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: spacing.dialogMaxWidth),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.loginTitle,
                    key: const Key('login-title'),
                    style: context.textTheme.headlineSmall,
                  ),
                  SizedBox(height: spacing.s),
                  Text(
                    l10n.loginSubtitle,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: spacing.xl),
                  if (failure != null) ...[
                    ErrorPanel(key: const Key('login-error'), failure: failure),
                    SizedBox(height: spacing.l),
                  ],
                  AppTextField(
                    key: const Key('login-email'),
                    label: l10n.loginEmailLabel,
                    isRequired: true,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    errorText: state.missingFields.contains(LoginField.email)
                        ? l10n.loginEmailRequired
                        : null,
                    onChanged: (_) => presenter.fieldChanged(LoginField.email),
                  ),
                  SizedBox(height: spacing.m),
                  AppTextField(
                    key: const Key('login-password'),
                    label: l10n.loginPasswordLabel,
                    isRequired: true,
                    isPassword: true,
                    controller: _password,
                    errorText: state.missingFields.contains(LoginField.password)
                        ? l10n.loginPasswordRequired
                        : null,
                    onChanged: (_) =>
                        presenter.fieldChanged(LoginField.password),
                  ),
                  SizedBox(height: spacing.xl),
                  AppButton(
                    key: const Key('login-submit'),
                    label: l10n.loginButton,
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
