import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_category.dart';
import 'package:resolveit/features/incident/domain/entity/incident_list.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/providers.dart';

/// State of the incident list screen (RIT-US-11).
final class IncidentListState {
  const IncidentListState({
    this.filter = const IncidentListFilter(),
    this.page,
    this.isLoading = true,
    this.failure,
  });

  final IncidentListFilter filter;

  /// The last page loaded; null before the first load.
  final IncidentPage? page;
  final bool isLoading;
  final ApiFailure? failure;
}

final incidentListPresenterProvider = NotifierProvider.autoDispose
    .family<IncidentListPresenter, IncidentListState, IncidentListFilter>(
      IncidentListPresenter.new,
    );

class IncidentListPresenter extends Notifier<IncidentListState> {
  IncidentListPresenter(this.initialFilter);

  /// The filter the screen opened with (from the URL, for example a dashboard card).
  final IncidentListFilter initialFilter;

  @override
  IncidentListState build() {
    Future.microtask(() => _load(initialFilter));
    return IncidentListState(filter: initialFilter);
  }

  void goToPage(int page) => _load(state.filter.copyWith(page: page));

  /// A header was clicked: sort by it (descending first), or flip the direction when it is already the sort column.
  void sortBy(String columnId) {
    final field = IncidentSortField.values
        .where((f) => f.name == columnId)
        .firstOrNull;
    if (field == null) return;
    final ascending =
        state.filter.sortField == field && !state.filter.ascending;
    _load(
      state.filter.copyWith(sortField: field, ascending: ascending, page: 0),
    );
  }

  void search(String text) {
    final trimmed = text.trim();
    _load(
      state.filter.copyWith(q: () => trimmed.isEmpty ? null : trimmed, page: 0),
    );
  }

  void filterStatus(IncidentStatus? status) {
    final statuses = status == null ? const <IncidentStatus>[] : [status];
    _load(state.filter.copyWith(statuses: statuses, page: 0));
  }

  void filterPriority(Priority? priority) {
    final priorities = priority == null ? const <Priority>[] : [priority];
    _load(state.filter.copyWith(priorities: priorities, page: 0));
  }

  void filterCategory(IncidentCategory? category) {
    final categories = category == null
        ? const <IncidentCategory>[]
        : [category];
    _load(state.filter.copyWith(categories: categories, page: 0));
  }

  void filterDateRange(
    DateRangeOption option, {
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    if (option == DateRangeOption.custom) {
      _load(
        state.filter.copyWith(
          dateRange: option,
          createdFrom: () => customFrom,
          createdTo: () => customTo,
          page: 0,
        ),
      );
    } else {
      final bounds = datesForOption(option);
      _load(
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
    _load(
      IncidentListFilter(
        sortField: state.filter.sortField,
        ascending: state.filter.ascending,
      ),
    );
  }

  Future<void> _load(IncidentListFilter filter) async {
    state = IncidentListState(filter: filter, page: state.page);
    final result = await ref.read(incidentListInteractorProvider).load(filter);
    if (!ref.mounted || state.filter != filter) return;
    state = switch (result) {
      Success(:final value) => IncidentListState(
        filter: filter,
        page: value,
        isLoading: false,
      ),
      Failure(:final failure) => IncidentListState(
        filter: filter,
        page: state.page,
        isLoading: false,
        failure: failure,
      ),
    };
  }
}
