import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'import_boundary_checker.dart';

void main() {
  test(
    'layers respect the dependency rule and features use public barrels only',
    () {
      final violations = importBoundaryViolations(Directory('lib'));
      expect(violations, isEmpty, reason: violations.join('\n'));
    },
  );
}
