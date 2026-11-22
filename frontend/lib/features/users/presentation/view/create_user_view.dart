import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/users/domain/entity/new_user.dart';
import 'package:resolveit/core/domain/role.dart';
import 'package:resolveit/features/users/presentation/presenter/create_user_presenter.dart';
import 'package:resolveit/features/users/widgets/role_chip.dart';
import 'package:resolveit/features/users/widgets/role_label.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Admin creates a Technician or Employee who gets an invitation email (`/admin/users/new`, RIT-US-06).
///
/// Built only from the shared UI components (US-28).
class CreateUserView extends ConsumerStatefulWidget {
  const CreateUserView({super.key});

  static const path = '/admin/users/new';

  /// Where the Admin goes after creating a user (the user list arrives with RIT-US-08).
  static const listPath = '/admin/users';

  @override
  ConsumerState<CreateUserView> createState() => _CreateUserViewState();
}

class _CreateUserViewState extends ConsumerState<CreateUserView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _department = TextEditingController();
  Role? _role;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _department.dispose();
    super.dispose();
  }

  void _submit() => ref
      .read(createUserPresenterProvider.notifier)
      .submit(
        NewUser(
          name: _name.text,
          email: _email.text,
          role: _role,
          department: _department.text,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    ref.listen(createUserPresenterProvider, (previous, next) {
      final created = next.created;
      if (created != null && previous?.created == null) {
        AppToast.success(context, l10n.createUserSuccess(created.email));
        context.go(CreateUserView.listPath);
      }
    });
    final state = ref.watch(createUserPresenterProvider);
    final presenter = ref.read(createUserPresenterProvider.notifier);
    final failure = state.failure;
    String? required(NewUserField field, String message) =>
        state.missingFields.contains(field) ? message : null;

    final form = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failure != null) ...[
            ErrorPanel(key: const Key('create-user-error'), failure: failure),
            SizedBox(height: spacing.l),
          ],
          AppTextField(
            key: const Key('create-user-name'),
            label: l10n.createUserNameLabel,
            isRequired: true,
            maxLength: 100,
            controller: _name,
            errorText: required(NewUserField.name, l10n.createUserNameRequired),
            onChanged: (_) => presenter.fieldChanged(NewUserField.name),
          ),
          SizedBox(height: spacing.m),
          AppTextField(
            key: const Key('create-user-email'),
            label: l10n.createUserEmailLabel,
            isRequired: true,
            maxLength: 254,
            keyboardType: TextInputType.emailAddress,
            controller: _email,
            errorText: required(
              NewUserField.email,
              l10n.createUserEmailRequired,
            ),
            onChanged: (_) => presenter.fieldChanged(NewUserField.email),
          ),
          SizedBox(height: spacing.m),
          AppDropdown<Role>(
            key: const Key('create-user-role'),
            label: l10n.createUserRoleLabel,
            isRequired: true,
            value: _role,
            options: [
              for (final role in invitableRoles)
                AppDropdownOption(role, roleLabel(l10n, role)),
            ],
            errorText: required(NewUserField.role, l10n.createUserRoleRequired),
            onChanged: (role) {
              setState(() => _role = role);
              presenter.fieldChanged(NewUserField.role);
            },
          ),
          SizedBox(height: spacing.m),
          AppTextField(
            key: const Key('create-user-department'),
            label: l10n.createUserDepartmentLabel,
            isRequired: true,
            maxLength: 80,
            controller: _department,
            errorText: required(
              NewUserField.department,
              l10n.createUserDepartmentRequired,
            ),
            onChanged: (_) => presenter.fieldChanged(NewUserField.department),
          ),
          SizedBox(height: spacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                key: const Key('create-user-cancel'),
                label: l10n.confirmCancel,
                variant: AppButtonVariant.secondary,
                onPressed: state.isSubmitting
                    ? null
                    : () => context.go(CreateUserView.listPath),
              ),
              SizedBox(width: spacing.m),
              AppButton(
                key: const Key('create-user-submit'),
                label: l10n.createUserButton,
                isLoading: state.isSubmitting,
                onPressed: state.isSubmitting ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            key: const Key('create-user-back'),
            label: l10n.menuUserManagement,
            icon: Icons.arrow_back,
            variant: AppButtonVariant.text,
            onPressed: () => context.go(CreateUserView.listPath),
          ),
        ),
        SizedBox(height: spacing.s),
        PageHeader(
          title: l10n.createUserTitle,
          subtitle: l10n.createUserSubtitle,
        ),
        SizedBox(height: spacing.l),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < spacing.twoColumnMinWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _InfoPanel(),
                  SizedBox(height: spacing.l),
                  form,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 2, child: _InfoPanel()),
                SizedBox(width: spacing.l),
                Expanded(flex: 3, child: form),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final colors = context.appColors;
    final text = context.textTheme;
    return AppCard(
      key: const Key('create-user-help'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_alt_1,
            size: spacing.illustrationIcon,
            color: colors.primary,
          ),
          SizedBox(height: spacing.l),
          Text(
            l10n.createUserTitle,
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.s),
          Text(
            l10n.createUserSubtitle,
            style: text.bodyMedium?.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.l),
          Divider(color: colors.border),
          SizedBox(height: spacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const RoleChip(Role.supportAgent),
              SizedBox(width: spacing.m),
              const RoleChip(Role.employee),
            ],
          ),
        ],
      ),
    );
  }
}
