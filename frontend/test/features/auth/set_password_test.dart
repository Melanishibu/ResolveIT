import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:resolveit/features/auth/data/repository/api_auth_repository.dart';

import '../../support/auth_fakes.dart';
import '../../support/test_app.dart';

/// RIT-US-07 (AB#49) set-password screen, through the real composition root, signed out.
void main() {
  testWidgets('User sets a password from a valid link', (tester) async {
    final passwords = FakePasswords();
    await _openLink(tester, passwords, token: 'tok-123');

    expect(find.text(l10nEn.setPasswordPolicy), findsOneWidget);
    await _enter(tester, 'set-password-new', 'Welcome2026Asha');
    await _enter(tester, 'set-password-confirm', 'Welcome2026Asha');
    await tester.tap(find.byKey(const Key('set-password-submit')));
    await tester.pumpAndSettle();

    expect(passwords.calls.single, ('tok-123', 'Welcome2026Asha'));
    expect(find.text(l10nEn.setPasswordSuccess), findsOneWidget);
    expect(
      _router(tester).state.uri.path,
      '/login',
      reason: 'no automatic login',
    );
  });

  testWidgets('Link works only once', (tester) async {
    await _openLink(
      tester,
      FakePasswords(
        failure: ApiFailure(code: 'AUTH_TOKEN_INVALID', httpStatus: 400),
      ),
      token: 'used',
    );

    await _fillMatching(tester);
    await tester.tap(find.byKey(const Key('set-password-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.errorAuthTokenInvalidTitle), findsOneWidget);
  });

  testWidgets('Expired link is rejected', (tester) async {
    await _openLink(
      tester,
      FakePasswords(
        failure: ApiFailure(code: 'AUTH_TOKEN_EXPIRED', httpStatus: 400),
      ),
      token: 'old',
    );

    await _fillMatching(tester);
    await tester.tap(find.byKey(const Key('set-password-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.errorAuthTokenExpiredTitle), findsOneWidget);
    expect(
      find.text(l10nEn.errorAuthTokenExpiredNextStep),
      findsOneWidget,
      reason: 'the screen says to ask the Admin for a new invitation',
    );
  });

  testWidgets('Weak password is rejected', (tester) async {
    await _openLink(
      tester,
      FakePasswords(
        failure: ApiFailure(code: 'PASSWORD_POLICY_VIOLATION', httpStatus: 400),
      ),
      token: 'tok',
    );

    await _enter(tester, 'set-password-new', 'short1');
    await _enter(tester, 'set-password-confirm', 'short1');
    await tester.tap(find.byKey(const Key('set-password-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.errorPasswordPolicyViolationTitle), findsOneWidget);
    expect(
      find.text(l10nEn.errorPasswordPolicyViolationWhy),
      findsOneWidget,
      reason: 'the policy is shown',
    );
  });

  testWidgets('Passwords must match', (tester) async {
    final passwords = FakePasswords();
    await _openLink(tester, passwords, token: 'tok');

    await _enter(tester, 'set-password-new', 'Welcome2026Asha');
    await _enter(tester, 'set-password-confirm', 'Welcome2026Asho');
    await tester.tap(find.byKey(const Key('set-password-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.setPasswordMismatch), findsOneWidget);
    expect(passwords.calls, isEmpty, reason: 'no request is sent');
  });

  testWidgets('A link without a token explains itself and cannot be sent', (
    tester,
  ) async {
    await _openLink(tester, FakePasswords(), token: null);

    expect(find.text(l10nEn.errorAuthTokenInvalidTitle), findsOneWidget);
    final button = tester.widget<AppButton>(
      find.byKey(const Key('set-password-submit')),
    );
    expect(button.onPressed, isNull);
  });

  group('ApiAuthRepository.setPassword', () {
    test(
      'fetches the CSRF cookie, then posts the token and password',
      () async {
        final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'));
        final server = DioAdapter(dio: dio);
        server
          ..onGet('/auth/csrf', (s) => s.reply(204, null))
          ..onPost(
            '/auth/password/set',
            (s) => s.reply(204, null),
            data: {'token': 'tok-1', 'newPassword': 'Welcome2026Asha'},
          );

        final result = await ApiAuthRepository(
          AuthRemoteDataSource(dio),
        ).setPassword(token: 'tok-1', newPassword: 'Welcome2026Asha');

        expect(result, isA<Success<void>>());
      },
    );

    test('a refusal becomes the Problem Details failure', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'));
      DioAdapter(dio: dio)
        ..onGet('/auth/csrf', (s) => s.reply(204, null))
        ..onPost(
          '/auth/password/set',
          (s) => s.reply(400, {'code': 'AUTH_TOKEN_EXPIRED', 'title': 'x'}),
          data: Matchers.any,
        );

      final result = await ApiAuthRepository(
        AuthRemoteDataSource(dio),
      ).setPassword(token: 't', newPassword: 'p');

      expect((result as Failure<void>).failure.code, 'AUTH_TOKEN_EXPIRED');
    });
  });
}

final class FakePasswords implements PasswordRepository {
  FakePasswords({this.failure});

  final ApiFailure? failure;
  final calls = <(String, String)>[];

  @override
  Future<Result<void>> setPassword({
    required String token,
    required String newPassword,
  }) async {
    final refused = failure;
    if (refused != null) return Failure(refused);
    calls.add((token, newPassword));
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final refused = failure;
    if (refused != null) return Failure(refused);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> requestPasswordReset(String email) async {
    final refused = failure;
    if (refused != null) return Failure(refused);
    return const Success<void>(null);
  }
}

Future<void> _openLink(
  WidgetTester tester,
  FakePasswords passwords, {
  required String? token,
}) async {
  final backend = FakeIdentityBackend.signedOut();
  tester.view.physicalSize = const Size(1440, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserRepositoryProvider.overrideWithValue(backend),
        sessionRepositoryProvider.overrideWithValue(backend),
        passwordRepositoryProvider.overrideWithValue(passwords),
      ],
    ),
  );
  await tester.pumpAndSettle();
  _router(
    tester,
  ).go(token == null ? '/set-password' : '/set-password?token=$token');
  await tester.pumpAndSettle();
  expect(
    find.byKey(const Key('set-password-title')),
    findsOneWidget,
    reason: 'reachable while signed out',
  );
}

Future<void> _fillMatching(WidgetTester tester) async {
  await _enter(tester, 'set-password-new', 'Welcome2026Asha');
  await _enter(tester, 'set-password-confirm', 'Welcome2026Asha');
}

Future<void> _enter(WidgetTester tester, String fieldKey, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(Key(fieldKey)),
      matching: find.byType(EditableText),
    ),
    text,
  );
  await tester.pump();
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));
