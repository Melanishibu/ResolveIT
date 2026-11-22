/// Public API of the auth feature (login, logout, current user). Other features and the app import
/// only this file.
library;

export 'package:resolveit/core/domain/role.dart';
export 'package:resolveit/features/auth/domain/entity/current_user.dart';
export 'package:resolveit/features/auth/domain/entity/login_credentials.dart';
export 'package:resolveit/features/auth/domain/repository/current_user_repository.dart';
export 'package:resolveit/features/auth/domain/repository/password_repository.dart';
export 'package:resolveit/features/auth/domain/repository/session_repository.dart';
export 'package:resolveit/features/auth/domain/usecase/change_password.dart';
export 'package:resolveit/features/auth/presentation/presenter/session_presenter.dart';
export 'package:resolveit/features/auth/presentation/router/auth_routes.dart';
export 'package:resolveit/features/auth/presentation/view/forgot_password_view.dart';
export 'package:resolveit/features/auth/presentation/view/login_view.dart';
export 'package:resolveit/features/auth/presentation/view/set_password_view.dart';
export 'package:resolveit/features/auth/providers.dart'
    show
        authHttpClientProvider,
        currentUserRepositoryProvider,
        sessionRepositoryProvider,
        passwordRepositoryProvider,
        changePasswordUseCaseProvider;
