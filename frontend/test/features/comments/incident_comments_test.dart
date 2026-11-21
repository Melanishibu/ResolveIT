import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/comments/comments.dart';
import 'package:resolveit/features/comments/data/repository/api_incident_comments_repository.dart';
import 'package:resolveit/features/incident/incident.dart';

import '../../support/auth_fakes.dart';
import '../../support/test_app.dart';

/// RIT-US-20 (AB#53) Comments tab on the incident details screen. Access, the closed rule and validation are
/// enforced by the backend (IncidentCommentsIT); these tests cover what the screen does with them.
void main() {
  testWidgets('TC-013 Add authorised comment', (tester) async {
    final comments = _FakeComments();
    await _open(tester, Role.employee, comments);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('comment-input')),
        matching: find.byType(EditableText),
      ),
      'It happens every morning',
    );
    await tester.tap(find.byKey(const Key('comment-submit')));
    await tester.pumpAndSettle();

    expect(comments.added, [('i1', 'It happens every morning')]);
    expect(find.text('It happens every morning'), findsOneWidget);
    expect(find.textContaining('Employee One'), findsWidgets);
    expect(find.text(l10nEn.incidentDetailsComments(1)), findsOneWidget);
  });

  testWidgets('Agent comments on an assigned incident', (tester) async {
    final comments = _FakeComments();
    await _open(tester, Role.supportAgent, comments);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('comment-input')),
        matching: find.byType(EditableText),
      ),
      'Looking into it',
    );
    await tester.tap(find.byKey(const Key('comment-submit')));
    await tester.pumpAndSettle();

    expect(comments.added.single.$2, 'Looking into it');
  });

  testWidgets('Unauthorised user cannot read or add comments', (tester) async {
    final comments = _FakeComments(
      loadRefusal: ApiFailure(
        code: 'INCIDENT_ACCESS_DENIED',
        params: {},
        httpStatus: 403,
      ),
    );
    await _open(tester, Role.employee, comments);

    expect(find.byKey(const Key('comments-error')), findsOneWidget);
  });

  testWidgets('Closed incident accepts no comments', (tester) async {
    await _open(
      tester,
      Role.employee,
      _FakeComments(),
      status: IncidentStatus.closed,
    );

    expect(find.byKey(const Key('comment-input')), findsNothing);
    expect(find.byKey(const Key('comment-submit')), findsNothing);
  });

  testWidgets('Empty comment is rejected', (tester) async {
    final comments = _FakeComments(
      addRefusal: ApiFailure(
        code: 'VALIDATION_FAILED',
        params: {'fields': 'text'},
        httpStatus: 400,
      ),
    );
    await _open(tester, Role.employee, comments);

    await tester.tap(find.byKey(const Key('comment-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('comment-add-error')), findsOneWidget);
  });

  test('maps the API comment page', () {
    final page = commentPageFromJson({
      'items': [
        {
          'id': 'c1',
          'author': {'id': 'u1', 'name': 'Employee One'},
          'text': 'Hello',
          'createdAt': '2026-11-21T09:00:00Z',
        },
      ],
      'totalItems': 1,
    })!;

    expect(page.totalItems, 1);
    expect(page.items.single.authorName, 'Employee One');
  });
}

final class _FakeComments implements IncidentCommentsRepository {
  _FakeComments({this.loadRefusal, this.addRefusal});

  final ApiFailure? loadRefusal;
  final ApiFailure? addRefusal;
  final added = <(String, String)>[];

  @override
  Future<Result<IncidentCommentPage>> list(String incidentId) async {
    final failure = loadRefusal;
    if (failure != null) return Failure(failure);
    return const Success(IncidentCommentPage(items: [], totalItems: 0));
  }

  @override
  Future<Result<IncidentComment>> add(String incidentId, String text) async {
    final failure = addRefusal;
    if (failure != null) return Failure(failure);
    added.add((incidentId, text));
    return Success(
      IncidentComment(
        id: 'c${added.length}',
        authorName: 'Employee One',
        text: text,
        createdAt: DateTime.utc(2026, 11, 21, 10),
      ),
    );
  }
}

final class _FakeDetails implements IncidentDetailsRepository {
  _FakeDetails(this.status);

  final IncidentStatus status;

  @override
  Future<Result<IncidentDetails>> details(String id) async => Success(
    IncidentDetails(
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
      allowedActions: const [],
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  Role role,
  _FakeComments comments, {
  IncidentStatus status = IncidentStatus.open,
}) async {
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
          _FakeDetails(status),
        ),
        incidentCommentsRepositoryProvider.overrideWithValue(comments),
      ],
    ),
  );
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/incidents/i1');
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10nEn.incidentDetailsComments(0)));
  await tester.pumpAndSettle();
}
