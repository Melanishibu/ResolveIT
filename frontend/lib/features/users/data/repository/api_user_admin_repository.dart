import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/data/datasource/users_remote_datasource.dart';
import 'package:resolveit/features/users/domain/entity/new_user.dart';
import 'package:resolveit/features/users/domain/repository/user_admin_repository.dart';

/// Implements [UserAdminRepository] on the user-management REST API; API errors become [Failure]s.
final class ApiUserAdminRepository implements UserAdminRepository {
  ApiUserAdminRepository(this._remote);

  final UsersRemoteDataSource _remote;

  @override
  Future<Result<CreatedUser>> createUser(NewUser user) async {
    try {
      final created = createdUserFromJson(await _remote.createUser(user));
      return created == null ? Failure(ApiFailure.unknown()) : Success(created);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}
