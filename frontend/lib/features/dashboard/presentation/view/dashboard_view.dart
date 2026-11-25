import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/dashboard/domain/entity/dashboard.dart';
import 'package:resolveit/features/dashboard/presentation/presenter/dashboard_presenter.dart';
import 'package:resolveit/features/dashboard/widgets/count_card.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The role-based dashboard (`/dashboard`, RIT-US-21): count cards that open the filtered incident list, and
/// Recent Activity (Admin, Employee) or Recent Assigned Incidents (Technician). The page title stays "Dashboard"
/// (the shell tests rely on it); the role-specific title from the spec is shown as the subtitle.
class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  static const path = '/dashboard';

  static const _notClosed = ['OPEN', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final role = ref.watch(sessionProvider).value?.role ?? Role.employee;
    final isTechnician = role == Role.supportAgent;
    final data = ref.watch(dashboardPresenterProvider(isTechnician));
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: l10n.menuDashboard,
            subtitle: switch (role) {
              Role.admin => l10n.dashboardAdminTitle,
              Role.supportAgent => l10n.dashboardTechnicianTitle,
              _ => l10n.dashboardEmployeeTitle,
            },
          ),
          SizedBox(height: spacing.l),
          data.when(
            loading: () => const LoadingState(),
            error: (error, _) => ErrorPanel(
              key: const Key('dashboard-error'),
              failure: error is ApiFailure ? error : ApiFailure.unknown(),
            ),
            data: (dashboard) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: spacing.m,
                  runSpacing: spacing.m,
                  children: _cards(l10n, role, dashboard.counts),
                ),
                SizedBox(height: spacing.xl),
                if (isTechnician)
                  _RecentAssigned(items: dashboard.recentAssigned)
                else
                  _RecentActivity(items: dashboard.activity),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _cards(AppLocalizations l10n, Role role, DashboardCounts c) {
    CountCard card(String key, String label, int count, String location) =>
        CountCard(
          key: Key('dashboard-card-$key'),
          label: label,
          count: count,
          location: location,
        );
    final total = card(
      'total',
      l10n.dashboardTotal,
      c.total,
      incidentListLocation(role),
    );
    final open = card(
      'open',
      l10n.statusOpen,
      c.open,
      incidentListLocation(role, statuses: ['OPEN']),
    );
    final assigned = card(
      'assigned',
      l10n.statusAssigned,
      c.assigned,
      incidentListLocation(role, statuses: ['ASSIGNED']),
    );
    final inProgress = card(
      'in-progress',
      l10n.statusInProgress,
      c.inProgress,
      incidentListLocation(role, statuses: ['IN_PROGRESS']),
    );
    final resolved = card(
      'resolved',
      l10n.statusResolved,
      c.resolved,
      incidentListLocation(role, statuses: ['RESOLVED']),
    );
    final critical = card(
      'critical',
      l10n.priorityCritical,
      c.critical,
      incidentListLocation(
        role,
        statuses: _notClosed,
        priorities: ['CRITICAL'],
      ),
    );
    return switch (role) {
      Role.admin => [total, open, assigned, inProgress, resolved, critical],
      Role.supportAgent => [assigned, inProgress, resolved],
      _ => [total, open, inProgress, resolved],
    };
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.items});

  final List<ActivityEntry> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final local = MaterialLocalizations.of(context);
    return AppCard(
      key: const Key('dashboard-recent-activity'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dashboardRecentActivity,
            style: context.textTheme.titleMedium,
          ),
          SizedBox(height: context.spacing.m),
          if (items.isEmpty)
            EmptyState(icon: Icons.history, message: l10n.dashboardNoActivity)
          else
            for (final entry in items)
              ListTile(
                title: Text(
                  '${entry.ticketNumber} · ${_actionLabel(l10n, entry.action)}',
                ),
                subtitle: Text(
                  '${entry.actorName ?? l10n.incidentDetailsNone} · '
                  '${local.formatShortDate(entry.occurredAt.toLocal())} '
                  '${local.formatTimeOfDay(TimeOfDay.fromDateTime(entry.occurredAt.toLocal()))}',
                ),
                onTap: () => context.go('/incidents/${entry.incidentId}'),
              ),
        ],
      ),
    );
  }
}

class _RecentAssigned extends StatelessWidget {
  const _RecentAssigned({required this.items});

  final List<RecentIncident> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      key: const Key('dashboard-recent-assigned'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dashboardRecentAssigned,
            style: context.textTheme.titleMedium,
          ),
          SizedBox(height: context.spacing.m),
          if (items.isEmpty)
            EmptyState(
              icon: Icons.assignment_outlined,
              message: l10n.dashboardNoAssigned,
            )
          else
            for (final incident in items)
              ListTile(
                key: Key('dashboard-recent-${incident.id}'),
                title: Text('${incident.ticketNumber} · ${incident.title}'),
                subtitle: Text(_statusLabel(l10n, incident.status)),
                onTap: () => context.go('/incidents/${incident.id}'),
              ),
        ],
      ),
    );
  }
}

String _statusLabel(AppLocalizations l10n, String code) => switch (code) {
  'OPEN' => l10n.statusOpen,
  'ASSIGNED' => l10n.statusAssigned,
  'IN_PROGRESS' => l10n.statusInProgress,
  'RESOLVED' => l10n.statusResolved,
  _ => l10n.statusClosed,
};

String _actionLabel(AppLocalizations l10n, String code) => switch (code) {
  'CREATED' => l10n.activityCreated,
  'ASSIGNED' => l10n.activityAssigned,
  'REASSIGNED' => l10n.activityReassigned,
  'STARTED' => l10n.activityStarted,
  'RESOLVED' => l10n.activityResolved,
  'REOPENED' => l10n.activityReopened,
  'CLOSED' => l10n.activityClosed,
  _ => l10n.activityPriorityChanged,
};
