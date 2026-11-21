import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/users/domain/entity/new_user.dart';
import 'package:resolveit/features/users/domain/usecase/create_user.dart';

/// Coordinates the create-user screen's use case (RIT-US-06).
final class CreateUserInteractor {
  const CreateUserInteractor(this._createUser);

  final CreateUser _createUser;

  Future<Result<CreatedUser>> createUser(NewUser user) => _createUser(user);
}
