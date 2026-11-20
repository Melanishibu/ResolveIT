import 'package:dio/dio.dart';
import 'package:resolveit/features/users/domain/entity/new_user.dart';

/// The user-management REST calls (`POST /users`, relative to the API base URL). Errors surface as
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
}

/// Data model: maps the API's created user; null when the body is not usable.
CreatedUser? createdUserFromJson(Object? data) {
  if (data is! Map) return null;
  final id = data['id'];
  final email = data['email'];
  if (id is! String || email is! String) return null;
  return CreatedUser(id: id, email: email);
}
