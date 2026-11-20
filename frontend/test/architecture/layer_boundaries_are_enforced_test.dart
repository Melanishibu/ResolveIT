import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'import_boundary_checker.dart';

// Scenario: Layer boundaries are enforced
//   Given a file in a domain folder imports package:flutter
//   When I run flutter test
//   Then the import-boundary test fails
void main() {
  test('Layer boundaries are enforced', () {
    final sampleLib = Directory(
      'test/architecture/fixtures/domain_imports_flutter/lib',
    );

    final violations = importBoundaryViolations(sampleLib);

    expect(
      violations,
      contains(
        'features/sample/domain/sample_entity.dart (domain) imports package:flutter/widgets.dart',
      ),
      reason:
          'the same check that guards lib/ must report a domain file importing Flutter',
    );
  });
}
