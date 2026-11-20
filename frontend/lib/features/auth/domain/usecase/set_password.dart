import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/entity/new_password.dart';
import 'package:resolveit/features/auth/domain/repository/password_repository.dart';

/// Use case: set a password from a one-time link. Never sends a request while a field is empty or the
/// two entries differ.
final class SetPassword {
  const SetPassword(this._repository);

  final PasswordRepository _repository;

  Future<Result<void>> call(NewPassword input) {
    final problems = input.problems;
    if (problems.isNotEmpty) {
      return Future.value(
        Failure(
          ApiFailure(
            code: 'VALIDATION_FAILED',
            params: {'fields': problems.map((p) => p.name).join(', ')},
            httpStatus: 400,
          ),
        ),
      );
    }
    return _repository.setPassword(
      token: input.token,
      newPassword: input.password,
    );
  }
}
