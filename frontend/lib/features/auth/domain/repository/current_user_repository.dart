import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/domain/entity/current_user.dart';

/// Outbound port: who is signed in.
abstract interface class CurrentUserRepository {
  Future<Result<CurrentUser>> currentUser();
}
