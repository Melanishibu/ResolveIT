import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/app/router/app_router.dart';
import 'package:resolveit/app/shell/navigation_menu.dart';
import 'package:resolveit/features/auth/auth.dart';

import '../../support/auth_fakes.dart';

/// Bug AB#181: the route guard follows the permission table (Create incident: Admin and Employee),
/// not the role menu. The Admin menu has no Create Incident entry, but the Admin may open the page.
void main() {
  testWidgets('Admin reaches the create screen', (tester) async {
    await _pumpApp(tester, FakeIdentityBackend.signedInAs(Role.admin));

    _router(tester).go('/incidents/new');
    await tester.pumpAndSettle();

    expect(_router(tester).state.uri.path, '/incidents/new');
    expect(find.byKey(const Key('create-incident-title')), findsOneWidget);
    expect(find.byKey(const Key('not-allowed-page')), findsNothing);
  });

  testWidgets('Technician still gets "not allowed"', (tester) async {
    await _pumpApp(tester, FakeIdentityBackend.signedInAs(Role.supportAgent));

    _router(tester).go('/incidents/new');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-allowed-page')), findsOneWidget);
    expect(find.byKey(const Key('create-incident-title')), findsNothing);
  });

  group('sessionRedirect for /incidents/new', () {
    AsyncValue<CurrentUser?> signedInAs(Role role) =>
        AsyncData(CurrentUser(id: 'u', displayName: 'U', role: role));

    test('Admin and Employee may open it, Technician may not', () {
      expect(sessionRedirect(signedInAs(Role.admin), '/incidents/new'), isNull);
      expect(
        sessionRedirect(signedInAs(Role.employee), '/incidents/new'),
        isNull,
      );
      expect(
        sessionRedirect(signedInAs(Role.supportAgent), '/incidents/new'),
        '/not-allowed',
      );
    });

    test('the Admin menu still has no Create Incident entry (Update 01)', () {
      expect(
        menuFor(Role.admin),
        isNot(contains(MenuDestination.createIncident)),
      );
    });
  });
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

Future<void> _pumpApp(WidgetTester tester, FakeIdentityBackend backend) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserRepositoryProvider.overrideWithValue(backend),
        sessionRepositoryProvider.overrideWithValue(backend),
      ],
    ),
  );
  await tester.pumpAndSettle();
}
