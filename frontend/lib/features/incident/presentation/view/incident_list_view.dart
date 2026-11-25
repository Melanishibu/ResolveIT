import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/incident_permissions.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/dashboard/dashboard.dart';
import 'package:resolveit/features/incident/domain/entity/incident_category.dart';
import 'package:resolveit/features/incident/domain/entity/incident_list.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_list_presenter.dart';
import 'package:resolveit/features/incident/presentation/view/incident_details_view.dart';
import 'package:resolveit/features/incident/presentation/view/report_incident_view.dart';
import 'package:resolveit/features/incident/widgets/category_label.dart';
import 'package:resolveit/features/incident/widgets/priority_chip.dart';
import 'package:resolveit/features/incident/widgets/status_chip.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The incident list (RIT-US-11, RIT-US-12): `/incidents` for Admins and `/my-incidents` for
/// Technicians and Employees. Search, filters (status, priority, category, date range), and sortable columns.
class IncidentListView extends ConsumerWidget {
  const IncidentListView({
    super.key,
    this.initialFilter = const IncidentListFilter(),
  });

  /// The search and filter state from the URL (RIT-US-12, RIT-US-21).
  final IncidentListFilter initialFilter;

  static const adminPath = '/incidents';
  static const ownPath = '/my-incidents';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final local = MaterialLocalizations.of(context);
    final role = ref.watch(sessionProvider).value?.role;
    final state = ref.watch(incidentListPresenterProvider(initialFilter));
    final presenter = ref.read(
      incidentListPresenterProvider(initialFilter).notifier,
    );
    final page = state.page;
    final failure = state.failure;

    void open(IncidentListItem incident) =>
        context.go(IncidentDetailsView.pathFor(incident.id));

    void updateUrl(IncidentListFilter newFilter) {
      final query = <String, dynamic>{
        if (newFilter.q != null && newFilter.q!.trim().isNotEmpty)
          'q': newFilter.q!.trim(),
        if (newFilter.statuses.isNotEmpty)
          'status': [for (final s in newFilter.statuses) s.code],
        if (newFilter.priorities.isNotEmpty)
          'priority': [for (final p in newFilter.priorities) p.code],
        if (newFilter.categories.isNotEmpty)
          'category': [for (final c in newFilter.categories) c.code],
        if (newFilter.dateRange != DateRangeOption.allTime)
          'dateRange': newFilter.dateRange.code,
        if (newFilter.createdFrom != null)
          'createdFrom': newFilter.createdFrom!.toIso8601String(),
        if (newFilter.createdTo != null)
          'createdTo': newFilter.createdTo!.toIso8601String(),
      };
      try {
        final path = GoRouterState.of(context).uri.path;
        context.go(
          Uri(
            path: path,
            queryParameters: query.isEmpty ? null : query,
          ).toString(),
        );
      } catch (_) {}
    }

    void onSearch(String text) {
      presenter.search(text);
      updateUrl(
        state.filter.copyWith(
          q: () => text.trim().isEmpty ? null : text.trim(),
          page: 0,
        ),
      );
    }

    void onStatus(IncidentStatus? status) {
      presenter.filterStatus(status);
      updateUrl(
        state.filter.copyWith(
          statuses: status == null ? const [] : [status],
          page: 0,
        ),
      );
    }

    void onPriority(Priority? priority) {
      presenter.filterPriority(priority);
      updateUrl(
        state.filter.copyWith(
          priorities: priority == null ? const [] : [priority],
          page: 0,
        ),
      );
    }

    void onCategory(IncidentCategory? category) {
      presenter.filterCategory(category);
      updateUrl(
        state.filter.copyWith(
          categories: category == null ? const [] : [category],
          page: 0,
        ),
      );
    }

