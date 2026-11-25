import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/domain/repository/user_admin_repository.dart';
import 'package:resolveit/features/users/domain/entity/new_user.dart';

/// Use case: an Admin creates a Technician or Employee. Never sends a request with a required field empty.
final class CreateUser {
  const CreateUser(this._repository);

  final UserAdminRepository _repository;

  Future<Result<CreatedUser>> call(NewUser user) {
    final missing = user.missingFields;
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
    return _repository.createUser(user);
  }
}
