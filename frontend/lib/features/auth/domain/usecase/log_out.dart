import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/repository/session_repository.dart';

/// Use case: log out (the backend ends the session and clears its cookies).
final class LogOut {
  const LogOut(this._repository);

  final SessionRepository _repository;

  Future<Result<void>> call() => _repository.logOut();
}
