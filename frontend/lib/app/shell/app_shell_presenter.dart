import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/identity.dart';

/// Shell state: the signed-in user (drives the menu and the avatar).
final appShellPresenterProvider =
    AsyncNotifierProvider<AppShellPresenter, CurrentUser>(
      AppShellPresenter.new,
    );

class AppShellPresenter extends AsyncNotifier<CurrentUser> {
  @override
  Future<CurrentUser> build() async {
    final result = await ref.read(loadCurrentUserProvider)();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final failure) => throw failure,
    };
  }
}
