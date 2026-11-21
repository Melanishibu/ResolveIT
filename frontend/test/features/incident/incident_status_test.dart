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

/// RIT-US-15 (AB#43) Start work on the incident details screen. Access and transition rules are enforced
/// by the backend (IncidentStatusIT); these tests cover what the screen does with them.
void main() {
  testWidgets('TC-007 Agent starts work on an assigned incident', (
    tester,
  ) async {
    final statuses = _FakeStatus();
    await _open(tester, [IncidentAction.start], statuses);

    await tester.tap(find.byKey(const Key('incident-start-work')));
    await tester.pumpAndSettle();

    expect(statuses.requests, [('i1', IncidentStatus.inProgress)]);
    expect(find.text(l10nEn.statusStartedDone), findsOneWidget);
  });

  testWidgets("TC-008 Agent cannot change another agent's incident", (
    tester,
  ) async {
    final statuses = _FakeStatus(
      refusal: ApiFailure(
        code: 'INCIDENT_ACCESS_DENIED',
        params: {},
        httpStatus: 403,
      ),
    );
    await _open(tester, [IncidentAction.start], statuses);

    await tester.tap(find.byKey(const Key('incident-start-work')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('status-error')), findsOneWidget);
    expect(find.text(l10nEn.errorIncidentAccessDeniedTitle), findsOneWidget);
  });

  testWidgets('TC-012 Invalid transition is rejected', (tester) async {
    final statuses = _FakeStatus(
      refusal: ApiFailure(
        code: 'INCIDENT_INVALID_TRANSITION',
        params: {'status': 'OPEN'},
        httpStatus: 409,
      ),
    );
    await _open(tester, [IncidentAction.start], statuses);

    await tester.tap(find.byKey(const Key('incident-start-work')));
    await tester.pumpAndSettle();

    expect(
      find.text(l10nEn.errorIncidentInvalidTransitionTitle),
      findsOneWidget,
    );
  });

  testWidgets('Closed incidents are final', (tester) async {
    await _open(tester, const [], _FakeStatus());

    expect(find.byKey(const Key('incident-start-work')), findsNothing);
    expect(find.byKey(const Key('incident-details-actions')), findsNothing);
  });
}

final class _FakeStatus implements IncidentStatusRepository {
  _FakeStatus({this.refusal});

  final ApiFailure? refusal;
  final requests = <(String, IncidentStatus)>[];

  @override
  Future<Result<IncidentDetails>> changeStatus(
    String incidentId,
    IncidentStatus target,
  ) async {
    final failure = refusal;
    if (failure != null) return Failure(failure);
    requests.add((incidentId, target));
    return Success(_incident(status: IncidentStatus.inProgress));
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
  IncidentStatus status = IncidentStatus.assigned,
  List<IncidentAction> actions = const [],
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
  createdAt: DateTime.utc(2026, 11, 21, 9),
  updatedAt: DateTime.utc(2026, 11, 21, 9),
  allowedActions: actions,
);

Future<void> _open(
  WidgetTester tester,
  List<IncidentAction> actions,
  _FakeStatus statuses,
) async {
  tester.view.physicalSize = const Size(1440, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = FakeIdentityBackend.signedInAs(Role.supportAgent);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserRepositoryProvider.overrideWithValue(backend),
        sessionRepositoryProvider.overrideWithValue(backend),
        incidentDetailsRepositoryProvider.overrideWithValue(
          _FakeDetails(actions),
        ),
        incidentStatusRepositoryProvider.overrideWithValue(statuses),
      ],
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/incidents/i1');
  await tester.pumpAndSettle();
}
