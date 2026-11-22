import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';

import '../../../support/component_test_app.dart';

// Scenario: Table paginates and sorts
//   Given an AppDataTable with 45 rows and page size 20
//   When page 3 is selected and the Priority header is clicked
//   Then the footer reads "Showing 41–45 of 45" and the sort callback receives Priority

typedef _Row = ({int number, String priority});

/// Test harness: owns page state like a presenter would (the table is controlled).
class _TableHarness extends StatefulWidget {
  const _TableHarness({required this.onSort});

  final ValueChanged<String> onSort;

  @override
  State<_TableHarness> createState() => _TableHarnessState();
}

class _TableHarnessState extends State<_TableHarness> {
  static const pageSize = 20;
  static final rows = [
    for (var i = 1; i <= 45; i++)
      (number: i, priority: i.isEven ? 'HIGH' : 'LOW'),
  ];
  int page = 0;

  @override
  Widget build(BuildContext context) => AppDataTable<_Row>(
    columns: [
      AppTableColumn(
        id: 'number',
        label: 'Incident #',
        cell: (row) => Text('INC-${row.number}'),
      ),
      AppTableColumn(
        id: 'priority',
        label: 'Priority',
        sortable: true,
        cell: (row) => Text(row.priority),
      ),
    ],
    rows: rows.skip(page * pageSize).take(pageSize).toList(),
    page: page,
    pageSize: pageSize,
    totalItems: rows.length,
    onPageChanged: (p) => setState(() => page = p),
    onSort: widget.onSort,
    rowAction: AppTableRowAction(label: 'View', onPressed: (_) {}),
  );
}

void main() {
  testWidgets('Table paginates and sorts', (tester) async {
    useDesktopViewport(tester, height: 2400);
    final sorted = <String>[];
    await tester.pumpWidget(
      componentTestApp(_TableHarness(onSort: sorted.add)),
    );

    expect(find.text('Showing 1–20 of 45'), findsOneWidget);

    await tester.tap(find.byKey(const Key('table-page-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Priority'));
    await tester.pumpAndSettle();

    expect(find.text('Showing 41–45 of 45'), findsOneWidget);
    expect(find.text('INC-45'), findsOneWidget);
    expect(find.text('INC-40'), findsNothing);
    expect(sorted, ['priority']);
  });

  testWidgets('previous and next move one page and stop at the ends', (
    tester,
  ) async {
    useDesktopViewport(tester, height: 2400);
    await tester.pumpWidget(componentTestApp(_TableHarness(onSort: (_) {})));

    IconButton button(String key) => tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(IconButton),
      ),
    );
    expect(button('table-previous-page').onPressed, isNull);

    await tester.tap(find.byKey(const Key('table-next-page')));
    await tester.pumpAndSettle();
    expect(find.text('Showing 21–40 of 45'), findsOneWidget);

    await tester.tap(find.byKey(const Key('table-next-page')));
    await tester.pumpAndSettle();
    expect(button('table-next-page').onPressed, isNull);
  });

  // PR !4 review (thread 28): with no rows the footer and paging are hidden; screens show an
  // EmptyState instead.
  testWidgets('an empty table shows no footer and no paging', (tester) async {
    await tester.pumpWidget(
      componentTestApp(
        AppDataTable<int>(
          columns: [
            AppTableColumn(id: 'n', label: 'N', cell: (n) => Text('$n')),
          ],
          rows: const [],
          page: 0,
          pageSize: 20,
          totalItems: 0,
          onPageChanged: (_) {},
        ),
      ),
    );
    expect(find.byKey(const Key('table-footer-summary')), findsNothing);
    expect(find.textContaining('Showing'), findsNothing);
    expect(find.byKey(const Key('table-page-1')), findsNothing);
    expect(find.byKey(const Key('table-previous-page')), findsNothing);
    expect(find.byKey(const Key('table-next-page')), findsNothing);
    expect(find.text('N'), findsOneWidget, reason: 'the header row stays');
  });

  testWidgets('table stretches to fill the container width', (tester) async {
    useDesktopViewport(tester, height: 800);
    await tester.pumpWidget(
      componentTestApp(
        SizedBox(
          width: 1200,
          child: AppDataTable<int>(
            columns: [
              AppTableColumn(id: 'col1', label: 'Col 1', cell: (n) => Text('$n')),
              AppTableColumn(id: 'col2', label: 'Col 2', cell: (n) => Text('$n')),
            ],
            rows: const [1, 2, 3],
            page: 0,
            pageSize: 20,
            totalItems: 3,
            onPageChanged: (_) {},
          ),
        ),
      ),
    );
    final dataTableWidth = tester.getSize(find.byType(DataTable)).width;
    expect(dataTableWidth, 1200);
  });

  testWidgets('table allows horizontal scrolling when container is smaller than content', (tester) async {
    useDesktopViewport(tester, height: 800);
    await tester.pumpWidget(
      componentTestApp(
        SizedBox(
          width: 200,
          child: AppDataTable<int>(
            columns: [
              AppTableColumn(id: 'col1', label: 'Long Column 1 Header', cell: (n) => Text('Row content $n')),
              AppTableColumn(id: 'col2', label: 'Long Column 2 Header', cell: (n) => Text('Row content $n')),
            ],
            rows: const [1, 2, 3],
            page: 0,
            pageSize: 20,
            totalItems: 3,
            onPageChanged: (_) {},
          ),
        ),
      ),
    );
    final dataTableWidth = tester.getSize(find.byType(DataTable)).width;
    expect(dataTableWidth, greaterThan(200));
  });
}
