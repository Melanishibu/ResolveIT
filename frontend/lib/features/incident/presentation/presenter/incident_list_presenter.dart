import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_list.dart';
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

final incidentListPresenterProvider =
    NotifierProvider.autoDispose<IncidentListPresenter, IncidentListState>(
      IncidentListPresenter.new,
    );

class IncidentListPresenter extends Notifier<IncidentListState> {
  @override
  IncidentListState build() {
    Future.microtask(() => _load(const IncidentListFilter()));
    return const IncidentListState();
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
