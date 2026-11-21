import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/core/domain/role.dart';
import 'package:resolveit/features/users/domain/entity/user_summary.dart';
import 'package:resolveit/features/users/providers.dart';

/// State of the user-list screen (RIT-US-08).
final class UserListState {
  const UserListState({
    this.filter = const UserListFilter(),
    this.page,
    this.isLoading = true,
    this.failure,
    this.busyUserId,
    this.statusChanged,
  });

  final UserListFilter filter;

  /// The last page loaded; null before the first load.
  final UserPage? page;
  final bool isLoading;

  /// The backend refused (shown through the structured error panel).
  final ApiFailure? failure;

  /// The user whose status is being changed (their action shows a spinner).
  final String? busyUserId;

  /// Set after a status change, for the success toast.
  final UserSummary? statusChanged;

  UserListState copyWith({
    UserListFilter? filter,
    UserPage? page,
    bool? isLoading,
    ApiFailure? Function()? failure,
    String? Function()? busyUserId,
    UserSummary? Function()? statusChanged,
  }) => UserListState(
    filter: filter ?? this.filter,
    page: page ?? this.page,
    isLoading: isLoading ?? this.isLoading,
    failure: failure == null ? this.failure : failure(),
    busyUserId: busyUserId == null ? this.busyUserId : busyUserId(),
    statusChanged: statusChanged == null ? this.statusChanged : statusChanged(),
  );
}

final userListPresenterProvider =
    NotifierProvider.autoDispose<UserListPresenter, UserListState>(
      UserListPresenter.new,
    );

class UserListPresenter extends Notifier<UserListState> {
  @override
  UserListState build() {
    Future.microtask(() => _load(const UserListFilter()));
    return const UserListState();
  }

  void search(String text) =>
      _load(state.filter.copyWith(search: text, page: 0));

  void filterRole(Role? role) =>
      _load(state.filter.copyWith(role: () => role, page: 0));

  void filterActive(bool? active) =>
      _load(state.filter.copyWith(active: () => active, page: 0));

  void goToPage(int page) => _load(state.filter.copyWith(page: page));

  /// A header was clicked: sort by it, or flip the direction when it is already the sort column.
  void sortBy(String columnId) {
    final field = UserSortField.values
        .where((f) => f.name == columnId)
        .firstOrNull;
    if (field == null) return;
    final ascending = state.filter.sortField == field
        ? !state.filter.ascending
        : true;
    _load(
      state.filter.copyWith(sortField: field, ascending: ascending, page: 0),
    );
  }

  Future<void> setActive(UserSummary user, {required bool active}) async {
    state = state.copyWith(busyUserId: () => user.id, failure: () => null);
    final result = await ref
        .read(userListInteractorProvider)
        .setActive(user.id, active: active);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        final page = state.page;
        state = state.copyWith(
          busyUserId: () => null,
          statusChanged: () => value,
          page: page == null
              ? null
              : UserPage(
                  items: [
                    for (final row in page.items)
                      row.id == value.id ? value : row,
                  ],
                  totalItems: page.totalItems,
                ),
        );
      case Failure(:final failure):
        state = state.copyWith(busyUserId: () => null, failure: () => failure);
    }
  }

  Future<void> _load(UserListFilter filter) async {
    state = state.copyWith(
      filter: filter,
      isLoading: true,
      failure: () => null,
    );
    final result = await ref.read(userListInteractorProvider).load(filter);
    if (!ref.mounted || state.filter != filter) return;
    state = switch (result) {
      Success(:final value) => state.copyWith(page: value, isLoading: false),
      Failure(:final failure) => state.copyWith(
        isLoading: false,
        failure: () => failure,
      ),
    };
  }
}
