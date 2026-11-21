import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/incident/data/datasource/incident_remote_datasource.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_repository.dart';
import 'package:resolveit/features/incident/incident.dart';

import '../../support/auth_fakes.dart';
import '../../support/test_app.dart';

/// RIT-US-09 (AB#37) create-incident screen, through the real composition root.
void main() {
  testWidgets('TC-003 Employee creates an incident from the form', (
    tester,
  ) async {
    final incidents = FakeIncidents();
    await _openForm(tester, incidents);

    expect(find.text(l10nEn.createIncidentHelpTitle), findsOneWidget);
    await _enter(tester, 'create-incident-title', "Laptop won't start");
    await _choose(tester, 'create-incident-category', l10nEn.categoryHardware);
    await _choose(tester, 'create-incident-priority', l10nEn.priorityHigh);
    await _enter(tester, 'create-incident-description', 'Black screen.');
    await tester.tap(find.byKey(const Key('create-incident-submit')));
    await tester.pumpAndSettle();

    final sent = incidents.reported.single;
    expect(sent.title, "Laptop won't start");
    expect(sent.category, IncidentCategory.hardware);
    expect(sent.priority, Priority.high);
    expect(
      find.text(l10nEn.createIncidentSuccess('INC-2026-00001')),
      findsOneWidget,
    );
    expect(_router(tester).state.uri.path, '/my-incidents');
  });

  testWidgets('TC-004 Empty title is rejected', (tester) async {
    final incidents = FakeIncidents();
    await _openForm(tester, incidents);

    await _choose(tester, 'create-incident-category', l10nEn.categorySoftware);
    await _choose(tester, 'create-incident-priority', l10nEn.priorityLow);
    await _enter(tester, 'create-incident-description', 'Something broke.');
    await tester.tap(find.byKey(const Key('create-incident-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.createIncidentTitleRequired), findsOneWidget);
    expect(incidents.reported, isEmpty, reason: 'nothing is sent');
    expect(_router(tester).state.uri.path, '/incidents/new');
  });

  testWidgets('TC-004 The backend refusal VALIDATION_FAILED is explained', (
    tester,
  ) async {
    final incidents = FakeIncidents(
      failure: ApiFailure(
        code: 'VALIDATION_FAILED',
        params: const {'fields': 'title'},
        httpStatus: 400,
      ),
    );
    await _openForm(tester, incidents);

    await _fillValidForm(tester);
    await tester.tap(find.byKey(const Key('create-incident-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create-incident-error')), findsOneWidget);
    expect(find.text(l10nEn.errorValidationFailedTitle), findsOneWidget);
  });

  testWidgets('Field limits are enforced', (tester) async {
    await _openForm(tester, FakeIncidents());

    expect(find.text('0/120'), findsOneWidget);
    expect(find.text('0/2000'), findsOneWidget);
    await _enter(tester, 'create-incident-title', 't' * 121);
    expect(find.text('120/120'), findsOneWidget, reason: 'input stops at 120');

    expect(
      NewIncident(
        title: 't' * 121,
        description: 'ok',
        category: IncidentCategory.other,
        priority: Priority.low,
      ).invalidFields,
      {NewIncidentField.title},
    );
    expect(
      NewIncident(
        title: 'ok',
        description: 'd' * 2001,
        category: IncidentCategory.other,
        priority: Priority.low,
      ).invalidFields,
      {NewIncidentField.description},
    );
  });

  testWidgets('Support Agent cannot create incidents', (tester) async {
    await _pumpApp(
      tester,
      FakeIdentityBackend.signedInAs(Role.supportAgent),
      FakeIncidents(),
    );

    _router(tester).go('/incidents/new');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('not-allowed-page')), findsOneWidget);
  });

  testWidgets('A 403 from the backend is shown through the error panel', (
    tester,
  ) async {
    final incidents = FakeIncidents(
      failure: ApiFailure(code: 'AUTH_FORBIDDEN', httpStatus: 403),
    );
    await _openForm(tester, incidents);

    await _fillValidForm(tester);
    await tester.tap(find.byKey(const Key('create-incident-submit')));
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.errorAuthForbiddenTitle), findsOneWidget);
  });

  testWidgets('Cancel returns to My Incidents without sending', (tester) async {
    final incidents = FakeIncidents();
    await _openForm(tester, incidents);

    await tester.tap(find.byKey(const Key('create-incident-cancel')));
    await tester.pumpAndSettle();

    expect(incidents.reported, isEmpty);
    expect(_router(tester).state.uri.path, '/my-incidents');
  });

  group('ApiIncidentRepository', () {
    late Dio dio;
    late DioAdapter server;
    late ApiIncidentRepository repository;
    const incident = NewIncident(
      title: "  Laptop won't start ",
      description: ' Black screen. ',
      category: IncidentCategory.hardware,
      priority: Priority.high,
    );

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'));
      server = DioAdapter(dio: dio);
      repository = ApiIncidentRepository(IncidentRemoteDataSource(dio));
    });

    test(
      'POST /tickets sends the trimmed fields and maps the ticket number',
      () async {
        server.onPost(
          '/tickets',
          (s) => s.reply(201, {
            'id': 'a1',
            'ticketNumber': 'INC-2026-00007',
            'status': 'OPEN',
          }),
          data: {
            'title': "Laptop won't start",
            'description': 'Black screen.',
            'category': 'HARDWARE',
            'priority': 'HIGH',
          },
        );

        final result = await repository.report(incident);

        final reported = (result as Success<ReportedIncident>).value;
        expect(reported.ticketNumber, 'INC-2026-00007');
        expect(reported.id, 'a1');
      },
    );

    test('a refusal becomes the Problem Details failure', () async {
      server.onPost(
        '/tickets',
        (s) => s.reply(400, {
          'code': 'VALIDATION_FAILED',
          'title': 'Invalid',
          'params': {
            'fields': ['title'],
          },
        }),
        data: Matchers.any,
      );

      final result = await repository.report(incident);

      expect(
        (result as Failure<ReportedIncident>).failure.code,
        'VALIDATION_FAILED',
      );
    });
  });
}

