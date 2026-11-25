import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/entity/current_user.dart';
import 'package:resolveit/features/auth/domain/entity/login_credentials.dart';

/// Outbound port: start and end a session (`POST /auth/login`, `POST /auth/logout`).
abstract interface class SessionRepository {
  Future<Result<CurrentUser>> logIn(LoginCredentials credentials);

  Future<Result<void>> logOut();
}
