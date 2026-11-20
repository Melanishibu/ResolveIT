import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'raw_control_guard.dart';

// Scenario: Raw Material controls are rejected in features
//   Given a file under lib/features uses ElevatedButton directly
//   When I run flutter test
//   Then the guard test fails naming the file and the App component to use instead
void main() {
  group('Raw Material controls are rejected in features', () {
    test('the guard names the file and the App component to use', () {
      final sampleLib = Directory(
        'test/architecture/fixtures/raw_controls/lib',
      );

      final violations = rawControlViolations(sampleLib);

      expect(
        violations,
        anyElement(
          allOf(
            startsWith('features/sample/presentation/sample_view.dart:'),
            endsWith(
              'uses ElevatedButton; use AppButton (variant: primary) '
              'from core/presentation/widgets/widgets.dart instead',
            ),
          ),
        ),
      );
    });

    test('lib/features uses only the shared App components', () {
      final violations = rawControlViolations(Directory('lib'));
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    test('every listed raw control has a replacement', () {
      expect(rawControlReplacements.keys, [
        'ElevatedButton',
        'FilledButton',
        'OutlinedButton',
        'TextButton',
        'TextField',
        'TextFormField',
        'DropdownButton',
        'DropdownMenu',
        'DataTable',
        'AlertDialog',
        'SnackBar',
      ]);
    });
  });
}
