import 'package:resolveit/core/domain/result.dart';

/// Contract: set a password from a one-time link (`POST /auth/password/set`, RIT-US-07).
abstract interface class PasswordRepository {
  Future<Result<void>> setPassword({
    required String token,
    required String newPassword,
  });
}
