import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/identity.dart';

import '../../support/identity_fakes.dart';
import '../../support/test_app.dart';

/// RIT-US-04 (AB#13) UI scenarios, through the real composition root with a fake identity backend.
void main() {
  testWidgets('TC-001 Login with valid credentials', (tester) async {
    final backend = FakeIdentityBackend.signedOut();
    await _pumpApp(tester, backend);
    expect(find.byKey(const Key('login-title')), findsOneWidget);

    await _enter(tester, 'login-email', ' employee1@resolveit.local ');
    await _enter(tester, 'login-password', 'ResolveIT-Dev-2026');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(backend.logInCalls, 1);
    expect(backend.lastCredentials?.email, ' employee1@resolveit.local ');
    expect(
      tester.widget<Text>(find.byKey(const Key('page-title'))).data,
      l10nEn.menuDashboard,
      reason: 'they land on the dashboard',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('current-user-name'))).data,
      'Employee One',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('current-role'))).data,
      l10nEn.roleEmployee,
    );
    expect(find.byKey(const Key('login-title')), findsNothing);
  });

  testWidgets('TC-002 Login with invalid credentials', (tester) async {
    final backend = FakeIdentityBackend.signedOut(
      loginFailure: ApiFailure(
        code: 'AUTH_INVALID_CREDENTIALS',
        httpStatus: 401,
      ),
    );
    await _pumpApp(tester, backend);

    await _enter(tester, 'login-email', 'employee1@resolveit.local');
    await _enter(tester, 'login-password', 'Wrong-Password-1');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-error')), findsOneWidget);
    expect(find.text(l10nEn.errorAuthInvalidCredentialsTitle), findsOneWidget);
    expect(
      l10nEn.errorAuthInvalidCredentialsTitle,
      'Email or password is incorrect',
    );
    for (final text in [
      l10nEn.errorAuthInvalidCredentialsTitle,
      l10nEn.errorAuthInvalidCredentialsWhy,
    ]) {
      expect(text.toLowerCase(), isNot(contains('wrong password')));
      expect(text.toLowerCase(), isNot(contains('unknown email')));
    }
    expect(
      find.byKey(const Key('login-title')),
      findsOneWidget,
      reason: 'still on the login screen',
    );
  });

  testWidgets('Email and password are mandatory', (tester) async {
    final backend = FakeIdentityBackend.signedOut();
    await _pumpApp(tester, backend);

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.loginEmailRequired), findsOneWidget);
    expect(find.text(l10nEn.loginPasswordRequired), findsOneWidget);

    await _enter(tester, 'login-email', 'employee1@resolveit.local');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.loginEmailRequired), findsNothing);
    expect(find.text(l10nEn.loginPasswordRequired), findsOneWidget);
    expect(backend.logInCalls, 0, reason: 'no request is sent');
  });

  testWidgets('Logout ends the session', (tester) async {
    final backend = FakeIdentityBackend.signedInAs(Role.supportAgent);
    await _pumpApp(tester, backend);
    expect(find.byKey(const Key('app-sidebar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('menu-item-logout')));
    await tester.pumpAndSettle();

    expect(backend.logOutCalls, 1);
    expect(
      find.byKey(const Key('login-title')),
      findsOneWidget,
      reason: 'the login screen is shown',
    );
    expect(find.byKey(const Key('app-sidebar')), findsNothing);
    expect(
      await backend.currentUser(),
      isA<Failure<CurrentUser>>(),
      reason: 'GET /auth/me now answers 401',
    );
  });

  testWidgets('A locked account shows how long to wait', (tester) async {
    final backend = FakeIdentityBackend.signedOut(
      loginFailure: ApiFailure(
        code: 'AUTH_LOGIN_TEMPORARILY_BLOCKED',
        params: const {'retryAfterMinutes': '12'},
        httpStatus: 429,
      ),
    );
    await _pumpApp(tester, backend);

    await _enter(tester, 'login-email', 'employee2@resolveit.local');
    await _enter(tester, 'login-password', 'ResolveIT-Dev-2026');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text(l10nEn.errorAuthLoginTemporarilyBlockedTitle),
      findsOneWidget,
    );
    expect(
      find.text(l10nEn.errorAuthLoginTemporarilyBlockedWhy('12')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpApp(WidgetTester tester, FakeIdentityBackend backend) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserGatewayProvider.overrideWithValue(backend),
        sessionGatewayProvider.overrideWithValue(backend),
      ],
    ),
  );
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
