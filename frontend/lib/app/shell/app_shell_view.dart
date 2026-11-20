import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/shell/app_shell_presenter.dart';
import 'package:resolveit/app/shell/navigation_menu.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/errors/error_panel.dart';
import 'package:resolveit/features/identity/identity.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The app shell: navy sidebar with the role's menu, top bar with the avatar, page content.
class AppShellView extends ConsumerWidget {
  const AppShellView({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appShellPresenterProvider);
    return Scaffold(
      body: user.when(
        data: (currentUser) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Sidebar(
              role: currentUser.role,
              active: MenuDestination.forLocation(location),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(user: currentUser),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(context.spacing.xl),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => Center(
          child: CircularProgressIndicator(
            semanticsLabel: AppLocalizations.of(context).loadingLabel,
          ),
        ),
        error: (error, _) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.spacing.dialogMaxWidth,
            ),
            child: ErrorPanel(
              failure: error is ApiFailure ? error : ApiFailure.unknown(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.role, required this.active});

  final Role role;
  final MenuDestination? active;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    return Container(
      key: const Key('app-sidebar'),
      width: spacing.sidebarWidth,
      color: colors.sidebarBackground,
      padding: EdgeInsets.all(spacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent, color: colors.sidebarForeground),
              SizedBox(width: spacing.s),
              Expanded(
                child: Text(
                  l10n.appBrand,
                  key: const Key('app-logo'),
                  style: context.textTheme.titleMedium?.copyWith(
                    color: colors.sidebarForeground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.xxl),
          for (final destination in menuFor(role))
            _MenuItem(
              key: Key('menu-item-${destination.name}'),
              icon: destination.icon,
              label: destination.label(l10n),
              selected: destination == active,
              onTap: () => context.go(destination.path),
            ),
          const Spacer(),
          _MenuItem(
            key: const Key('menu-item-logout'),
            icon: Icons.logout,
            label: l10n.menuLogout,
            selected: false,
            // Logout arrives with US-04 (AB#13).
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.spacing;
    final foreground = selected
        ? colors.sidebarActiveForeground
        : colors.sidebarForeground;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.xs),
      child: Material(
        color: selected
            ? colors.sidebarActiveBackground
            : colors.sidebarBackground,
        borderRadius: BorderRadius.circular(context.radii.control),
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radii.control),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.m,
              vertical: spacing.m,
            ),
            child: Row(
              children: [
                Icon(icon, color: foreground),
                SizedBox(width: spacing.m),
                Expanded(
                  child: Text(
                    label,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.user});

  final CurrentUser user;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.spacing;
    final l10n = AppLocalizations.of(context);
    final role = roleLabel(l10n, user.role);
    return Container(
      height: spacing.topBarHeight,
      color: colors.cardBackground,
      padding: EdgeInsets.symmetric(horizontal: spacing.xl),
      child: Row(
        children: [
          const Spacer(),
          Text(
            role,
            key: const Key('current-role'),
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(width: spacing.m),
          Tooltip(
            message: l10n.avatarTooltip(user.displayName, role),
            child: CircleAvatar(
              key: const Key('user-avatar'),
              radius: spacing.avatarRadius,
              backgroundColor: colors.primary,
              child: Text(
                user.initials,
                style: context.textTheme.labelLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