    Future<void> onDateRange(DateRangeOption option) async {
      if (option == DateRangeOption.custom) {
        final now = DateTime.now();
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(now.year + 5),
          initialDateRange:
              state.filter.createdFrom != null && state.filter.createdTo != null
              ? DateTimeRange(
                  start: state.filter.createdFrom!.toLocal(),
                  end: state.filter.createdTo!.toLocal(),
                )
              : null,
        );
        if (picked != null) {
          final startUtc = DateTime.utc(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          );
          final endUtc = DateTime.utc(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
            999,
          );
          presenter.filterDateRange(
            DateRangeOption.custom,
            customFrom: startUtc,
            customTo: endUtc,
          );
          updateUrl(
            state.filter.copyWith(
              dateRange: DateRangeOption.custom,
              createdFrom: () => startUtc,
              createdTo: () => endUtc,
              page: 0,
            ),
          );
        }
      } else {
        presenter.filterDateRange(option);
        final bounds = datesForOption(option);
        updateUrl(
          state.filter.copyWith(
            dateRange: option,
            createdFrom: () => bounds.$1,
            createdTo: () => bounds.$2,
            page: 0,
          ),
        );
      }
    }

    void clearFilters() {
      presenter.clearFilters();
      try {
        final path = GoRouterState.of(context).uri.path;
        context.go(path);
      } catch (_) {}
    }

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
        if (role != null) IncidentCountCards(role: role),
        Wrap(
          key: const Key('incident-filter-bar'),
          spacing: spacing.m,
          runSpacing: spacing.m,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: spacing.fieldMaxWidth,
              child: AppSearchField(
                key: const Key('incident-list-search'),
                hint: l10n.incidentListSearchHint,
                initialText: state.filter.q,
                onSearch: onSearch,
              ),
            ),
            SizedBox(
              width: spacing.filterWidth,
              child: AppDropdown<IncidentStatus?>(
                key: const Key('incident-filter-status'),
                label: l10n.incidentListFilterStatus,
                value: state.filter.statuses.firstOrNull,
                options: [
                  AppDropdownOption(null, l10n.incidentListAllStatuses),
                  for (final status in IncidentStatus.values)
                    AppDropdownOption(
                      status,
                      StatusChip.labelFor(l10n, status),
                    ),
                ],
                onChanged: onStatus,
              ),
            ),
            SizedBox(
              width: spacing.filterWidth,
              child: AppDropdown<Priority?>(
                key: const Key('incident-filter-priority'),
                label: l10n.incidentListFilterPriority,
                value: state.filter.priorities.firstOrNull,
                options: [
                  AppDropdownOption(null, l10n.incidentListAllPriorities),
                  for (final priority in Priority.values)
                    AppDropdownOption(
                      priority,
                      PriorityChip.labelFor(l10n, priority),
                    ),
                ],
                onChanged: onPriority,
              ),
            ),
            SizedBox(
              width: spacing.filterWidth,
              child: AppDropdown<IncidentCategory?>(
                key: const Key('incident-filter-category'),
                label: l10n.incidentListFilterCategory,
                value: state.filter.categories.firstOrNull,
                options: [
                  AppDropdownOption(null, l10n.incidentListAllCategories),
                  for (final category in IncidentCategory.values)
                    AppDropdownOption(category, categoryLabel(l10n, category)),
                ],
                onChanged: onCategory,
              ),
            ),
            SizedBox(
              width: spacing.filterWidth,
              child: AppDropdown<DateRangeOption>(
                key: const Key('incident-filter-date'),
                label: l10n.incidentListFilterDate,
                value: state.filter.dateRange,
                options: [
                  AppDropdownOption(
                    DateRangeOption.allTime,
                    l10n.incidentListDateAll,
                  ),
                  AppDropdownOption(
                    DateRangeOption.last7Days,
                    l10n.incidentListDate7Days,
                  ),
                  AppDropdownOption(
                    DateRangeOption.last30Days,
                    l10n.incidentListDate30Days,
                  ),
                  AppDropdownOption(
                    DateRangeOption.custom,
                    l10n.incidentListDateCustom,
                  ),
                ],
                onChanged: (opt) => onDateRange(opt ?? DateRangeOption.allTime),
              ),
            ),
            if (state.filter.hasFilters)
              AppButton(
                key: const Key('incident-clear-filters'),
                label: l10n.incidentListClearFilters,
                variant: AppButtonVariant.text,
                onPressed: clearFilters,
              ),
          ],
        ),
        if (state.filter.hasFilters) ...[
          SizedBox(height: spacing.s),
          Wrap(
            key: const Key('incident-active-filter-chips'),
            spacing: spacing.s,
            runSpacing: spacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (state.filter.q != null && state.filter.q!.isNotEmpty)
                AppChip(
                  key: const Key('chip-filter-q'),
                  label: '"${state.filter.q}"',
                  colors: context.appColors.statusClosed,
                ),
              for (final s in state.filter.statuses)
                AppChip(
                  key: Key('chip-filter-status-${s.code}'),
                  label: StatusChip.labelFor(l10n, s),
                  colors: StatusChip.colorsFor(context.appColors, s),
                ),
              for (final p in state.filter.priorities)
                AppChip(
                  key: Key('chip-filter-priority-${p.code}'),
                  label: PriorityChip.labelFor(l10n, p),
                  colors: PriorityChip.colorsFor(context.appColors, p),
                ),
              for (final c in state.filter.categories)
                AppChip(
                  key: Key('chip-filter-category-${c.code}'),
                  label: categoryLabel(l10n, c),
                  colors: context.appColors.roleChip,
                ),
              if (state.filter.dateRange != DateRangeOption.allTime)
                AppChip(
                  key: const Key('chip-filter-date'),
                  label: switch (state.filter.dateRange) {
                    DateRangeOption.last7Days => l10n.incidentListDate7Days,
                    DateRangeOption.last30Days => l10n.incidentListDate30Days,
                    _ => l10n.incidentListDateCustom,
                  },
                  colors: context.appColors.statusClosed,
                ),
            ],
          ),
        ],
        SizedBox(height: spacing.l),
        if (failure != null) ...[
          ErrorPanel(key: const Key('incident-list-error'), failure: failure),
          SizedBox(height: spacing.l),
        ],
        if (page == null && state.isLoading)
          const LoadingState()
        else if (page != null && page.items.isEmpty)
          state.filter.hasFilters
              ? EmptyState(
                  key: const Key('incident-list-no-matches'),
                  icon: Icons.search_off,
                  message: l10n.incidentListNoMatches,
                  actionLabel: l10n.incidentListClearFilters,
                  onAction: clearFilters,
                )
              : EmptyState(
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
