import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/data/datasource/users_remote_datasource.dart';
import 'package:resolveit/features/users/domain/entity/new_user.dart';
import 'package:resolveit/features/users/domain/entity/user_summary.dart';
import 'package:resolveit/features/users/domain/repository/user_admin_repository.dart';
import 'package:resolveit/features/users/domain/repository/user_directory_repository.dart';

/// Implements the user-management contracts on the REST API; API errors become [Failure]s.
final class ApiUserAdminRepository
    implements UserAdminRepository, UserDirectoryRepository {
  ApiUserAdminRepository(this._remote);

  final UsersRemoteDataSource _remote;

  @override
  Future<Result<CreatedUser>> createUser(NewUser user) =>
      _call(() => _remote.createUser(user), createdUserFromJson);

  @override
  Future<Result<UserPage>> listUsers(UserListFilter filter) =>
      _call(() => _remote.listUsers(filter), userPageFromJson);

  @override
  Future<Result<UserSummary>> setActive(
    String userId, {
    required bool active,
  }) => _call(
    () => _remote.setActive(userId, active: active),
    userSummaryFromJson,
  );

  @override
  Future<Result<UserSummary>> resendInvitation(String userId) =>
      _call(() => _remote.resendInvitation(userId), userSummaryFromJson);

  Future<Result<T>> _call<T>(
    Future<Object?> Function() request,
    T? Function(Object? body) map,
  ) async {
    try {
      final value = map(await request());
      return value == null ? Failure(ApiFailure.unknown()) : Success(value);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}
