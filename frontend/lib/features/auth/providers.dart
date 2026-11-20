import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:resolveit/features/auth/data/repository/api_auth_repository.dart';
import 'package:resolveit/features/auth/domain/repository/current_user_repository.dart';
import 'package:resolveit/features/auth/domain/repository/session_repository.dart';
import 'package:resolveit/features/auth/domain/usecase/load_current_user.dart';
import 'package:resolveit/features/auth/domain/usecase/log_in.dart';
import 'package:resolveit/features/auth/domain/usecase/log_out.dart';
import 'package:resolveit/features/auth/interactor/auth_interactor.dart';

/// The HTTP client of the auth API. The composition root (`lib/app/app.dart`) binds it to the
/// shared API client; features never import the composition root.
final authHttpClientProvider = Provider<Dio>(
  (ref) => throw StateError(
    'authHttpClientProvider is bound by the composition root (ResolveItApp)',
  ),
);

/// One API repository serves both auth contracts (AB#13).
final apiAuthRepositoryProvider = Provider<ApiAuthRepository>(
  (ref) => ApiAuthRepository(
    AuthRemoteDataSource(ref.watch(authHttpClientProvider)),
  ),
);

/// Who is signed in (`GET /auth/me`). Tests override it with a fake.
final currentUserRepositoryProvider = Provider<CurrentUserRepository>(
  (ref) => ref.watch(apiAuthRepositoryProvider),
);

/// Log in and log out. Tests override it with a fake.
final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => ref.watch(apiAuthRepositoryProvider),
);

/// What the session and login presenters call.
final authInteractorProvider = Provider<AuthInteractor>(
  (ref) => AuthInteractor(
    LoadCurrentUser(ref.watch(currentUserRepositoryProvider)),
    LogIn(ref.watch(sessionRepositoryProvider)),
    LogOut(ref.watch(sessionRepositoryProvider)),
  ),
);
