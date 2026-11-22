import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/users/domain/entity/user_profile.dart';
import 'package:resolveit/features/users/presentation/presenter/profile_presenter.dart';
import 'package:resolveit/features/users/widgets/role_chip.dart';
import 'package:resolveit/features/users/widgets/role_label.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The user's profile and password change screen (`/profile`, RIT-US-27).
class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  static const path = '/profile';

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _currentError;
  String? _newError;
  String? _confirmError;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submitPassword() async {
    final l10n = AppLocalizations.of(context);
    final current = _currentPassword.text;
    final next = _newPassword.text;
    final confirm = _confirmPassword.text;

    setState(() {
      _currentError = current.isEmpty ? l10n.profileCurrentPasswordRequired : null;
      _newError = next.isEmpty ? l10n.profileNewPasswordRequired : null;
      _confirmError = confirm.isEmpty
          ? l10n.profileConfirmPasswordRequired
          : (next != confirm ? l10n.profilePasswordsDoNotMatch : null);
    });

    if (_currentError != null || _newError != null || _confirmError != null) {
      return;
    }

    final success = await ref.read(profilePresenterProvider.notifier).changePassword(
          currentPassword: current,
          newPassword: next,
        );

    if (success && mounted) {
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      AppToast.success(context, l10n.profilePasswordChangedSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final state = ref.watch(profilePresenterProvider);
    final profile = state.profile;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: l10n.profileTitle,
            subtitle: l10n.profileSubtitle,
          ),
          SizedBox(height: spacing.l),
          if (state.isLoading && profile == null)
            const LoadingState()
          else if (state.failure != null && profile == null)
            ErrorPanel(key: const Key('profile-load-error'), failure: state.failure!)
          else if (profile != null) ...[
            _ProfileHeaderCard(profile: profile),
            SizedBox(height: spacing.l),
            AppTabs(
              tabs: [
                AppTab(
                  key: const Key('profile-tab-personal'),
                  label: l10n.profileTabPersonalInfo,
                  child: _PersonalInfoTab(profile: profile),
                ),
                AppTab(
                  key: const Key('profile-tab-security'),
                  label: l10n.profileTabSecurity,
                  child: _SecurityTab(
                    currentPasswordController: _currentPassword,
                    newPasswordController: _newPassword,
                    confirmPasswordController: _confirmPassword,
                    currentError: _currentError,
                    newError: _newError,
                    confirmError: _confirmError,
                    isSubmitting: state.isSubmittingPassword,
                    failure: state.passwordFailure,
                    onSubmit: _submitPassword,
                    onChanged: () {
                      if (_currentError != null || _newError != null || _confirmError != null) {
                        setState(() {
                          _currentError = null;
                          _newError = null;
                          _confirmError = null;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return AppCard(
      key: const Key('profile-card'),
      child: Row(
        children: [
          AvatarInitials(
            key: const Key('profile-avatar'),
            initials: profile.initials,
            semanticLabel: profile.name,
          ),
          SizedBox(width: spacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  key: const Key('profile-summary-name'),
                  style: context.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: spacing.xs),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: spacing.m,
                  runSpacing: spacing.xs,
                  children: [
                    RoleChip(key: const Key('profile-role-chip'), profile.role),
                    Text(
                      profile.email,
                      key: const Key('profile-summary-email'),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoTab extends StatelessWidget {
  const _PersonalInfoTab({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final local = MaterialLocalizations.of(context);

    return AppCard(
      key: const Key('profile-personal-info-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReadOnlyRow(
            label: l10n.profileName,
            value: profile.name,
            valueKey: 'profile-name-value',
          ),
          Divider(color: context.appColors.border),
          _ReadOnlyRow(
            label: l10n.profileEmail,
            value: profile.email,
            valueKey: 'profile-email-value',
          ),
          Divider(color: context.appColors.border),
          _ReadOnlyRow(
            label: l10n.profileRole,
            value: roleLabel(l10n, profile.role),
            valueKey: 'profile-role-value',
          ),
          Divider(color: context.appColors.border),
          _ReadOnlyRow(
            label: l10n.profileDepartment,
            value: profile.department,
            valueKey: 'profile-department-value',
          ),
          Divider(color: context.appColors.border),
          _ReadOnlyRow(
            label: l10n.profileMemberSince,
            value: local.formatShortDate(profile.memberSince.toLocal()),
            valueKey: 'profile-member-since-value',
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              key: Key(valueKey),
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityTab extends StatelessWidget {
  const _SecurityTab({
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.currentError,
    required this.newError,
    required this.confirmError,
    required this.isSubmitting,
    required this.failure,
    required this.onSubmit,
    required this.onChanged,
  });

  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final String? currentError;
  final String? newError;
  final String? confirmError;
  final bool isSubmitting;
  final ApiFailure? failure;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;

    return AppCard(
      key: const Key('profile-security-card'),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: spacing.dialogMaxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.profileChangePasswordTitle,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: spacing.l),
            if (failure != null) ...[
              ErrorPanel(
                key: const Key('profile-password-error'),
                failure: failure!,
              ),
              SizedBox(height: spacing.l),
            ],
            AppTextField(
              key: const Key('profile-current-password'),
              label: l10n.profileCurrentPassword,
              isRequired: true,
              isPassword: true,
              controller: currentPasswordController,
              errorText: currentError,
              onChanged: (_) => onChanged(),
            ),
            SizedBox(height: spacing.m),
            AppTextField(
              key: const Key('profile-new-password'),
              label: l10n.profileNewPassword,
              isRequired: true,
              isPassword: true,
              controller: newPasswordController,
              errorText: newError,
              onChanged: (_) => onChanged(),
            ),
            SizedBox(height: spacing.m),
            AppTextField(
              key: const Key('profile-confirm-password'),
              label: l10n.profileConfirmPassword,
              isRequired: true,
              isPassword: true,
              controller: confirmPasswordController,
              errorText: confirmError,
              onChanged: (_) => onChanged(),
            ),
            SizedBox(height: spacing.l),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                key: const Key('profile-change-password-submit'),
                label: l10n.profileChangePasswordButton,
                isLoading: isSubmitting,
                onPressed: onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
