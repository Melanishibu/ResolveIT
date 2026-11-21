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

/// RIT-US-17 (AB#45) reopen panel on the incident details screen. Reason length, roles and transitions are
/// enforced by the backend (ReopenIncidentIT); these tests cover what the screen does with them.
void main() {
  testWidgets('Employee reopens their resolved incident', (tester) async {
    final transitions = _FakeTransitions();
    await _open(tester, Role.employee, [IncidentAction.reopen], transitions);

    await _reopen(tester, 'The laptop still does not start');

    expect(transitions.requests, [
      ('i1', IncidentStatus.inProgress, 'The laptop still does not start'),
    ]);
    expect(find.text(l10nEn.statusReopenedDone), findsOneWidget);
  });

  testWidgets('Assigned agent reopens', (tester) async {
    final transitions = _FakeTransitions();
    await _open(tester, Role.supportAgent, [
      IncidentAction.reopen,
    ], transitions);

    await _reopen(tester, 'The fix did not hold overnight');

    expect(transitions.requests, hasLength(1));
  });

  testWidgets('Reason is required', (tester) async {
    final transitions = _FakeTransitions(
      refusal: ApiFailure(
        code: 'INCIDENT_REOPEN_REASON_REQUIRED',
        params: {'min': '10', 'max': '500'},
        httpStatus: 400,
      ),
    );
    await _open(tester, Role.employee, [IncidentAction.reopen], transitions);

    await _reopen(tester, '');

    expect(
      find.text(l10nEn.errorIncidentReopenReasonRequiredTitle),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reopen-panel')), findsOneWidget);
  });

  testWidgets('Other employees cannot reopen', (tester) async {
    await _open(tester, Role.employee, const [], _FakeTransitions());

    expect(find.byKey(const Key('incident-details-actions')), findsNothing);
  });
}

Future<void> _reopen(WidgetTester tester, String reason) async {
  await tester.tap(find.byKey(const Key('incident-details-actions')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('incident-action-REOPEN')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('reopen-reason')),
      matching: find.byType(EditableText),
    ),
    reason,
  );
  await tester.tap(find.byKey(const Key('reopen-submit')));
  await tester.pumpAndSettle();
}

final class _FakeTransitions implements IncidentTransitionRepository {
  _FakeTransitions({this.refusal});

  final ApiFailure? refusal;
  final requests = <(String, IncidentStatus, String?)>[];

  @override
  Future<Result<IncidentDetails>> transition(
    String incidentId,
    IncidentStatus target, {
    String? resolutionNotes,
    String? reason,
  }) async {
    final failure = refusal;
    if (failure != null) return Failure(failure);
    requests.add((incidentId, target, reason));
    return Success(_incident(status: target));
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
  IncidentStatus status = IncidentStatus.resolved,
  List<IncidentAction> actions = const [],
}) => IncidentDetails(
  id: 'i1',
  ticketNumber: 'INC-2026-00001',
  title: "Laptop won't start",
  description: 'Black screen',
  category: IncidentCategory.hardware,
  priority: Priority.high,
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
  Role role,
  List<IncidentAction> actions,
  _FakeTransitions transitions,
) async {
  tester.view.physicalSize = const Size(1440, 1600);
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
        incidentTransitionRepositoryProvider.overrideWithValue(transitions),
      ],
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/incidents/i1');
  await tester.pumpAndSettle();
}
