import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/app/theme/app_colors.dart';

import '../../../support/source_scan.dart';

// Scenario: Components use theme tokens only
//   When I run flutter test
//   Then no file under lib/core/presentation/widgets contains a raw colour, TextStyle, fontSize
//   or numeric padding

double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('Components use theme tokens only', () {
    test(
      'no raw colour, TextStyle, fontSize or numeric padding in the library',
      () {
        final hits = forbiddenUsages(
          [
            RegExp(r'\bColor\s*\('),
            RegExp(r'\bColor\.from'),
            RegExp(r'\bColors\.'),
            RegExp(r'\bTextStyle\s*\('),
            RegExp(r'\bfontSize\s*:'),
            RegExp(r'\bEdgeInsets\.\w+\([^)]*\d'),
            RegExp(r'\bSizedBox\s*\([^)]*\b(?:width|height)\s*:\s*\d'),
            RegExp(r'\b(?:BorderRadius|Radius)\.circular\(\s*\d'),
            RegExp(r'\bsize\s*:\s*\d'),
          ],
          onlyPrefixes: ['core/presentation/widgets/'],
        );
        expect(hits, isEmpty, reason: hits.join('\n'));
      },
    );

    test('the new US-28 colour pairs meet WCAG AA (4.5:1)', () {
      final colors = AppColors.light;
      final pairs = <String, (Color, Color)>{
        'danger button': (colors.onDanger, colors.danger),
        'primary button': (colors.onPrimary, colors.primary),
        'secondary/text button': (colors.primary, colors.cardBackground),
        'success toast': (colors.success.foreground, colors.success.background),
        'role chip': (colors.roleChip.foreground, colors.roleChip.background),
        'active chip': (
          colors.activeChip.foreground,
          colors.activeChip.background,
        ),
        'inactive chip': (
          colors.inactiveChip.foreground,
          colors.inactiveChip.background,
        ),
        'secondary text': (colors.textSecondary, colors.cardBackground),
      };
      pairs.forEach((name, pair) {
        final ratio = _contrast(pair.$1, pair.$2);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$name has ${ratio.toStringAsFixed(2)}:1',
        );
      });
    });
  });
}
