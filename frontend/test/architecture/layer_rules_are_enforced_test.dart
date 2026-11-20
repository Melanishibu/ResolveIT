import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'import_boundary_checker.dart';

// Scenario: Layer rules are enforced (RIT-US-29, AB#175)
//   Given a file in domain/usecase imports package:dio
//   When I run flutter test
//   Then the import-boundary test fails naming the file and the rule
void main() {
  test('Layer rules are enforced', () {
    final violations = importBoundaryViolations(
      Directory('test/architecture/fixtures/convention_violations/lib'),
    );

    expect(
      violations,
      contains(
        'features/sample/domain/usecase/sample_usecase.dart (domain/usecase) imports package:dio/dio.dart; '
        'rule: domain/usecase must never import Dio',
      ),
    );
  });
}
