import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/incident/domain/entity/incident_list.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_list_presenter.dart';
import 'package:resolveit/features/incident/presentation/view/incident_details_view.dart';
import 'package:resolveit/features/incident/presentation/view/report_incident_view.dart';
import 'package:resolveit/core/domain/incident_permissions.dart';
import 'package:resolveit/features/incident/widgets/priority_chip.dart';
import 'package:resolveit/features/incident/widgets/status_chip.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The incident list (RIT-US-11): `/incidents` for Admins (all incidents) and `/my-incidents` for
/// Technicians (assigned to them) and Employees (their own). The backend scopes the rows; newest first,
/// 20 per page, sortable columns; a row opens the incident's details.
class IncidentListView extends ConsumerWidget {
  const IncidentListView({super.key});

  static const adminPath = '/incidents';
  static const ownPath = '/my-incidents';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final local = MaterialLocalizations.of(context);
    final role = ref.watch(sessionProvider).value?.role;
    final state = ref.watch(incidentListPresenterProvider);
    final presenter = ref.read(incidentListPresenterProvider.notifier);
    final page = state.page;
    final failure = state.failure;

    void open(IncidentListItem incident) =>
        context.go(IncidentDetailsView.pathFor(incident.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: role == Role.admin ? l10n.menuIncidents : l10n.menuMyIncidents,
          subtitle: switch (role) {
            Role.admin => l10n.incidentListSubtitleAll,
            Role.supportAgent => l10n.incidentListSubtitleAssigned,
            _ => l10n.incidentListSubtitleOwn,
          },
          actions: [
            if (role != null && mayCreateIncident(role))
              AppButton(
                key: const Key('incident-list-create'),
                label: l10n.menuCreateIncident,
                icon: Icons.add,
                onPressed: () => context.go(ReportIncidentView.path),
              ),
          ],
        ),
        SizedBox(height: spacing.l),
        if (failure != null) ...[
          ErrorPanel(key: const Key('incident-list-error'), failure: failure),
          SizedBox(height: spacing.l),
        ],
        if (page == null && state.isLoading)
          const LoadingState()
        else if (page != null && page.items.isEmpty)
          EmptyState(
            key: const Key('incident-list-empty'),
            icon: Icons.assignment_outlined,
            message: l10n.incidentListEmpty,
          )
        else if (page != null)
          AppCard(
            child: AppDataTable<IncidentListItem>(
              key: const Key('incident-list-table'),
              rows: page.items,
              page: state.filter.page,
              pageSize: IncidentListFilter.pageSize,
              totalItems: page.totalItems,
              onPageChanged: presenter.goToPage,
              sortColumnId: state.filter.sortField.name,
              sortAscending: state.filter.ascending,
              onSort: presenter.sortBy,
              rowAction: AppTableRowAction(
                label: l10n.incidentListOpen,
                onPressed: open,
              ),
              columns: [
                AppTableColumn(
                  id: IncidentSortField.ticketNumber.name,
                  label: l10n.incidentListNumber,
                  sortable: true,
                  cell: (i) => Text(i.ticketNumber),
                ),
                AppTableColumn(
                  id: 'title',
                  label: l10n.incidentDetailsTitle,
                  cell: (i) => Text(i.title),
                ),
                AppTableColumn(
                  id: IncidentSortField.priority.name,
                  label: l10n.incidentDetailsPriority,
                  sortable: true,
                  cell: (i) => PriorityChip(i.priority),
                ),
                AppTableColumn(
                  id: IncidentSortField.status.name,
                  label: l10n.incidentDetailsStatus,
                  sortable: true,
                  cell: (i) => StatusChip(i.status),
                ),
                if (role == Role.admin)
                  AppTableColumn(
                    id: 'assignee',
                    label: l10n.incidentDetailsAssignedTo,
                    cell: (i) => Text(switch (i.assigneeName) {
                      null => l10n.incidentDetailsNotAssigned,
                      final name when !i.assigneeActive =>
                        '$name (${l10n.incidentDetailsInactiveAssignee})',
                      final name => name,
                    }),
                  ),
                AppTableColumn(
                  id: IncidentSortField.createdAt.name,
                  label: l10n.incidentDetailsCreatedAt,
                  sortable: true,
                  cell: (i) =>
                      Text(local.formatShortDate(i.createdAt.toLocal())),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
