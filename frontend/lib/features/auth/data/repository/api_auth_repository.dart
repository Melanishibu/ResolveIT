import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:resolveit/features/auth/domain/entity/current_user.dart';
import 'package:resolveit/features/auth/domain/entity/login_credentials.dart';
import 'package:resolveit/features/auth/domain/repository/current_user_repository.dart';
import 'package:resolveit/features/auth/domain/repository/session_repository.dart';

/// Implements both auth contracts on the auth REST API; API errors become [Failure]s.
final class ApiAuthRepository
    implements CurrentUserRepository, SessionRepository {
  ApiAuthRepository(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Result<CurrentUser>> currentUser() => _user(_remote.me);

  @override
  Future<Result<CurrentUser>> logIn(LoginCredentials credentials) => _user(
    () => _remote.logIn(
      email: credentials.email.trim(),
      password: credentials.password,
    ),
  );

  @override
  Future<Result<void>> logOut() async {
    try {
      await _remote.logOut();
      return const Success<void>(null);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }

  Future<Result<CurrentUser>> _user(Future<Object?> Function() call) async {
    try {
      final user = currentUserFromJson(await call());
      return user == null ? Failure(ApiFailure.unknown()) : Success(user);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}
