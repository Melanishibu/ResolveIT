import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/application/ports/user_admin_gateway.dart';
import 'package:resolveit/features/identity/domain/new_user.dart';

/// Use case: an Admin creates a Technician or Employee. Never sends a request with a required field empty.
final class CreateUser {
  const CreateUser(this._gateway);

  final UserAdminGateway _gateway;

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
    return _gateway.createUser(user);
  }
}
