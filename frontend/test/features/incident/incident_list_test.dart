import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_list_repository.dart';
import 'package:resolveit/features/incident/incident.dart';

import '../../support/auth_fakes.dart';
import '../../support/test_app.dart';

/// RIT-US-11 (AB#39) incident list screen. Scoping, paging maths and the size cap are enforced by the
/// backend (IncidentListIT); these tests cover what the screen does with them.
void main() {
  testWidgets('Admin sees all incidents', (tester) async {
    final incidents = _FakeList(_page(3, total: 3));
    await _open(tester, Role.admin, '/incidents', incidents);

    expect(find.text(l10nEn.menuIncidents), findsWidgets);
    expect(find.text(l10nEn.incidentListSubtitleAll), findsOneWidget);
    expect(find.text('INC-2026-00001'), findsOneWidget);
    expect(find.text('INC-2026-00003'), findsOneWidget);
    expect(incidents.requests.single.sortField, IncidentSortField.createdAt);
    expect(
      incidents.requests.single.ascending,
      isFalse,
      reason: 'newest first',
    );
  });

  testWidgets('Employee sees only their own incidents', (tester) async {
    await _open(tester, Role.employee, '/my-incidents', _FakeList(_page(1)));

    expect(find.text(l10nEn.incidentListSubtitleOwn), findsOneWidget);
    expect(find.text('INC-2026-00001'), findsOneWidget);
  });

  testWidgets('Agent sees only incidents assigned to them', (tester) async {
    await _open(
      tester,
      Role.supportAgent,
      '/my-incidents',
      _FakeList(_page(1)),
    );

    expect(find.text(l10nEn.incidentListSubtitleAssigned), findsOneWidget);
  });

  testWidgets('Paging works', (tester) async {
    final incidents = _FakeList(_page(20, total: 45));
    await _open(tester, Role.admin, '/incidents', incidents);

    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();

    expect(incidents.requests.last.page, 2);
  });

  testWidgets('Sorting by priority', (tester) async {
    final incidents = _FakeList(_page(2));
    await _open(tester, Role.admin, '/incidents', incidents);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('incident-list-table')),
        matching: find.text(l10nEn.incidentDetailsPriority),
      ),
    );
    await tester.pumpAndSettle();

    expect(incidents.requests.last.sortField, IncidentSortField.priority);
    expect(
      incidents.requests.last.ascending,
      isFalse,
      reason: 'CRITICAL first',
    );
  });

  testWidgets('A row opens the incident details', (tester) async {
    await _open(tester, Role.admin, '/incidents', _FakeList(_page(1)));

    final view = find.text(l10nEn.incidentListOpen);
    await tester.ensureVisible(view);
    await tester.pumpAndSettle();
    await tester.tap(view);
    await tester.pumpAndSettle();

    expect(_router(tester).state.uri.path, '/incidents/i1');
  });

  test('maps the API page', () {
    final page = incidentPageFromJson({
      'items': [
        {
          'id': 'i1',
          'ticketNumber': 'INC-2026-00001',
          'title': 'Printer jams',
          'category': 'HARDWARE',
          'priority': 'CRITICAL',
          'status': 'ASSIGNED',
          'assignee': {'id': 'a1', 'name': 'Agent One', 'active': true},
          'createdAt': '2026-11-21T09:00:00Z',
          'updatedAt': '2026-11-21T09:00:00Z',
        },
      ],
      'page': 0,
      'size': 20,
      'totalItems': 1,
      'totalPages': 1,
    })!;

    expect(page.totalItems, 1);
    expect(page.items.single.priority, Priority.critical);
    expect(page.items.single.assigneeName, 'Agent One');
  });

  group('RIT-US-12 (AB#40) Search and filter incidents', () {
    testWidgets('Search box updates q in list filter after 300 ms debounce', (
      tester,
    ) async {
      final incidents = _FakeList(_page(1));
      await _open(tester, Role.admin, '/incidents', incidents);

      await tester.enterText(
        find.byKey(const Key('incident-list-search')),
        'printer',
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(incidents.requests.last.q, isNull);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(incidents.requests.last.q, 'printer');
    });

    testWidgets(
      'Empty state shows no matches message and clear filters button when filtered',
      (tester) async {
        final incidents = _FakeList(_page(0));
        await _open(tester, Role.admin, '/incidents?q=nonexistent', incidents);

        expect(
          find.byKey(const Key('incident-list-no-matches')),
          findsOneWidget,
        );
        expect(find.text(l10nEn.incidentListNoMatches), findsOneWidget);

        await tester.tap(
          find.widgetWithText(FilledButton, l10nEn.incidentListClearFilters),
        );
        await tester.pumpAndSettle();

        expect(incidents.requests.last.q, isNull);
      },
    );

    testWidgets('Clear filters button clears all filters and chips', (
      tester,
    ) async {
      final incidents = _FakeList(_page(2));
      await _open(
        tester,
        Role.admin,
        '/incidents?status=OPEN&q=test',
        incidents,
      );

      expect(
        find.byKey(const Key('incident-active-filter-chips')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('incident-clear-filters')), findsOneWidget);

      await tester.tap(find.byKey(const Key('incident-clear-filters')));
      await tester.pumpAndSettle();

      expect(incidents.requests.last.hasFilters, isFalse);
    });

    testWidgets('URL parameters populate initial filter on page load', (
      tester,
    ) async {
      final incidents = _FakeList(_page(1));
      await _open(
        tester,
        Role.admin,
        '/incidents?q=INC-2026-00042&status=OPEN&priority=CRITICAL&dateRange=last30Days',
        incidents,
      );

      final filter = incidents.requests.first;
      expect(filter.q, 'INC-2026-00042');
      expect(filter.statuses, [IncidentStatus.open]);
      expect(filter.priorities, [Priority.critical]);
      expect(filter.dateRange, DateRangeOption.last30Days);
      expect(filter.createdFrom, isNotNull);
    });
  });
}

IncidentPage _page(int count, {int? total}) => IncidentPage(
  totalItems: total ?? count,
  items: [
    for (var n = 1; n <= count; n++)
      IncidentListItem(
        id: 'i$n',
        ticketNumber: 'INC-2026-${n.toString().padLeft(5, '0')}',
        title: 'Incident $n',
        category: IncidentCategory.hardware,
        priority: Priority.low,
        status: IncidentStatus.open,
        assigneeName: null,
        createdAt: DateTime.utc(2026, 11, 21, 9),
      ),
  ],
);

final class _FakeList implements IncidentListRepository {
  _FakeList(this.page);

  final IncidentPage page;
  final requests = <IncidentListFilter>[];

  @override
  Future<Result<IncidentPage>> list(IncidentListFilter filter) async {
    requests.add(filter);
    return Success(page);
  }
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

Future<void> _open(
  WidgetTester tester,
  Role role,
  String path,
  _FakeList incidents,
) async {
  tester.view.physicalSize = const Size(1600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = FakeIdentityBackend.signedInAs(role);
  await tester.pumpWidget(
    ResolveItApp(
      overrides: [
        currentUserRepositoryProvider.overrideWithValue(backend),
        sessionRepositoryProvider.overrideWithValue(backend),
        incidentListRepositoryProvider.overrideWithValue(incidents),
      ],
    ),
  );
  await tester.pumpAndSettle();
  _router(tester).go(path);
  await tester.pumpAndSettle();
}
