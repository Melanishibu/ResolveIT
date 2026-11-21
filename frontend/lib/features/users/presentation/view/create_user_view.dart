import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/users/domain/entity/new_user.dart';
import 'package:resolveit/core/domain/role.dart';
import 'package:resolveit/features/users/presentation/presenter/create_user_presenter.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.createUserTitle,
          subtitle: l10n.createUserSubtitle,
        ),
        SizedBox(height: spacing.l),
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: spacing.dialogMaxWidth),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (failure != null) ...[
                    ErrorPanel(
                      key: const Key('create-user-error'),
                      failure: failure,
                    ),
                    SizedBox(height: spacing.l),
                  ],
                  AppTextField(
                    key: const Key('create-user-name'),
                    label: l10n.createUserNameLabel,
                    isRequired: true,
                    maxLength: 100,
                    controller: _name,
                    errorText: required(
                      NewUserField.name,
                      l10n.createUserNameRequired,
                    ),
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
                    onChanged: (_) =>
                        presenter.fieldChanged(NewUserField.email),
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
                    errorText: required(
                      NewUserField.role,
                      l10n.createUserRoleRequired,
                    ),
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
                    onChanged: (_) =>
                        presenter.fieldChanged(NewUserField.department),
                  ),
                  SizedBox(height: spacing.xl),
                  AppButton(
                    key: const Key('create-user-submit'),
                    label: l10n.createUserButton,
                    isLoading: state.isSubmitting,
                    onPressed: state.isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
