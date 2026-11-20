import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/adapters/di/identity_providers.dart';
import 'package:resolveit/features/identity/domain/current_user.dart';

/// Who is signed in: a [CurrentUser], `null` when signed out, or an error when the backend can't
/// be reached. The router sends signed-out users to `/login`.
final sessionProvider = AsyncNotifierProvider<SessionPresenter, CurrentUser?>(
  SessionPresenter.new,
);

class SessionPresenter extends AsyncNotifier<CurrentUser?> {
  @override
  Future<CurrentUser?> build() async {
    final result = await ref.read(loadCurrentUserProvider)();
    return switch (result) {
      Success(:final value) => value,
      // 401: no valid session (never logged in, logged out, expired or deactivated).
      Failure(:final failure) when failure.httpStatus == 401 => null,
      Failure(:final failure) => throw failure,
    };
  }

  /// Called by the login screen after a successful login.
  void signedIn(CurrentUser user) => state = AsyncData(user);

  /// Ends the session. The user is signed out locally even if the call fails.
  Future<void> logOut() async {
    await ref.read(logOutProvider)();
    state = const AsyncData(null);
  }
}
