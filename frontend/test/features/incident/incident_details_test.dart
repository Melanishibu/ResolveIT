import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_details_repository.dart';
import 'package:resolveit/features/incident/incident.dart';

import '../../support/auth_fakes.dart';

/// RIT-US-10 (AB#38) UI scenarios.
void main() {
  testWidgets('Employee opens their own incident', (tester) async {
    await _open(tester, Role.employee, Success(_incident()));

    expect(find.text('INC-2026-00001'), findsOneWidget);
    expect(find.text('Printer jams'), findsWidgets);
    expect(find.text('Open'), findsWidgets);
    expect(find.text('Not assigned'), findsOneWidget);
  });

  testWidgets("TC-015 Employee cannot open another employee's incident", (
    tester,
  ) async {
    await _open(
      tester,
      Role.employee,
      Failure(
        ApiFailure(code: 'INCIDENT_ACCESS_DENIED', params: {}, httpStatus: 403),
      ),
    );

    expect(find.byKey(const Key('incident-details-error')), findsOneWidget);
    expect(find.text("You can't open this incident"), findsOneWidget);
  });

  testWidgets('Unknown incident', (tester) async {
    await _open(
      tester,
      Role.admin,
      Failure(
        ApiFailure(code: 'INCIDENT_NOT_FOUND', params: {}, httpStatus: 404),
      ),
    );

    expect(find.text("This incident doesn't exist"), findsOneWidget);
  });

  testWidgets('Actions follow the permission table', (tester) async {
    await _open(
      tester,
      Role.employee,
      Success(
        _incident(
          status: IncidentStatus.resolved,
          actions: const [IncidentAction.reopen, IncidentAction.close],
        ),
      ),
    );

    expect(find.byKey(const Key('incident-reopen')), findsOneWidget);
    expect(find.byKey(const Key('incident-close')), findsOneWidget);
    expect(find.byKey(const Key('incident-assign')), findsNothing);
  });

  testWidgets("Reporter's department is shown", (tester) async {
    await _open(tester, Role.admin, Success(_incident()));

    final department = tester.widget<Text>(
      find.byKey(const Key('incident-details-department')),
    );
    expect(department.data, 'Finance');
  });

  test('the API body maps to the incident details', () {
    final details = incidentDetailsFromJson({
      'id': 'i1',
      'ticketNumber': 'INC-2026-00001',
      'title': 'Printer jams',
      'description': 'Paper jam',
      'category': 'HARDWARE',
      'priority': 'LOW',
      'status': 'RESOLVED',
      'createdBy': {
        'id': 'u1',
        'name': 'Employee One',
        'department': 'Finance',
        'active': true,
      },
      'assignee': null,
      'resolutionNotes': null,
      'createdAt': '2026-11-21T09:00:00Z',
      'updatedAt': '2026-11-21T09:00:00Z',
      'allowedActions': ['REOPEN', 'CLOSE'],
    })!;

    expect(details.status, IncidentStatus.resolved);
    expect(details.createdBy.department, 'Finance');
    expect(details.allowedActions, [
      IncidentAction.reopen,
      IncidentAction.close,
    ]);
  });
}

IncidentDetails _incident({
  IncidentStatus status = IncidentStatus.open,
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

final class _FakeDetails implements IncidentDetailsRepository {
  _FakeDetails(this.result);

  final Result<IncidentDetails> result;

  @override
  Future<Result<IncidentDetails>> details(String id) async => result;
}

Future<void> _open(
  WidgetTester tester,
  Role role,
  Result<IncidentDetails> result,
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
          _FakeDetails(result),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/incidents/i1');
  await tester.pumpAndSettle();
}
