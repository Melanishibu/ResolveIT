import 'package:dio/dio.dart';
import 'package:resolveit/core/domain/role.dart';
import 'package:resolveit/features/auth/domain/entity/current_user.dart';

/// The auth REST calls (`/auth/login`, `/auth/logout`, `/auth/me`, relative to the API base URL).
///
/// The session lives in the HttpOnly `RIT_SESSION` cookie that the browser sends by itself; this
/// data source never sees or stores the token. Errors surface as [DioException].
final class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /auth/me`: the response body.
  Future<Object?> me() async => (await _dio.get<Object?>('/auth/me')).data;

  /// `POST /auth/login`: the response body.
  Future<Object?> logIn({
    required String email,
    required String password,
  }) async => (await _dio.post<Object?>(
    '/auth/login',
    data: {'email': email, 'password': password},
  )).data;

  /// `POST /auth/logout`.
  Future<void> logOut() => _dio.post<Object?>('/auth/logout');

  /// `GET /auth/csrf`: the backend sets the `XSRF-TOKEN` cookie, which the XSRF interceptor then sends
  /// back as a header (needed without a session, RIT-US-07).
  Future<void> fetchCsrfToken() => _dio.get<Object?>('/auth/csrf');

  /// `POST /auth/password/set` with the token from the link.
  Future<void> setPassword({
    required String token,
    required String newPassword,
  }) => _dio.post<Object?>(
    '/auth/password/set',
    data: {'token': token, 'newPassword': newPassword},
  );

  /// `POST /auth/password/change` (RIT-US-27).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _dio.post<Object?>(
    '/auth/password/change',
    data: {'currentPassword': currentPassword, 'newPassword': newPassword},
  );
}

/// Data model: maps the API's `{id, name, email, role}` to a [CurrentUser]; null when the body is
/// not usable.
CurrentUser? currentUserFromJson(Object? data) {
  if (data is! Map) return null;
  final id = data['id'];
  final name = data['name'];
  final roleCode = data['role'];
  if (id is! String || name is! String || roleCode is! String) return null;
  final role = Role.tryParse(roleCode);
  if (role == null || id.trim().isEmpty || name.trim().isEmpty) return null;
  return CurrentUser(id: id, displayName: name, role: role);
}
