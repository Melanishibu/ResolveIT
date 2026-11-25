import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:resolveit/app/router/app_router.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:resolveit/features/auth/data/repository/api_auth_repository.dart';
import 'package:resolveit/features/auth/domain/usecase/log_in.dart';
import 'package:resolveit/features/auth/auth.dart';

void main() {
  late Dio dio;
  late DioAdapter server;
  late ApiAuthRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'));
    server = DioAdapter(dio: dio);
    repository = ApiAuthRepository(AuthRemoteDataSource(dio));
  });

  group('ApiAuthRepository', () {
    test(
      'GET /auth/me maps {id, name, email, role} to the current user',
      () async {
        server.onGet(
          '/auth/me',
          (s) => s.reply(200, {
            'id': '00000000-0000-4000-8000-000000000004',
            'name': 'Employee One',
            'email': 'employee1@resolveit.local',
            'role': 'EMPLOYEE',
          }),
        );

        final result = await repository.currentUser();

        expect(result, isA<Success<CurrentUser>>());
        final user = (result as Success<CurrentUser>).value;
        expect(user.displayName, 'Employee One');
        expect(user.role, Role.employee);
      },
    );

    test(
      'GET /auth/me without a session is a 401 AUTH_UNAUTHENTICATED failure',
      () async {
        server.onGet(
          '/auth/me',
          (s) => s.reply(401, {
            'code': 'AUTH_UNAUTHENTICATED',
            'params': <String, Object>{},
          }),
        );

        final result = await repository.currentUser();

        final failure = (result as Failure<CurrentUser>).failure;
        expect(failure.code, 'AUTH_UNAUTHENTICATED');
        expect(failure.httpStatus, 401);
      },
    );

    test(
      'POST /auth/login sends the trimmed email and maps refusals',
      () async {
        server.onPost(
          '/auth/login',
          (s) => s.reply(401, {
            'code': 'AUTH_INVALID_CREDENTIALS',
            'params': <String, Object>{},
          }),
          data: {'email': 'employee1@resolveit.local', 'password': 'Wrong-1'},
        );

        final result = await repository.logIn(
          const LoginCredentials(
            email: ' employee1@resolveit.local ',
            password: 'Wrong-1',
          ),
        );

        expect(
          (result as Failure<CurrentUser>).failure.code,
          'AUTH_INVALID_CREDENTIALS',
        );
      },
    );

    test(
      'an unusable body is reported as an unknown error, never as a user',
      () {
        expect(
          currentUserFromJson({'id': 'x', 'name': 'A', 'role': 'ROOT'}),
          isNull,
        );
        expect(currentUserFromJson('nonsense'), isNull);
      },
    );
  });

  group('LoginCredentials and LogIn', () {
    test('blank fields are missing and no request is sent', () async {
      final calls = <LoginCredentials>[];
      final logIn = LogIn(_RecordingSession(calls));

      final result = await logIn(
        const LoginCredentials(email: '  ', password: ''),
      );

      expect(const LoginCredentials(email: ' ', password: '').missingFields, {
        LoginField.email,
        LoginField.password,
      });
      expect(
        (result as Failure<CurrentUser>).failure.code,
        'VALIDATION_FAILED',
      );
      expect(calls, isEmpty);
      expect(
        const LoginCredentials(email: 'a@b.c', password: 'secret').toString(),
        isNot(contains('secret')),
      );
    });
  });

  group('sessionRedirect', () {
    final user = CurrentUser(
      id: 'u-1',
      displayName: 'Employee One',
      role: Role.employee,
    );

    test('signed-out users go to /login; dev routes stay reachable', () {
      expect(sessionRedirect(const AsyncData(null), '/incidents'), '/login');
      expect(sessionRedirect(const AsyncData(null), '/login'), isNull);
      expect(sessionRedirect(const AsyncData(null), '/dev/components'), isNull);
    });

    test('signed-in users leave /login for the dashboard', () {
      expect(sessionRedirect(AsyncData(user), '/login'), '/dashboard');
      expect(sessionRedirect(AsyncData(user), '/my-incidents'), isNull);
    });

    test(
      'while loading or when the backend is unreachable nothing redirects',
      () {
        expect(sessionRedirect(const AsyncLoading(), '/incidents'), isNull);
        expect(
          sessionRedirect(
            AsyncError(Exception('offline'), StackTrace.empty),
            '/incidents',
          ),
          isNull,
        );
      },
    );
  });
}

final class _RecordingSession implements SessionRepository {
  _RecordingSession(this.calls);

  final List<LoginCredentials> calls;

  @override
  Future<Result<CurrentUser>> logIn(LoginCredentials credentials) async {
    calls.add(credentials);
    return Success(CurrentUser(id: 'u', displayName: 'U', role: Role.employee));
  }

  @override
  Future<Result<void>> logOut() async => const Success<void>(null);
}
