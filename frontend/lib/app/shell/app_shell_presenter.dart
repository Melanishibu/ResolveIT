import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/features/identity/identity.dart';

/// Shell state: the signed-in user (drives the menu, the name and the avatar).
final appShellPresenterProvider =
    AsyncNotifierProvider<AppShellPresenter, CurrentUser>(
      AppShellPresenter.new,
    );

class AppShellPresenter extends AsyncNotifier<CurrentUser> {
  @override
  Future<CurrentUser> build() async {
    final user = await ref.watch(sessionProvider.future);
    // Signed out: the router is already on its way to /login.
    if (user == null) {
      throw ApiFailure(code: 'AUTH_UNAUTHENTICATED', httpStatus: 401);
    }
    return user;
  }

  /// Logout from the shell menu (AB#13).
  Future<void> logOut() => ref.read(sessionProvider.notifier).logOut();
}
