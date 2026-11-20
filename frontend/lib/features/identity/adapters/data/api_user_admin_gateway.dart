import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/application/ports/user_admin_gateway.dart';
import 'package:resolveit/features/identity/domain/new_user.dart';

/// The user-management API (`POST /users`, relative to the API base URL).
final class ApiUserAdminGateway implements UserAdminGateway {
  ApiUserAdminGateway(this._dio);

  final Dio _dio;

  @override
  Future<Result<CreatedUser>> createUser(NewUser user) async {
    try {
      final response = await _dio.post<Object?>(
        '/users',
        data: {
          'name': user.name.trim(),
          'email': user.email.trim(),
          'role': user.role?.code,
          'department': user.department.trim(),
        },
      );
      final created = createdUserFromJson(response.data);
      return created == null ? Failure(ApiFailure.unknown()) : Success(created);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}

/// Maps the API's created user; null when the body is not usable.
CreatedUser? createdUserFromJson(Object? data) {
  if (data is! Map) return null;
  final id = data['id'];
  final email = data['email'];
  if (id is! String || email is! String) return null;
  return CreatedUser(id: id, email: email);
}
