import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/dashboard/dashboard.dart';
import 'package:resolveit/features/incident/incident.dart';

import '../../support/auth_fakes.dart';
import '../../support/test_app.dart';

/// RIT-US-21 (AB#54) dashboard screen. Counting and role scope are done by the backend (DashboardIT); these tests
/// cover what the screen shows and where the cards lead.
void main() {
  testWidgets('Admin sees counts for all incidents', (tester) async {
    await _open(tester, Role.admin, '/dashboard');

    expect(find.text(l10nEn.dashboardAdminTitle), findsOneWidget);
    expect(_count('total'), '8');
    expect(_count('open'), '3');
    expect(_count('assigned'), '2');
    expect(_count('in-progress'), '1');
    expect(_count('resolved'), '1');
    expect(_count('critical'), '2');
  });

  testWidgets('Card opens the filtered list', (tester) async {
    final list = _FakeList();
    await _open(tester, Role.admin, '/dashboard', list: list);

    await tester.tap(find.byKey(const Key('dashboard-card-critical')));
    await tester.pumpAndSettle();

    final filter = list.requests.last;
    expect(filter.priorities, [Priority.critical]);
    expect(filter.statuses, isNot(contains(IncidentStatus.closed)));
    expect(filter.statuses, hasLength(4));
  });

  testWidgets('Recent activity respects the role scope', (tester) async {
    await _open(tester, Role.employee, '/dashboard');

    expect(find.byKey(const Key('dashboard-recent-activity')), findsOneWidget);
    expect(
      find.text('INC-2026-00001 · ${l10nEn.activityCreated}'),
      findsOneWidget,
    );
  });

  testWidgets('Technician sees recent assigned incidents', (tester) async {
    final dashboard = _FakeDashboard();
    await _open(tester, Role.supportAgent, '/dashboard', dashboard: dashboard);

    expect(find.text(l10nEn.dashboardTechnicianTitle), findsOneWidget);
    expect(dashboard.recentLimit, 5);
    for (var n = 1; n <= 5; n++) {
      expect(find.byKey(Key('dashboard-recent-r$n')), findsOneWidget);
    }
    expect(find.byKey(const Key('dashboard-card-total')), findsNothing);
  });

  testWidgets('Count cards on the incident list', (tester) async {
    await _open(tester, Role.employee, '/my-incidents');

    expect(find.byKey(const Key('incident-count-cards')), findsOneWidget);
    expect(find.text(l10nEn.dashboardTotal), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });
}

String? _count(String key) {
  final card = find.byKey(Key('dashboard-card-$key'));
  return find
      .descendant(of: card, matching: find.byType(Text))
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .last;
}

final class _FakeDashboard implements DashboardRepository {
  int? recentLimit;

  @override
  Future<Result<DashboardCounts>> counts() async => const Success(
    DashboardCounts(
      total: 8,
      open: 3,
      assigned: 2,
      inProgress: 1,
      resolved: 1,
      critical: 2,
    ),
  );

  @override
  Future<Result<List<ActivityEntry>>> activity({int limit = 10}) async =>
      Success([
        ActivityEntry(
          incidentId: 'i1',
          ticketNumber: 'INC-2026-00001',
          action: 'CREATED',
          actorName: 'Employee One',
          occurredAt: DateTime.utc(2026, 11, 21, 9),
        ),
      ]);

  @override
  Future<Result<List<RecentIncident>>> recentAssigned({int limit = 5}) async {
    recentLimit = limit;
    return Success([
      for (var n = 1; n <= limit; n++)
        RecentIncident(
          id: 'r$n',
          ticketNumber: 'INC-2026-0000$n',
          title: 'Assigned $n',
          status: 'ASSIGNED',
        ),
    ]);
  }
}

final class _FakeList implements IncidentListRepository {
  final requests = <IncidentListFilter>[];

  @override
  Future<Result<IncidentPage>> list(IncidentListFilter filter) async {
    requests.add(filter);
    return const Success(IncidentPage(items: [], totalItems: 0));
  }
}

Future<void> _open(
  WidgetTester tester,
  Role role,
  String path, {
  _FakeDashboard? dashboard,
  _FakeList? list,
}) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = FakeIdentityBackend.signedInAs(role);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserRepositoryProvider.overrideWithValue(backend),
        sessionRepositoryProvider.overrideWithValue(backend),
        dashboardRepositoryProvider.overrideWithValue(
          dashboard ?? _FakeDashboard(),
        ),
        incidentListRepositoryProvider.overrideWithValue(list ?? _FakeList()),
      ],
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
  await tester.pumpAndSettle();
}
