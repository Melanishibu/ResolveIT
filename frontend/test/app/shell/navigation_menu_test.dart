import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/app/shell/navigation_menu.dart';
import 'package:resolveit/app/theme/app_colors.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/identity.dart';

import '../../support/test_app.dart';

Future<void> _pumpShellAs(
  WidgetTester tester,
  CurrentUserGateway gateway,
) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [currentUserGatewayProvider.overrideWithValue(gateway)],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('menuFor (Update 01 menus)', () {
    test('Admin: Dashboard, Incidents, User Management, Profile', () {
      expect(menuFor(Role.admin), [
        MenuDestination.dashboard,
        MenuDestination.incidents,
        MenuDestination.userManagement,
        MenuDestination.profile,
      ]);
    });

    test('Technician: Dashboard, My Incidents, Profile', () {
      expect(menuFor(Role.supportAgent), [
        MenuDestination.dashboard,
        MenuDestination.myIncidents,
        MenuDestination.profile,
      ]);
    });

    test('Employee: Dashboard, My Incidents, Create Incident, Profile', () {
      expect(menuFor(Role.employee), [
        MenuDestination.dashboard,
        MenuDestination.myIncidents,
        MenuDestination.createIncident,
        MenuDestination.profile,
      ]);
    });

    test('the active item is the longest matching path', () {
      expect(
        MenuDestination.forLocation('/incidents/new'),
        MenuDestination.createIncident,
      );
      expect(
        MenuDestination.forLocation('/incidents'),
        MenuDestination.incidents,
      );
      expect(MenuDestination.forLocation('/nowhere'), isNull);
    });
  });

  group('app shell', () {
    testWidgets('shows SUPPORT_AGENT as Technician with the Technician menu', (
      tester,
    ) async {
      await _pumpShellAs(
        tester,
        FakeCurrentUserGateway.signedInAs(Role.supportAgent),
      );

      expect(find.byKey(const Key('current-role')), findsOneWidget);
      expect(find.text(l10nEn.roleSupportAgent), findsOneWidget);
      expect(l10nEn.roleSupportAgent, 'Technician');
      expect(find.textContaining('SUPPORT_AGENT'), findsNothing);
      expect(find.text(l10nEn.menuMyIncidents), findsOneWidget);
      expect(find.text(l10nEn.menuUserManagement), findsNothing);
      expect(find.text(l10nEn.menuCreateIncident), findsNothing);
      expect(find.text(l10nEn.menuLogout), findsOneWidget);
      expect(find.text('SJ'), findsOneWidget);
    });

    testWidgets('navigates from the menu and highlights the new item', (
      tester,
    ) async {
      await _pumpShellAs(
        tester,
        FakeCurrentUserGateway.signedInAs(Role.employee),
      );

      await tester.tap(find.byKey(const Key('menu-item-createIncident')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.byKey(const Key('page-title'))).data,
        l10nEn.menuCreateIncident,
      );
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byKey(const Key('menu-item-createIncident')),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, AppColors.light.sidebarActiveBackground);
    });

    testWidgets(
      'shows the structured error panel when the user cannot be loaded',
      (tester) async {
        await _pumpShellAs(
          tester,
          FakeCurrentUserGateway.failing(
            Failure(ApiFailure.networkUnavailable()),
          ),
        );

        expect(find.byKey(const Key('error-panel')), findsOneWidget);
        expect(find.text(l10nEn.errorNetworkUnavailableTitle), findsOneWidget);
        expect(find.byKey(const Key('app-sidebar')), findsNothing);
      },
    );
  });
}
