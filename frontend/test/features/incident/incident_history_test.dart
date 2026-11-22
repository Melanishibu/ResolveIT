import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_history_repository.dart';
import 'package:resolveit/features/incident/incident.dart';

import '../../support/auth_fakes.dart';

/// RIT-US-13 (AB#41) UI scenarios: full history and Activity Timeline.
void main() {
  testWidgets('TC-014 Authorised user sees the history', (tester) async {
    final entries = [
      IncidentHistoryEntry(
        action: 'ASSIGNED',
        actorName: 'ResolveIT Admin',
        oldValue: null,
        newValue: 'Agent One',
        occurredAt: DateTime.utc(2026, 11, 21, 10, 30),
      ),
      IncidentHistoryEntry(
        action: 'CREATED',
        actorName: 'Employee One',
        oldValue: null,
        newValue: null,
        occurredAt: DateTime.utc(2026, 11, 21, 10),
      ),
    ];

    await _open(tester, Role.admin, Success(entries));

    // Overview tab shows Activity Timeline with the entries
    expect(find.byKey(const Key('activity-timeline-panel')), findsOneWidget);
    expect(find.text('Activity Timeline'), findsOneWidget);
    expect(find.text('Status: Open → Assigned'), findsWidgets);
    expect(find.text('Incident created'), findsWidgets);

    // Switch to History tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('incident-history-list')), findsOneWidget);
    expect(find.text('Status: Open → Assigned'), findsWidgets);
    expect(find.text('Incident created'), findsWidgets);
  });

  testWidgets('Activity Timeline View all link switches to History tab', (
    tester,
  ) async {
    final entries = [
      IncidentHistoryEntry(
        action: 'CREATED',
        actorName: 'Employee One',
        occurredAt: DateTime.utc(2026, 11, 21, 10),
      ),
    ];

    await _open(tester, Role.admin, Success(entries));

    // Click "View all" in Activity Timeline
    await tester.tap(find.byKey(const Key('activity-timeline-view-all')));
    await tester.pumpAndSettle();

    // Now History tab is active
    expect(find.byKey(const Key('incident-history-list')), findsOneWidget);
  });

  testWidgets('Empty history displays empty state', (tester) async {
    await _open(tester, Role.admin, const Success([]));

    // Tap History tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('incident-history-empty')), findsOneWidget);
  });

  test('incidentHistoryFromJson maps JSON array properly', () {
    final entries = incidentHistoryFromJson([
      {
        'action': 'ASSIGNED',
        'actorName': 'ResolveIT Admin',
        'oldValue': 'OPEN',
        'newValue': 'ASSIGNED',
        'occurredAt': '2026-11-21T10:30:00Z',
      },
      {
        'action': 'CREATED',
        'actor': 'Employee One',
        'timestamp': '2026-11-21T10:00:00Z',
      },
    ])!;

    expect(entries.length, 2);
    expect(entries[0].action, 'ASSIGNED');
    expect(entries[0].actorName, 'ResolveIT Admin');
    expect(entries[0].oldValue, 'OPEN');
    expect(entries[0].newValue, 'ASSIGNED');
    expect(entries[1].action, 'CREATED');
    expect(entries[1].actorName, 'Employee One');
  });
}

IncidentDetails _incident() => IncidentDetails(
  id: 'i1',
  ticketNumber: 'INC-2026-00001',
  title: 'Printer jams',
  description: 'Paper jam on floor 2',
  category: IncidentCategory.hardware,
  priority: Priority.low,
  status: IncidentStatus.assigned,
  createdBy: const IncidentPerson(
    id: 'u1',
    name: 'Employee One',
    department: 'Finance',
  ),
  createdAt: DateTime.utc(2026, 11, 21, 9),
  updatedAt: DateTime.utc(2026, 11, 21, 10, 30),
  allowedActions: const [IncidentAction.start],
);

final class _FakeDetails implements IncidentDetailsRepository {
  @override
  Future<Result<IncidentDetails>> details(String id) async =>
      Success(_incident());
}

final class _FakeHistory implements IncidentHistoryRepository {
  _FakeHistory(this.result);

  final Result<List<IncidentHistoryEntry>> result;

  @override
  Future<Result<List<IncidentHistoryEntry>>> history(String incidentId) async =>
      result;
}

Future<void> _open(
  WidgetTester tester,
  Role role,
  Result<List<IncidentHistoryEntry>> historyResult,
) async {
  tester.view.physicalSize = const Size(1440, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = FakeIdentityBackend.signedInAs(role);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserRepositoryProvider.overrideWithValue(backend),
        sessionRepositoryProvider.overrideWithValue(backend),
        incidentDetailsRepositoryProvider.overrideWithValue(_FakeDetails()),
        incidentHistoryRepositoryProvider.overrideWithValue(
          _FakeHistory(historyResult),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/incidents/i1');
  await tester.pumpAndSettle();
}
