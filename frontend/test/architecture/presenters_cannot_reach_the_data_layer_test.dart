import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'import_boundary_checker.dart';

// Scenario: Presenters cannot reach the data layer (RIT-US-29, AB#175)
//   Given a presenter imports data/repository
//   When I run flutter test
//   Then the import-boundary test fails
void main() {
  test('Presenters cannot reach the data layer', () {
    final violations = importBoundaryViolations(
      Directory('test/architecture/fixtures/convention_violations/lib'),
    );

    expect(
      violations,
      contains(
        'features/sample/presentation/presenter/sample_presenter.dart (presentation/presenter) imports '
        'package:resolveit/features/sample/data/repository/sample_repository_impl.dart; '
        'rule: presentation/presenter must never import the data layer',
      ),
    );
  });
}
