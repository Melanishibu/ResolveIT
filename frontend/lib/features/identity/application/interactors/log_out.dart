import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/application/ports/session_gateway.dart';

/// Use case: log out (the backend ends the session and clears its cookies).
final class LogOut {
  const LogOut(this._gateway);

  final SessionGateway _gateway;

  Future<Result<void>> call() => _gateway.logOut();
}
