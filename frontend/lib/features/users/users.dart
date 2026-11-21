/// Public API of the users feature (user management). Other features and the app import only this
/// file.
library;

export 'package:resolveit/core/domain/role.dart';
export 'package:resolveit/features/users/domain/entity/new_user.dart';
export 'package:resolveit/features/users/domain/entity/user_summary.dart';
export 'package:resolveit/features/users/domain/repository/user_admin_repository.dart';
export 'package:resolveit/features/users/domain/repository/user_directory_repository.dart';
export 'package:resolveit/features/users/presentation/router/users_routes.dart';
export 'package:resolveit/features/users/presentation/view/create_user_view.dart';
export 'package:resolveit/features/users/presentation/view/user_list_view.dart';
export 'package:resolveit/features/users/providers.dart'
    show
        usersHttpClientProvider,
        userAdminRepositoryProvider,
        userDirectoryRepositoryProvider;
export 'package:resolveit/features/users/widgets/active_chip.dart';
export 'package:resolveit/features/users/widgets/role_chip.dart';
export 'package:resolveit/features/users/widgets/role_label.dart';
