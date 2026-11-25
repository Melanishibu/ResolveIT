import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'import_boundary_checker.dart';

// Scenario: Existing features follow the convention (RIT-US-29, AB#175)
//   Given the frontend code
//   When I list lib/features
//   Then every feature uses only the folders of the convention
void main() {
  test('Existing features follow the convention', () {
    final violations = conventionViolations(Directory('lib'));

    expect(violations, isEmpty, reason: violations.join('\n'));
    expect(
      Directory('lib/features').listSync().whereType<Directory>().map(
        (dir) => dir.uri.pathSegments[dir.uri.pathSegments.length - 2],
      ),
      containsAll(['auth', 'users', 'incident']),
      reason: 'identity was split into auth and users',
    );
    expect(Directory('lib/features/identity').existsSync(), isFalse);
  });

  test('a folder outside the convention is reported', () {
    final violations = conventionViolations(
      Directory('test/architecture/fixtures/convention_violations/lib'),
    );

    expect(
      violations,
      contains(
        startsWith(
          'features/sample/services/sample_service.dart is outside the feature folder convention',
        ),
      ),
    );
    expect(
      violations,
      contains(startsWith('features/Bad_Name/bad_name.dart is outside')),
      reason: 'feature folders are lowercase snake_case',
    );
    expect(
      violations,
      contains(startsWith('features/loose.dart is outside')),
      reason: 'files belong to a feature folder',
    );
  });
}