final class FakeIncidents implements IncidentRepository {
  FakeIncidents({this.failure});

  final ApiFailure? failure;
  final reported = <NewIncident>[];

  @override
  Future<Result<ReportedIncident>> report(NewIncident incident) async {
    final refused = failure;
    if (refused != null) return Failure(refused);
    reported.add(incident);
    return const Success(
      ReportedIncident(id: 'i-1', ticketNumber: 'INC-2026-00001'),
    );
  }
}

Future<void> _openForm(WidgetTester tester, FakeIncidents incidents) async {
  await _pumpApp(
    tester,
    FakeIdentityBackend.signedInAs(Role.employee),
    incidents,
  );
  _router(tester).go('/incidents/new');
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('create-incident-submit')), findsOneWidget);
}

Future<void> _fillValidForm(WidgetTester tester) async {
  await _enter(tester, 'create-incident-title', 'Printer jam');
  await _choose(tester, 'create-incident-category', l10nEn.categoryHardware);
  await _choose(tester, 'create-incident-priority', l10nEn.priorityMedium);
  await _enter(tester, 'create-incident-description', 'Paper stuck.');
}

Future<void> _pumpApp(
  WidgetTester tester,
  FakeIdentityBackend backend,
  FakeIncidents incidents,
) async {
  tester.view.physicalSize = const Size(1440, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserRepositoryProvider.overrideWithValue(backend),
        sessionRepositoryProvider.overrideWithValue(backend),
        incidentRepositoryProvider.overrideWithValue(incidents),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String fieldKey, String text) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(Key(fieldKey)),
      matching: find.byType(EditableText),
    ),
    text,
  );
  await tester.pump();
}

Future<void> _choose(WidgetTester tester, String key, String label) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));
