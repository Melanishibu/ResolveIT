import 'package:resolveit/core/domain/role.dart';

/// The invitation status shown in the user list (RIT-US-08), derived by the backend.
enum InvitationStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  expired('EXPIRED'),
  sendFailed('SEND_FAILED');

  const InvitationStatus(this.code);

  final String code;

  static InvitationStatus? tryParse(String? code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    return null;
  }
}

/// One row of the Admin's user list.
final class UserSummary {
  const UserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.isActive,
    required this.invitationStatus,
  });

  final String id;
  final String name;
  final String email;
  final Role role;
  final String department;
  final bool isActive;
  final InvitationStatus? invitationStatus;
}

/// Sortable columns of the user list.
enum UserSortField { name, email, role, department }

/// Filters, page and sort of the user list (20 per page).
final class UserListFilter {
  const UserListFilter({
    this.search = '',
    this.role,
    this.active,
    this.page = 0,
    this.sortField = UserSortField.name,
    this.ascending = true,
  });

  static const pageSize = 20;

  final String search;
  final Role? role;
  final bool? active;
  final int page;
  final UserSortField sortField;
  final bool ascending;

  UserListFilter copyWith({
    String? search,
    Role? Function()? role,
    bool? Function()? active,
    int? page,
    UserSortField? sortField,
    bool? ascending,
  }) => UserListFilter(
    search: search ?? this.search,
    role: role == null ? this.role : role(),
    active: active == null ? this.active : active(),
    page: page ?? this.page,
    sortField: sortField ?? this.sortField,
    ascending: ascending ?? this.ascending,
  );
}

/// One page of users.
final class UserPage {
  const UserPage({required this.items, required this.totalItems});

  final List<UserSummary> items;
  final int totalItems;
}
