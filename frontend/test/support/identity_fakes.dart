import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/identity.dart';

/// An in-memory identity backend: answers like the real API (401 when signed out).
final class FakeIdentityBackend implements CurrentUserGateway, SessionGateway {
  FakeIdentityBackend.signedOut({this.loginFailure}) : _user = null;

  FakeIdentityBackend.signedInAs(Role role)
    : loginFailure = null,
      _user = CurrentUser(id: 'u-2', displayName: 'Agent One', role: role);

  final ApiFailure? loginFailure;
  CurrentUser? _user;
  int logInCalls = 0;
  int logOutCalls = 0;
  LoginCredentials? lastCredentials;

  static final _unauthenticated = ApiFailure(
    code: 'AUTH_UNAUTHENTICATED',
    httpStatus: 401,
  );

  @override
  Future<Result<CurrentUser>> currentUser() async {
    final user = _user;
    return user == null ? Failure(_unauthenticated) : Success(user);
  }

  @override
  Future<Result<CurrentUser>> logIn(LoginCredentials credentials) async {
    logInCalls++;
    lastCredentials = credentials;
    final failure = loginFailure;
    if (failure != null) return Failure(failure);
    final user = CurrentUser(
      id: 'u-1',
      displayName: 'Employee One',
      role: Role.employee,
    );
    _user = user;
    return Success(user);
  }

  @override
  Future<Result<void>> logOut() async {
    logOutCalls++;
    _user = null;
    return const Success<void>(null);
  }
}
