import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/repository/password_repository.dart';

/// Changes the logged-in user's password (RIT-US-27).
final class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);

  final PasswordRepository _repository;

  Future<Result<void>> call({
    required String currentPassword,
    required String newPassword,
  }) => _repository.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );
}
