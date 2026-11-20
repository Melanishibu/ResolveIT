import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/entity/new_password.dart';
import 'package:resolveit/features/auth/domain/usecase/set_password.dart';

/// Coordinates the set-password screen's use case (RIT-US-07; password reset, RIT-US-23, reuses it).
final class PasswordInteractor {
  const PasswordInteractor(this._setPassword);

  final SetPassword _setPassword;

  Future<Result<void>> setPassword(NewPassword input) => _setPassword(input);
}
