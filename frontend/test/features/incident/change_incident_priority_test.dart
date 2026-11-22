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

/// RIT-US-19 (AB#47) change priority on the incident details screen.
void main() {
  testWidgets(
    'Admin changes incident priority via Change Priority button and panel',
    (tester) async {
      final priorityRepo = _FakePriorityRepo();
      await _open(tester, Role.admin, [
        IncidentAction.changePriority,
      ], priorityRepo);

      expect(
        find.byKey(const Key('incident-change-priority-btn')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('incident-change-priority-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('change-priority-panel')), findsOneWidget);
      expect(find.byKey(const Key('incident-change-priority')), findsOneWidget);

      // Tap dropdown and select Critical
      await tester.tap(find.byKey(const Key('incident-change-priority')));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10nEn.priorityCritical).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('change-priority-submit')));
      await tester.pumpAndSettle();

      expect(priorityRepo.requests, [('i1', Priority.critical)]);
      expect(find.text('Priority changed to Critical'), findsOneWidget);
      expect(find.byKey(const Key('change-priority-panel')), findsNothing);
    },
  );

  testWidgets('Non-admin does not see priority button or panel', (
    tester,
  ) async {
    final priorityRepo = _FakePriorityRepo();
    await _open(tester, Role.employee, const [], priorityRepo);

    expect(find.byKey(const Key('incident-change-priority-btn')), findsNothing);
    expect(find.byKey(const Key('change-priority-panel')), findsNothing);
    expect(find.byKey(const Key('incident-change-priority')), findsNothing);
    expect(find.byType(PriorityChip), findsWidgets);
  });

  testWidgets('Backend 409 error is displayed in error panel', (tester) async {
    final priorityRepo = _FakePriorityRepo(
      refusal: ApiFailure(code: 'INCIDENT_CLOSED', params: {}, httpStatus: 409),
    );
    await _open(tester, Role.admin, [
      IncidentAction.changePriority,
    ], priorityRepo);

    await tester.tap(find.byKey(const Key('incident-change-priority-btn')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('incident-change-priority')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.priorityCritical).last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('change-priority-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('priority-error')), findsOneWidget);
  });

  testWidgets(
    'Admin does not see Start work button or standalone actions menu',
    (tester) async {
      final priorityRepo = _FakePriorityRepo();
      await _open(tester, Role.admin, [
        IncidentAction.reassign,
        IncidentAction.changePriority,
        IncidentAction.start,
      ], priorityRepo);

      expect(find.byKey(const Key('incident-reassign')), findsOneWidget);
      expect(
        find.byKey(const Key('incident-change-priority-btn')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('incident-start-work')), findsNothing);
      expect(find.byKey(const Key('incident-details-actions')), findsNothing);
    },
  );
}

Future<void> _open(
  WidgetTester tester,
  Role role,
  List<IncidentAction> actions,
  _FakePriorityRepo priorityRepo,
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
        incidentPriorityRepositoryProvider.overrideWithValue(priorityRepo),
      ],
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/incidents/i1');
  await tester.pumpAndSettle();
}

final class _FakePriorityRepo implements IncidentPriorityRepository {
  _FakePriorityRepo({this.refusal});

  final ApiFailure? refusal;
  final requests = <(String, Priority)>[];

  @override
  Future<Result<IncidentDetails>> changePriority(
    String incidentId,
    Priority priority,
  ) async {
    final failure = refusal;
    if (failure != null) return Failure(failure);
    requests.add((incidentId, priority));
    return Success(_incident(priority: priority));
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
  Priority priority = Priority.medium,
  IncidentStatus status = IncidentStatus.open,
  List<IncidentAction> actions = const [],
}) => IncidentDetails(
  id: 'i1',
  ticketNumber: 'INC-2026-00001',
  title: "Laptop won't start",
  description: 'Black screen',
  category: IncidentCategory.hardware,
  priority: priority,
  status: status,
  createdBy: const IncidentPerson(
    id: 'u1',
    name: 'Employee One',
    department: 'Finance',
  ),
  createdAt: DateTime.utc(2026, 11, 20, 10, 0),
  updatedAt: DateTime.utc(2026, 11, 20, 10, 0),
  allowedActions: actions,
);
