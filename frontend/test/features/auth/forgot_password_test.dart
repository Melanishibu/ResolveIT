import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';

import '../../support/auth_fakes.dart';
import '../../support/test_app.dart';

void main() {
  testWidgets('User requests password reset successfully', (tester) async {
    final passwords = FakePasswords();
    await _openForgotPassword(tester, passwords);

    expect(find.byKey(const Key('forgot-password-card')), findsOneWidget);
    expect(find.text(l10nEn.forgotPasswordTitle), findsOneWidget);

    await _enter(tester, 'forgot-password-email', 'employee1@resolveit.local');
    await tester.tap(find.byKey(const Key('forgot-password-submit')));
    await tester.pumpAndSettle();

    expect(passwords.resetCalls.single, 'employee1@resolveit.local');
    expect(find.text(l10nEn.forgotPasswordSuccessTitle), findsOneWidget);
    expect(find.text(l10nEn.forgotPasswordSuccessMessage), findsOneWidget);

    await tester.tap(find.byKey(const Key('forgot-password-back-button')));
    await tester.pumpAndSettle();

    expect(_router(tester).state.uri.path, '/login');
  });

  testWidgets(
    'Login page contains Forgot password? link that navigates to /forgot-password',
    (tester) async {
      final backend = FakeIdentityBackend.signedOut();
      await tester.pumpWidget(
        ResolveItApp(
          overrides: [
            currentUserRepositoryProvider.overrideWithValue(backend),
            sessionRepositoryProvider.overrideWithValue(backend),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login-forgot-password')), findsOneWidget);
      await tester.tap(find.byKey(const Key('login-forgot-password')));
      await tester.pumpAndSettle();

      expect(_router(tester).state.uri.path, '/forgot-password');
      expect(find.byKey(const Key('forgot-password-card')), findsOneWidget);
    },
  );

  testWidgets('Empty email shows required validation error', (tester) async {
    final passwords = FakePasswords();
    await _openForgotPassword(tester, passwords);

    await tester.tap(find.byKey(const Key('forgot-password-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.forgotPasswordEmailRequired), findsOneWidget);
    expect(passwords.resetCalls, isEmpty);
  });

  testWidgets('Backend error is shown via ErrorPanel', (tester) async {
    final passwords = FakePasswords(
      failure: ApiFailure(code: 'AUTH_CSRF_INVALID', httpStatus: 403),
    );
    await _openForgotPassword(tester, passwords);

    await _enter(tester, 'forgot-password-email', 'employee1@resolveit.local');
    await tester.tap(find.byKey(const Key('forgot-password-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('forgot-password-error')), findsOneWidget);
    expect(find.text(l10nEn.errorAuthCsrfInvalidTitle), findsOneWidget);
  });
}

final class FakePasswords implements PasswordRepository {
  FakePasswords({this.failure});

  final ApiFailure? failure;
  final resetCalls = <String>[];

  @override
  Future<Result<void>> setPassword({
    required String token,
    required String newPassword,
  }) async => const Success(null);

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => const Success(null);

  @override
  Future<Result<void>> requestPasswordReset(String email) async {
    final refused = failure;
    if (refused != null) return Failure(refused);
    resetCalls.add(email);
    return const Success(null);
  }
}

Future<void> _openForgotPassword(
  WidgetTester tester,
  FakePasswords passwords,
) async {
  final backend = FakeIdentityBackend.signedOut();
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
  _router(tester).go('/forgot-password');
  await tester.pumpAndSettle();
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
