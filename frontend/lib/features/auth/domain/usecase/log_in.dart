import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/repository/session_repository.dart';
import 'package:resolveit/features/auth/domain/entity/current_user.dart';
import 'package:resolveit/features/auth/domain/entity/login_credentials.dart';

/// Use case: log in. Never sends a request while a required field is empty.
final class LogIn {
  const LogIn(this._repository);

  final SessionRepository _repository;

  Future<Result<CurrentUser>> call(LoginCredentials credentials) {
    final missing = credentials.missingFields;
    if (missing.isNotEmpty) {
      return Future.value(
        Failure(
          ApiFailure(
            code: 'VALIDATION_FAILED',
            params: {'fields': missing.map((field) => field.name).join(', ')},
            httpStatus: 400,
          ),
        ),
      );
    }
    return _repository.logIn(credentials);
  }
}
