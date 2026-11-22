import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/incident/incident.dart';

import '../../support/auth_fakes.dart';
import '../../support/test_app.dart';

/// RIT-US-14 (AB#42) assign panel on the incident details screen. Role, status and assignee rules are
/// enforced by the backend (AssignIncidentIT); these tests cover what the screen does with them.
void main() {
  testWidgets('TC-005 Admin assigns an active agent', (tester) async {
    final assignment = _FakeAssignment();
    await _open(tester, Role.admin, [IncidentAction.assign], assignment);

    await _openPanel(tester);
    await tester.tap(find.byKey(const Key('assign-agent')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agent One (agent1@resolveit.local)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-submit')));
    await tester.pumpAndSettle();

    expect(assignment.assigned, [('i1', 'a1')]);
    expect(find.text(l10nEn.assignPanelDone('Agent One')), findsOneWidget);
    expect(find.byKey(const Key('assign-panel')), findsNothing);
  });

  testWidgets('Admin assigns an active agent via the Assign button', (tester) async {
    final assignment = _FakeAssignment();
    await _open(tester, Role.admin, [IncidentAction.assign], assignment);

    expect(find.byKey(const Key('incident-assign')), findsOneWidget);
    await tester.tap(find.byKey(const Key('incident-assign')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assign-panel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('assign-agent')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agent One (agent1@resolveit.local)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-submit')));
    await tester.pumpAndSettle();

    expect(assignment.assigned, [('i1', 'a1')]);
    expect(find.text(l10nEn.assignPanelDone('Agent One')), findsOneWidget);
    expect(find.byKey(const Key('assign-panel')), findsNothing);
  });

  testWidgets('TC-006 Employee attempts assignment', (tester) async {
    await _open(tester, Role.employee, const [], _FakeAssignment());

    expect(find.byKey(const Key('incident-details-actions')), findsNothing);
  });

  testWidgets('Inactive agent cannot receive assignments', (tester) async {
    final assignment = _FakeAssignment(
      refusal: ApiFailure(
        code: 'ASSIGNEE_NOT_ACTIVE_AGENT',
        params: {},
        httpStatus: 422,
      ),
    );
    await _open(tester, Role.admin, [IncidentAction.assign], assignment);

    await _openPanel(tester);
    await tester.tap(find.byKey(const Key('assign-agent')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agent One (agent1@resolveit.local)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('assign-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assign-error')), findsOneWidget);
    expect(find.text(l10nEn.errorAssigneeNotActiveAgentTitle), findsOneWidget);
  });

  testWidgets('Admin reassigns an assigned incident', (tester) async {
    await _open(tester, Role.admin, [
      IncidentAction.reassign,
      IncidentAction.start,
    ], _FakeAssignment());

    await tester.tap(find.byKey(const Key('incident-reassign')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('assign-panel')), findsOneWidget);
  });

  testWidgets('Agent dropdown lists only active agents', (tester) async {
    await _open(tester, Role.admin, [IncidentAction.assign], _FakeAssignment());

    await _openPanel(tester);
    await tester.tap(find.byKey(const Key('assign-agent')));
    await tester.pumpAndSettle();

    expect(find.text('Agent One (agent1@resolveit.local)'), findsWidgets);
    expect(find.textContaining('Agent Two'), findsNothing);
  });
}

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('incident-assign')));
  await tester.pumpAndSettle();
}

final class _FakeAssignment implements IncidentAssignmentRepository {
  _FakeAssignment({this.refusal});

  final ApiFailure? refusal;
  final assigned = <(String, String)>[];

  @override
  Future<Result<List<AssignableAgent>>> activeAgents() async => const Success([
    AssignableAgent(
      id: 'a1',
      name: 'Agent One',
      email: 'agent1@resolveit.local',
    ),
  ]);

  @override
  Future<Result<IncidentDetails>> assign(
    String incidentId,
    String agentId,
  ) async {
    final failure = refusal;
    if (failure != null) return Failure(failure);
    assigned.add((incidentId, agentId));
    return Success(
      _incident(
        status: IncidentStatus.assigned,
        assignee: const IncidentPerson(id: 'a1', name: 'Agent One'),
      ),
    );
  }
}

final class _FakeDetails implements IncidentDetailsRepository {
  _FakeDetails(this.actions);

  final List<IncidentAction> actions;

  @override
  Future<Result<IncidentDetails>> details(String id) async =>
      Success(_incident(actions: actions));
}

IncidentDetails _incident({
  IncidentStatus status = IncidentStatus.open,
  List<IncidentAction> actions = const [],
  IncidentPerson? assignee,
}) => IncidentDetails(
  id: 'i1',
  ticketNumber: 'INC-2026-00001',
  title: 'Printer jams',
  description: 'Paper jam on floor 2',
  category: IncidentCategory.hardware,
  priority: Priority.low,
  status: status,
  createdBy: const IncidentPerson(
    id: 'u1',
    name: 'Employee One',
    department: 'Finance',
  ),
  assignee: assignee,
  createdAt: DateTime.utc(2026, 11, 21, 9),
  updatedAt: DateTime.utc(2026, 11, 21, 9),
  allowedActions: actions,
);

Future<void> _open(
  WidgetTester tester,
  Role role,
  List<IncidentAction> actions,
  _FakeAssignment assignment,
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
        incidentDetailsRepositoryProvider.overrideWithValue(
          _FakeDetails(actions),
        ),
        incidentAssignmentRepositoryProvider.overrideWithValue(assignment),
      ],
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/incidents/i1');
  await tester.pumpAndSettle();
}
