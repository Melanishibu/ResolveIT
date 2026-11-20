import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/app/router/app_router.dart';
import 'package:resolveit/core/adapters/http/unauthorized_interceptor.dart';
import 'package:resolveit/features/identity/identity.dart';

import '../../support/identity_fakes.dart';

/// RIT-US-05 (AB#14) router scenarios, through the real composition root.
void main() {
  testWidgets('Router sends unauthenticated users to login', (tester) async {
    await _pumpApp(tester, FakeIdentityBackend.signedOut());

    _router(tester).go('/incidents');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-title')), findsOneWidget);
    expect(_router(tester).state.uri.path, '/login');
  });

  testWidgets('Router hides pages for other roles', (tester) async {
    await _pumpApp(tester, FakeIdentityBackend.signedInAs(Role.employee));

    _router(tester).go('/admin/users');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-allowed-page')), findsOneWidget);
    expect(find.text(l10nForbiddenTitle), findsOneWidget);
    expect(
      find.byKey(const Key('app-sidebar')),
      findsOneWidget,
      reason: 'the shell stays',
    );

    await tester.tap(find.byKey(const Key('not-allowed-back')));
    await tester.pumpAndSettle();
    expect(_router(tester).state.uri.path, '/dashboard');
  });

  testWidgets('A 401 from any API call returns to login', (tester) async {
    await _pumpApp(tester, FakeIdentityBackend.signedInAs(Role.admin));
    expect(find.byKey(const Key('app-sidebar')), findsOneWidget);

    ProviderScope.containerOf(
      tester.element(find.byKey(const Key('app-sidebar'))),
    ).read(sessionProvider.notifier).signedOut();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-title')), findsOneWidget);
  });

  group('sessionRedirect role guard', () {
    AsyncValue<CurrentUser?> signedInAs(Role role) =>
        AsyncData(CurrentUser(id: 'u', displayName: 'U', role: role));

    test('pages outside the role menu go to the not-allowed page', () {
      expect(
        sessionRedirect(signedInAs(Role.employee), '/admin/users'),
        '/not-allowed',
      );
      expect(
        sessionRedirect(signedInAs(Role.supportAgent), '/incidents'),
        '/not-allowed',
      );
      expect(
        sessionRedirect(signedInAs(Role.supportAgent), '/incidents/new'),
        '/not-allowed',
      );
    });

    test('pages in the role menu and unknown paths are left alone', () {
      expect(sessionRedirect(signedInAs(Role.admin), '/admin/users'), isNull);
      expect(
        sessionRedirect(signedInAs(Role.employee), '/incidents/new'),
        isNull,
      );
      expect(
        sessionRedirect(signedInAs(Role.employee), '/not-allowed'),
        isNull,
      );
      expect(sessionRedirect(signedInAs(Role.employee), '/nowhere'), isNull);
    });
  });

  test('UnauthorizedInterceptor reports 401 responses only', () async {
    var unauthorized = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'));
    final server = DioAdapter(dio: dio);
    dio.interceptors.add(UnauthorizedInterceptor(() => unauthorized++));
    server
      ..onGet('/expired', (s) => s.reply(401, {'code': 'AUTH_UNAUTHENTICATED'}))
      ..onGet('/forbidden', (s) => s.reply(403, {'code': 'AUTH_FORBIDDEN'}));

    await expectLater(
      dio.get<Object?>('/expired'),
      throwsA(isA<DioException>()),
    );
    await expectLater(
      dio.get<Object?>('/forbidden'),
      throwsA(isA<DioException>()),
    );

    expect(unauthorized, 1);
  });
}

const l10nForbiddenTitle = "You don't have access to this";

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

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
