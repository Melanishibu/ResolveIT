import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/entity/current_user.dart';
import 'package:resolveit/features/auth/domain/entity/login_credentials.dart';
import 'package:resolveit/features/auth/domain/usecase/load_current_user.dart';
import 'package:resolveit/features/auth/domain/usecase/log_in.dart';
import 'package:resolveit/features/auth/domain/usecase/log_out.dart';

/// Coordinates the auth use cases for the session and login screens.
final class AuthInteractor {
  const AuthInteractor(this._loadCurrentUser, this._logIn, this._logOut);

  final LoadCurrentUser _loadCurrentUser;
  final LogIn _logIn;
  final LogOut _logOut;

  Future<Result<CurrentUser>> currentUser() => _loadCurrentUser();

  Future<Result<CurrentUser>> logIn(LoginCredentials credentials) =>
      _logIn(credentials);

  Future<Result<void>> logOut() => _logOut();
}
