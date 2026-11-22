import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/auth/presentation/presenter/forgot_password_presenter.dart';
import 'package:resolveit/features/auth/presentation/view/login_view.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Request a password reset email (`/forgot-password`, RIT-US-23). Public: used without a session.
class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  static const path = '/forgot-password';

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() =>
      ref.read(forgotPasswordPresenterProvider.notifier).submit(_email.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final state = ref.watch(forgotPasswordPresenterProvider);
    final presenter = ref.read(forgotPasswordPresenterProvider.notifier);

    return Scaffold(
      backgroundColor: context.appColors.pageBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.m),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AppCard(
              key: const Key('forgot-password-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.forgotPasswordTitle,
                    key: const Key('forgot-password-title'),
                    style: context.textTheme.headlineSmall,
                  ),
                  SizedBox(height: spacing.s),
                  Text(
                    l10n.forgotPasswordSubtitle,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: spacing.xl),
                  if (state.failure != null) ...[
                    ErrorPanel(
                      key: const Key('forgot-password-error'),
                      failure: state.failure!,
                    ),
                    SizedBox(height: spacing.l),
                  ],
                  if (state.done) ...[
                    Container(
                      padding: EdgeInsets.all(spacing.m),
                      decoration: BoxDecoration(
                        color: context.appColors.success.background,
                        borderRadius: BorderRadius.circular(
                          context.radii.control,
                        ),
                        border: Border.all(color: context.appColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: context.appColors.success.foreground,
                                size: 20,
                              ),
                              SizedBox(width: spacing.s),
                              Text(
                                l10n.forgotPasswordSuccessTitle,
                                style: context.textTheme.titleMedium?.copyWith(
                                  color: context.appColors.success.foreground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing.s),
                          Text(
                            l10n.forgotPasswordSuccessMessage,
                            key: const Key('forgot-password-success-message'),
                            style: context.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: spacing.xl),
                    AppButton(
                      key: const Key('forgot-password-back-button'),
                      label: l10n.forgotPasswordBackToLogin,
                      onPressed: () => context.go(LoginView.path),
                    ),
                  ] else ...[
                    AppTextField(
                      key: const Key('forgot-password-email'),
                      label: l10n.forgotPasswordEmailLabel,
                      isRequired: true,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      errorText: state.emailRequired
                          ? l10n.forgotPasswordEmailRequired
                          : null,
                      onChanged: (_) => presenter.emailChanged(),
                    ),
                    SizedBox(height: spacing.xl),
                    AppButton(
                      key: const Key('forgot-password-submit'),
                      label: l10n.forgotPasswordButton,
                      isLoading: state.isLoading,
                      onPressed: state.isLoading ? null : _submit,
                    ),
                    SizedBox(height: spacing.m),
                    Center(
                      child: AppButton(
                        key: const Key('forgot-password-back-link'),
                        label: l10n.forgotPasswordBackToLogin,
                        variant: AppButtonVariant.text,
                        onPressed: () => context.go(LoginView.path),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
