import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/comments/comments.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_details_presenter.dart';
import 'package:resolveit/features/incident/presentation/presenter/assign_incident_presenter.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_status_presenter.dart';
import 'package:resolveit/features/incident/presentation/view/assign_incident_panel.dart';
import 'package:resolveit/features/incident/presentation/view/resolve_incident_panel.dart';
import 'package:resolveit/features/incident/presentation/view/reopen_incident_panel.dart';
import 'package:resolveit/features/incident/widgets/category_label.dart';
import 'package:resolveit/features/incident/widgets/priority_chip.dart';
import 'package:resolveit/features/incident/widgets/status_chip.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// One incident (`/incidents/:id`, RIT-US-10): back link, header with number, chips and the Actions menu
/// (only the backend's `allowedActions`, shown disabled until their stories), tabs Overview / Comments / History.
class IncidentDetailsView extends ConsumerWidget {
  const IncidentDetailsView({super.key, required this.incidentId});

  static const pathPattern = '/incidents/:id';

  static String pathFor(String id) => '/incidents/$id';

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final role = ref.watch(sessionProvider).value?.role;
    final details = ref.watch(incidentDetailsPresenterProvider(incidentId));
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              key: const Key('incident-details-back'),
              label: role == Role.admin
                  ? l10n.incidentDetailsBackToIncidents
                  : l10n.incidentDetailsBackToMyIncidents,
              variant: AppButtonVariant.text,
              onPressed: () => context.go(
                role == Role.admin ? '/incidents' : '/my-incidents',
              ),
            ),
          ),
          SizedBox(height: spacing.m),
          details.when(
            loading: () => const LoadingState(),
            error: (error, _) => ErrorPanel(
              key: const Key('incident-details-error'),
              failure: error is ApiFailure ? error : ApiFailure.unknown(),
            ),
            data: (incident) => _Details(incident: incident),
          ),
        ],
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.incident});

  final IncidentDetails incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    ref.listen(assignIncidentPresenterProvider(incident.id), (previous, next) {
      final assigned = next.assigned;
      if (assigned != null && previous?.assigned == null) {
        AppToast.success(
          context,
          l10n.assignPanelDone(assigned.assignee?.name ?? ''),
        );
      }
    });
    ref.listen(incidentStatusPresenterProvider(incident.id), (previous, next) {
      if (next.started != null && previous?.started == null) {
        AppToast.success(context, l10n.statusStartedDone);
      }
      if (next.resolved != null && previous?.resolved == null) {
        AppToast.success(context, l10n.statusResolvedDone);
      }
      if (next.closed != null && previous?.closed == null) {
        AppToast.success(context, l10n.statusClosedDone);
      }
      if (next.reopened != null && previous?.reopened == null) {
        AppToast.success(context, l10n.statusReopenedDone);
      }
    });
    final statusState = ref.watch(incidentStatusPresenterProvider(incident.id));
    final statusFailure = statusState.failure;
    final assignState = ref.watch(assignIncidentPresenterProvider(incident.id));
    final commentCount = ref
        .watch(incidentCommentsPresenterProvider(incident.id))
        .count;
    void startWork() => ref
        .read(incidentStatusPresenterProvider(incident.id).notifier)
        .startWork();
    void openAssign() => ref
        .read(assignIncidentPresenterProvider(incident.id).notifier)
        .open();
    Future<void> confirmClose() async {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.closeConfirmTitle(incident.ticketNumber),
        message: l10n.closeConfirmMessage,
        confirmLabel: l10n.incidentActionClose,
      );
      if (confirmed) {
        await ref
            .read(incidentStatusPresenterProvider(incident.id).notifier)
            .close();
      }
    }

    void choose(IncidentAction action) {
      if (action == IncidentAction.assign ||
          action == IncidentAction.reassign) {
        ref.read(assignIncidentPresenterProvider(incident.id).notifier).open();
      } else if (action == IncidentAction.reopen) {
        ref
            .read(incidentStatusPresenterProvider(incident.id).notifier)
            .openReopen();
      } else if (action == IncidentAction.close) {
        confirmClose();
      } else if (action == IncidentAction.resolve) {
        ref
            .read(incidentStatusPresenterProvider(incident.id).notifier)
            .openResolve();
      } else if (action == IncidentAction.start) {
        startWork();
      }
    }

    final menuActions = incident.allowedActions
        .where(
          (a) =>
              a != IncidentAction.start &&
              a != IncidentAction.assign &&
              a != IncidentAction.reassign,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: incident.ticketNumber,
          subtitle: incident.title,
          actions: [
            PriorityChip(incident.priority),
            StatusChip(incident.status),
            if (incident.allowedActions.contains(IncidentAction.assign))
              AppButton(
                key: const Key('incident-assign'),
                label: l10n.incidentActionAssign,
                icon: Icons.person_add_alt_1,
                isLoading: assignState.isSaving,
                onPressed: assignState.isSaving ? null : openAssign,
              ),
            if (incident.allowedActions.contains(IncidentAction.reassign))
              AppButton(
                key: const Key('incident-reassign'),
                label: l10n.incidentActionReassign,
                icon: Icons.person_add_alt_1,
                isLoading: assignState.isSaving,
                onPressed: assignState.isSaving ? null : openAssign,
              ),
            if (incident.allowedActions.contains(IncidentAction.start))
              AppButton(
                key: const Key('incident-start-work'),
                label: l10n.incidentActionStart,
                icon: Icons.play_arrow,
                isLoading: statusState.isSaving,
                onPressed: statusState.isSaving ? null : startWork,
              ),
            if (menuActions.where(_isAvailable).isNotEmpty)
              PopupMenuButton<IncidentAction>(
                key: const Key('incident-details-actions'),
                tooltip: l10n.incidentDetailsActions,
                onSelected: choose,
                itemBuilder: (context) => [
                  for (final action in menuActions)
                    if (_isAvailable(action))
                      PopupMenuItem<IncidentAction>(
                        key: Key('incident-action-${action.code}'),
                        value: action,
                        child: Text(_actionLabel(l10n, action)),
                      )
                    else
                      PopupMenuItem<IncidentAction>(
                        key: Key('incident-action-${action.code}'),
                        enabled: false,
                        value: action,
                        child: Text(
                          '${_actionLabel(l10n, action)} · ${l10n.incidentDetailsActionLater}',
                        ),
                      ),
                ],
                child: Padding(
                  padding: EdgeInsets.all(spacing.s),
                  child: Text(l10n.incidentDetailsActions),
                ),
              ),
          ],
        ),
        SizedBox(height: spacing.l),
        if (statusFailure != null) ...[
          ErrorPanel(key: const Key('status-error'), failure: statusFailure),
          SizedBox(height: spacing.l),
        ],
        AssignIncidentPanel(incidentId: incident.id),
        ResolveIncidentPanel(incidentId: incident.id),
        ReopenIncidentPanel(incidentId: incident.id),
        AppTabs(
          tabs: [
            AppTab(
              label: l10n.incidentDetailsOverview,
              child: _Overview(incident: incident),
            ),
            AppTab(
              label: l10n.incidentDetailsComments(commentCount),
              child: IncidentCommentsTab(
                incidentId: incident.id,
                canComment: incident.status != IncidentStatus.closed,
              ),
            ),
            AppTab(
              label: l10n.incidentDetailsHistory,
              child: EmptyState(
                icon: Icons.history,
                message: l10n.incidentDetailsHistoryLater,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.incident});

  final IncidentDetails incident;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final local = MaterialLocalizations.of(context);
    final created = incident.createdAt.toLocal();
    final assignee = incident.assignee;
    final rows = <(String, Widget)>[
      (l10n.incidentDetailsTitle, Text(incident.title)),
      (l10n.incidentDetailsDescription, Text(incident.description)),
      (
        l10n.incidentDetailsCategory,
        Text(categoryLabel(l10n, incident.category)),
      ),
      (l10n.incidentDetailsPriority, PriorityChip(incident.priority)),
      (l10n.incidentDetailsStatus, StatusChip(incident.status)),
      (
        l10n.incidentDetailsCreatedBy,
        Text(incident.createdBy.name ?? l10n.incidentDetailsNone),
      ),
      (
        l10n.incidentDetailsCreatedAt,
        Text(
          '${local.formatShortDate(created)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(created))}',
        ),
      ),
      (
        l10n.incidentDetailsAssignedTo,
        Text(
          assignee == null
              ? l10n.incidentDetailsNotAssigned
              : '${assignee.name ?? l10n.incidentDetailsNone}'
                    '${assignee.active ? '' : ' (${l10n.incidentDetailsInactiveAssignee})'}',
        ),
      ),
      (
        l10n.incidentDetailsDepartment,
        Text(
          key: const Key('incident-details-department'),
          incident.createdBy.department ?? l10n.incidentDetailsNone,
        ),
      ),
      (
        l10n.incidentDetailsResolutionNotes,
        Text(incident.resolutionNotes ?? l10n.incidentDetailsNone),
      ),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.incidentDetailsInformation,
            style: context.textTheme.titleMedium,
          ),
          SizedBox(height: spacing.m),
          for (final (label, value) in rows)
            Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(label, style: context.textTheme.labelLarge),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(alignment: Alignment.centerLeft, child: value),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _actionLabel(AppLocalizations l10n, IncidentAction action) =>
    switch (action) {
      IncidentAction.assign => l10n.incidentActionAssign,
      IncidentAction.reassign => l10n.incidentActionReassign,
      IncidentAction.start => l10n.incidentActionStart,
      IncidentAction.resolve => l10n.incidentActionResolve,
      IncidentAction.reopen => l10n.incidentActionReopen,
      IncidentAction.close => l10n.incidentActionClose,
      IncidentAction.changePriority => l10n.incidentActionChangePriority,
    };

/// Actions whose stories are built; the others stay visible but disabled.
bool _isAvailable(IncidentAction action) =>
    action == IncidentAction.assign ||
    action == IncidentAction.reassign ||
    action == IncidentAction.start ||
    action == IncidentAction.resolve ||
    action == IncidentAction.close ||
    action == IncidentAction.reopen;
