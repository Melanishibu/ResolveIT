import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/features/identity/identity.dart';

import '../support/test_app.dart';

// Scenario: App starts in the browser
//   When I run flutter run -d chrome
//   Then the ResolveIT shell opens without errors
//
// This widget test starts the real composition root. The run in Chrome itself is recorded in
// the Evidence comment (flutter run -d chrome --web-port 5000, flutter build web).
void main() {
  testWidgets('App starts in the browser', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // AB#13 removed the placeholder user: the signed-in "Dev User" now comes from a fake gateway.
    await tester.pumpWidget(
      ResolveItApp(
        overrides: [
          currentUserGatewayProvider.overrideWithValue(
            FakeCurrentUserGateway.signedInAs(
              Role.admin,
              displayName: 'Dev User',
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('app-sidebar')), findsOneWidget);
    expect(find.text(l10nEn.appBrand), findsOneWidget);
    expect(find.byKey(const Key('page-title')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('page-title'))).data,
      l10nEn.menuDashboard,
      reason: 'the shell opens on the dashboard',
    );
    expect(find.byKey(const Key('user-avatar')), findsOneWidget);
    expect(
      find.text('DU'),
      findsOneWidget,
      reason: 'placeholder Dev User initials',
    );
    expect(find.byKey(const Key('menu-item-logout')), findsOneWidget);
  });
}
