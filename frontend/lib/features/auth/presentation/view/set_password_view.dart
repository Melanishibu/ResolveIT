import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/auth/domain/entity/new_password.dart';
import 'package:resolveit/features/auth/presentation/presenter/set_password_presenter.dart';
import 'package:resolveit/features/auth/presentation/view/login_view.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Set your password from the invitation link (`/set-password?token=…`, RIT-US-07). Public: used
/// without a session. The same screen serves the password reset of RIT-US-23. No automatic login.
class SetPasswordView extends ConsumerStatefulWidget {
  const SetPasswordView({super.key, required this.token});

  static const path = '/set-password';

  /// The link's `token` query parameter; empty when the link is broken.
  final String token;

  @override
  ConsumerState<SetPasswordView> createState() => _SetPasswordViewState();
}

class _SetPasswordViewState extends ConsumerState<SetPasswordView> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() => ref
      .read(setPasswordPresenterProvider.notifier)
      .submit(
        NewPassword(
          token: widget.token,
          password: _password.text,
          confirmation: _confirmation.text,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    ref.listen(setPasswordPresenterProvider, (previous, next) {
      if (next.done && !(previous?.done ?? false)) {
        AppToast.success(context, l10n.setPasswordSuccess);
        context.go(LoginView.path);
      }
    });
    final state = ref.watch(setPasswordPresenterProvider);
    final presenter = ref.read(setPasswordPresenterProvider.notifier);
    // A link without a token can never work: say so before the user types anything.
    final failure =
        state.failure ??
        (widget.token.isEmpty ? ApiFailure(code: 'AUTH_TOKEN_INVALID') : null);
    final problems = state.problems;
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
                    l10n.setPasswordTitle,
                    key: const Key('set-password-title'),
                    style: context.textTheme.headlineSmall,
                  ),
                  SizedBox(height: spacing.s),
                  Text(
                    l10n.setPasswordSubtitle,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: spacing.l),
                  Text(
                    l10n.setPasswordPolicy,
                    key: const Key('set-password-policy'),
                    style: context.textTheme.bodyMedium,
                  ),
                  SizedBox(height: spacing.l),
                  if (failure != null) ...[
                    ErrorPanel(
                      key: const Key('set-password-error'),
                      failure: failure,
                    ),
                    SizedBox(height: spacing.l),
                  ],
                  AppTextField(
                    key: const Key('set-password-new'),
                    label: l10n.setPasswordNewLabel,
                    isRequired: true,
                    isPassword: true,
                    maxLength: 128,
                    controller: _password,
                    errorText:
                        problems.contains(NewPasswordProblem.passwordMissing)
                        ? l10n.setPasswordRequired
                        : null,
                    onChanged: (_) => presenter.edited(),
                  ),
                  SizedBox(height: spacing.m),
                  AppTextField(
                    key: const Key('set-password-confirm'),
                    label: l10n.setPasswordConfirmLabel,
                    isRequired: true,
                    isPassword: true,
                    maxLength: 128,
                    controller: _confirmation,
                    errorText: switch (problems) {
                      _ when problems.contains(NewPasswordProblem.mismatch) =>
                        l10n.setPasswordMismatch,
                      _
                          when problems.contains(
                            NewPasswordProblem.confirmationMissing,
                          ) =>
                        l10n.setPasswordConfirmRequired,
                      _ => null,
                    },
                    onChanged: (_) => presenter.edited(),
                  ),
                  SizedBox(height: spacing.xl),
                  AppButton(
                    key: const Key('set-password-submit'),
                    label: l10n.setPasswordButton,
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting || widget.token.isEmpty
                        ? null
                        : _submit,
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
