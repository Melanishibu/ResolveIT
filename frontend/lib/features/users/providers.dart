import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/users/data/datasource/users_remote_datasource.dart';
import 'package:resolveit/features/users/data/repository/api_user_admin_repository.dart';
import 'package:resolveit/features/users/data/repository/api_user_profile_repository.dart';
import 'package:resolveit/features/users/domain/repository/user_admin_repository.dart';
import 'package:resolveit/features/users/domain/repository/user_directory_repository.dart';
import 'package:resolveit/features/users/domain/repository/user_profile_repository.dart';
import 'package:resolveit/features/users/domain/usecase/create_user.dart';
import 'package:resolveit/features/users/domain/usecase/get_my_profile.dart';
import 'package:resolveit/features/users/domain/usecase/manage_users.dart';
import 'package:resolveit/features/users/interactor/create_user_interactor.dart';
import 'package:resolveit/features/users/interactor/profile_interactor.dart';
import 'package:resolveit/features/users/interactor/user_list_interactor.dart';

/// The HTTP client of the user-management API. The composition root (`lib/app/app.dart`) binds it
/// to the shared API client; features never import the composition root.
final usersHttpClientProvider = Provider<Dio>(
  (ref) => throw StateError(
    'usersHttpClientProvider is bound by the composition root (ResolveItApp)',
  ),
);

/// User management for Admins (RIT-US-06). Tests override it with a fake.
final userAdminRepositoryProvider = Provider<UserAdminRepository>(
  (ref) => ApiUserAdminRepository(
    UsersRemoteDataSource(ref.watch(usersHttpClientProvider)),
  ),
);

/// What the create-user presenter calls.
final createUserInteractorProvider = Provider<CreateUserInteractor>(
  (ref) =>
      CreateUserInteractor(CreateUser(ref.watch(userAdminRepositoryProvider))),
);

/// The Admin's user list and activate/deactivate (RIT-US-08). Tests override it with a fake.
final userDirectoryRepositoryProvider = Provider<UserDirectoryRepository>(
  (ref) => ApiUserAdminRepository(
    UsersRemoteDataSource(ref.watch(usersHttpClientProvider)),
  ),
);

/// What the user-list presenter calls.
final userListInteractorProvider = Provider<UserListInteractor>((ref) {
  final repository = ref.watch(userDirectoryRepositoryProvider);
  return UserListInteractor(
    ListUsers(repository),
    ChangeUserStatus(repository),
    ResendInvitation(repository),
  );
});

/// My profile repository (RIT-US-27). Tests override it with a fake.
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => ApiUserProfileRepository(
    UsersRemoteDataSource(ref.watch(usersHttpClientProvider)),
  ),
);

/// Profile interactor (RIT-US-27).
final profileInteractorProvider = Provider<ProfileInteractor>((ref) {
  return ProfileInteractor(
    GetMyProfileUseCase(ref.watch(userProfileRepositoryProvider)),
    ref.watch(changePasswordUseCaseProvider),
  );
});
