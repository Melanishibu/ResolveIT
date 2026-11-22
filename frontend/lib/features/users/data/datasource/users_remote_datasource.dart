import 'package:dio/dio.dart';
import 'package:resolveit/core/domain/role.dart';
import 'package:resolveit/features/users/domain/entity/new_user.dart';
import 'package:resolveit/features/users/domain/entity/user_profile.dart';
import 'package:resolveit/features/users/domain/entity/user_summary.dart';

/// The user-management REST calls (`/users`, relative to the API base URL). Errors surface as
/// [DioException].
final class UsersRemoteDataSource {
  UsersRemoteDataSource(this._dio);

  final Dio _dio;

  /// `POST /users`: the response body.
  Future<Object?> createUser(NewUser user) async => (await _dio.post<Object?>(
    '/users',
    data: {
      'name': user.name.trim(),
      'email': user.email.trim(),
      'role': user.role?.code,
      'department': user.department.trim(),
    },
  )).data;

  /// `GET /users` with filters, page and sort (RIT-US-08): the response body.
  Future<Object?> listUsers(UserListFilter filter) async {
    final role = filter.role;
    final active = filter.active;
    return (await _dio.get<Object?>(
      '/users',
      queryParameters: {
        if (filter.search.trim().isNotEmpty) 'q': filter.search.trim(),
        'role': ?role?.code,
        'active': ?active,
        'page': filter.page,
        'size': UserListFilter.pageSize,
        'sort': '${filter.sortField.name},${filter.ascending ? 'asc' : 'desc'}',
      },
    )).data;
  }

  /// `PATCH /users/{id}/status` (RIT-US-08): the response body (the updated row).
  Future<Object?> setActive(String userId, {required bool active}) async =>
      (await _dio.patch<Object?>(
        '/users/${Uri.encodeComponent(userId)}/status',
        data: {'active': active},
      )).data;

  /// `GET /users/me` (RIT-US-27): profile of the logged-in user.
  Future<Object?> getMyProfile() async =>
      (await _dio.get<Object?>('/users/me')).data;
}

/// Data model: maps the API's created user; null when the body is not usable.
CreatedUser? createdUserFromJson(Object? data) {
  if (data is! Map) return null;
  final id = data['id'];
  final email = data['email'];
  if (id is! String || email is! String) return null;
  return CreatedUser(id: id, email: email);
}

/// Data model: one user-list row; null when the body is not usable.
UserSummary? userSummaryFromJson(Object? data) {
  if (data is! Map) return null;
  final id = data['id'];
  final name = data['name'];
  final email = data['email'];
  final roleCode = data['role'];
  final department = data['department'];
  final active = data['active'];
  if (id is! String ||
      name is! String ||
      email is! String ||
      roleCode is! String ||
      department is! String ||
      active is! bool) {
    return null;
  }
  final role = Role.tryParse(roleCode);
  if (role == null) return null;
  final invitation = data['invitationStatus'];
  return UserSummary(
    id: id,
    name: name,
    email: email,
    role: role,
    department: department,
    isActive: active,
    invitationStatus: InvitationStatus.tryParse(
      invitation is String ? invitation : null,
    ),
  );
}

/// Data model: one page `{items, totalItems, …}`; null when the body is not usable.
UserPage? userPageFromJson(Object? data) {
  if (data is! Map) return null;
  final items = data['items'];
  final total = data['totalItems'];
  if (items is! List || total is! int) return null;
  final rows = <UserSummary>[];
  for (final item in items) {
    final row = userSummaryFromJson(item);
    if (row == null) return null;
    rows.add(row);
  }
  return UserPage(items: rows, totalItems: total);
}

/// Data model: maps profile response (RIT-US-27); null when the body is not usable.
UserProfile? userProfileFromJson(Object? data) {
  if (data is! Map) return null;
  final name = data['name'];
  final email = data['email'];
  final roleCode = data['role'];
  final roleLabel = data['roleLabel'];
  final department = data['department'];
  final memberSinceRaw = data['memberSince'];
  if (name is! String ||
      email is! String ||
      roleCode is! String ||
      department is! String ||
      memberSinceRaw is! String) {
    return null;
  }
  final role = Role.tryParse(roleCode);
  if (role == null) return null;
  DateTime memberSince;
  try {
    memberSince = DateTime.parse(memberSinceRaw);
  } catch (_) {
    return null;
  }
  return UserProfile(
    name: name,
    email: email,
    role: role,
    roleLabel: roleLabel is String ? roleLabel : role.name,
    department: department,
    memberSince: memberSince,
  );
}
