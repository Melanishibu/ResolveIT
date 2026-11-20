import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/domain/current_user.dart';
import 'package:resolveit/features/identity/domain/login_credentials.dart';

/// Outbound port: start and end a session (`POST /auth/login`, `POST /auth/logout`).
abstract interface class SessionGateway {
  Future<Result<CurrentUser>> logIn(LoginCredentials credentials);

  Future<Result<void>> logOut();
}
