import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/repository/password_repository.dart';

/// Request a password reset link by email (RIT-US-23).
final class RequestPasswordReset {
  const RequestPasswordReset(this._repository);

  final PasswordRepository _repository;

  Future<Result<void>> call(String email) =>
      _repository.requestPasswordReset(email);
}
