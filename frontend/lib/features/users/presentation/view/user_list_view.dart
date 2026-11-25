import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/users/domain/entity/user_summary.dart';
import 'package:resolveit/features/users/presentation/presenter/user_list_presenter.dart';
import 'package:resolveit/features/users/presentation/view/create_user_view.dart';
import 'package:resolveit/features/users/widgets/active_chip.dart';
import 'package:resolveit/features/users/widgets/invitation_status_label.dart';
import 'package:resolveit/features/users/widgets/role_chip.dart';
import 'package:resolveit/features/users/widgets/role_label.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// User Management for Admins (`/admin/users`, RIT-US-08): search, role and status filters, a sortable
/// paged table (20 per page), Activate/Deactivate (deactivate is confirmed). No edit, delete or export.
class UserListView extends ConsumerWidget {
  const UserListView({super.key});

  static const path = '/admin/users';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    ref.listen(userListPresenterProvider, (previous, next) {
      final changed = next.statusChanged;
      if (changed != null && !identical(changed, previous?.statusChanged)) {
        AppToast.success(
          context,
          changed.isActive
              ? l10n.userListActivated(changed.name)
              : l10n.userListDeactivated(changed.name),
        );
      }
    });
    ref.listen(userListPresenterProvider, (previous, next) {
      final resent = next.invitationResent;
      if (resent != null && !identical(resent, previous?.invitationResent)) {
        AppToast.success(context, l10n.userListInvitationResent(resent.name));
      }
    });
    final state = ref.watch(userListPresenterProvider);
    final presenter = ref.read(userListPresenterProvider.notifier);
    final ownId = ref.watch(sessionProvider).value?.id;
    final page = state.page;
    final failure = state.failure;

    Future<void> deactivate(UserSummary user) async {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.userListDeactivateTitle(user.name),
        message: l10n.userListDeactivateMessage,
        confirmLabel: l10n.userListDeactivate,
        isDanger: true,
      );
      if (confirmed) await presenter.setActive(user, active: false);
    }

    Widget actions(UserSummary user) {
      if (user.id == ownId) return const SizedBox.shrink();
      final busy = state.busyUserId == user.id;
      final canResend =
          user.invitationStatus != null &&
          user.invitationStatus != InvitationStatus.accepted;
      final statusButton = user.isActive
          ? AppButton(
              key: Key('user-deactivate-${user.email}'),
              label: l10n.userListDeactivate,
              variant: AppButtonVariant.danger,
              isLoading: busy,
              onPressed: busy ? null : () => deactivate(user),
            )
          : AppButton(
              key: Key('user-activate-${user.email}'),
              label: l10n.userListActivate,
              variant: AppButtonVariant.secondary,
              isLoading: busy,
              onPressed: busy
                  ? null
                  : () => presenter.setActive(user, active: true),
            );
      if (!canResend) return statusButton;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          statusButton,
          SizedBox(width: spacing.s),
          AppButton(
            key: Key('user-resend-${user.email}'),
            label: l10n.userListResendInvitation,
            variant: AppButtonVariant.secondary,
            isLoading: busy,
            onPressed: busy ? null : () => presenter.resendInvitation(user),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.menuUserManagement,
          subtitle: l10n.userListSubtitle,
          actions: [
            AppButton(
              key: const Key('user-list-add'),
              label: l10n.userListAdd,
              icon: Icons.person_add_alt_1,
              onPressed: () => context.go(CreateUserView.path),
            ),
          ],
        ),
        SizedBox(height: spacing.l),
        Wrap(
          spacing: spacing.m,
          runSpacing: spacing.m,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: spacing.fieldMaxWidth,
              child: AppSearchField(
                key: const Key('user-list-search'),
                hint: l10n.userListSearchHint,
                onSearch: presenter.search,
              ),
            ),
            SizedBox(
              width: spacing.filterWidth,
              child: AppDropdown<Role?>(
                key: const Key('user-list-role'),
                label: l10n.userListRoleFilter,
                value: state.filter.role,
                options: [
                  AppDropdownOption(null, l10n.userListAllRoles),
                  for (final role in Role.values)
                    AppDropdownOption(role, roleLabel(l10n, role)),
                ],
                onChanged: presenter.filterRole,
              ),
            ),
            SizedBox(
              width: spacing.filterWidth,
              child: AppDropdown<bool?>(
                key: const Key('user-list-status'),
                label: l10n.userListStatusFilter,
                value: state.filter.active,
                options: [
                  AppDropdownOption(null, l10n.userListAllStatuses),
                  AppDropdownOption(true, l10n.userActive),
                  AppDropdownOption(false, l10n.userInactive),
                ],
                onChanged: presenter.filterActive,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing.l),
        if (failure != null) ...[
          ErrorPanel(key: const Key('user-list-error'), failure: failure),
          SizedBox(height: spacing.l),
        ],
        if (page == null && state.isLoading)
          const LoadingState()
        else if (page != null && page.items.isEmpty)
          EmptyState(
            key: const Key('user-list-empty'),
            icon: Icons.group_off_outlined,
            message: l10n.userListEmpty,
          )
        else if (page != null)
          AppCard(
            child: AppDataTable<UserSummary>(
              key: const Key('user-list-table'),
              rows: page.items,
              page: state.filter.page,
              pageSize: UserListFilter.pageSize,
              totalItems: page.totalItems,
              onPageChanged: presenter.goToPage,
              sortColumnId: state.filter.sortField.name,
              sortAscending: state.filter.ascending,
              onSort: presenter.sortBy,
              columns: [
                AppTableColumn(
                  id: UserSortField.name.name,
                  label: l10n.userListName,
                  sortable: true,
                  cell: (u) => Text(u.name),
                ),
                AppTableColumn(
                  id: UserSortField.email.name,
                  label: l10n.userListEmail,
                  sortable: true,
                  cell: (u) => Text(u.email),
                ),
                AppTableColumn(
                  id: UserSortField.role.name,
                  label: l10n.userListRole,
                  sortable: true,
                  cell: (u) => RoleChip(u.role),
                ),
                AppTableColumn(
                  id: UserSortField.department.name,
                  label: l10n.userListDepartment,
                  sortable: true,
                  cell: (u) => Text(u.department),
                ),
                AppTableColumn(
                  id: 'status',
                  label: l10n.userListStatus,
                  cell: (u) => ActiveChip(isActive: u.isActive),
                ),
                AppTableColumn(
                  id: 'invitation',
                  label: l10n.userListInvitation,
                  cell: (u) =>
                      Text(invitationStatusLabel(l10n, u.invitationStatus)),
                ),
                AppTableColumn(
                  id: 'actions',
                  label: l10n.userListActions,
                  cell: actions,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
