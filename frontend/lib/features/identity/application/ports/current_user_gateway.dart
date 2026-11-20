import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/domain/current_user.dart';

/// Outbound port: who is signed in.
abstract interface class CurrentUserGateway {
  Future<Result<CurrentUser>> currentUser();
}
