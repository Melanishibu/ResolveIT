import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/application/ports/current_user_gateway.dart';
import 'package:resolveit/features/identity/application/ports/session_gateway.dart';
import 'package:resolveit/features/identity/domain/current_user.dart';
import 'package:resolveit/features/identity/domain/login_credentials.dart';
import 'package:resolveit/features/identity/domain/role.dart';

/// The identity API (`/auth/login`, `/auth/logout`, `/auth/me`, relative to the API base URL).
///
/// The session lives in the HttpOnly `RIT_SESSION` cookie that the browser sends by itself; this
/// adapter never sees or stores the token.
final class ApiIdentityGateway implements CurrentUserGateway, SessionGateway {
  ApiIdentityGateway(this._dio);

  final Dio _dio;

  @override
  Future<Result<CurrentUser>> currentUser() =>
      _user(() => _dio.get<Object?>('/auth/me'));

  @override
  Future<Result<CurrentUser>> logIn(LoginCredentials credentials) => _user(
    () => _dio.post<Object?>(
      '/auth/login',
      data: {
        'email': credentials.email.trim(),
        'password': credentials.password,
      },
    ),
  );

  @override
  Future<Result<void>> logOut() async {
    try {
      await _dio.post<Object?>('/auth/logout');
      return const Success<void>(null);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }

  Future<Result<CurrentUser>> _user(
    Future<Response<Object?>> Function() call,
  ) async {
    try {
      final response = await call();
      final user = currentUserFromJson(response.data);
      return user == null ? Failure(ApiFailure.unknown()) : Success(user);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}

/// Maps the API's `{id, name, email, role}` to a [CurrentUser]; null when the body is not usable.
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
