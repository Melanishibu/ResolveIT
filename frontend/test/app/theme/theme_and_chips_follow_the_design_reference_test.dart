import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/app/app.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/features/auth/auth.dart';
import 'package:resolveit/features/incident/incident.dart';

import '../../support/source_scan.dart';
import '../../support/test_app.dart';

// Scenario: Theme and chips follow the design reference
//   Given the app shell is open
//   When I compare it with the UI reference
//   Then the sidebar, cards and priority/status chip colours match the reference, using theme tokens only
//
// The pixel-level visual comparison with resolveit-ui-mockups.png is Melani's QA (#22); this test
// proves the reference tokens are set, used, readable (WCAG AA) and the only source of styling.

double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final colors = AppColors.light;

  group('Theme and chips follow the design reference', () {
    test('tokens carry the colours read from the UI reference', () {
      expect(
        colors.sidebarBackground,
        const Color(0xFF132A5E),
        reason: 'navy sidebar',
      );
      expect(
        colors.sidebarForeground,
        const Color(0xFFFFFFFF),
        reason: 'white sidebar text',
      );
      expect(colors.primary, const Color(0xFF2563EB), reason: 'primary blue');
      expect(
        colors.pageBackground,
        const Color(0xFFF4F6FA),
        reason: 'light grey page',
      );
      expect(
        colors.cardBackground,
        const Color(0xFFFFFFFF),
        reason: 'white cards',
      );

      const priorityHues = {
        Priority.low: Color(0xFF16A34A),
        Priority.medium: Color(0xFFEA8C00),
        Priority.high: Color(0xFFDC2626),
        Priority.critical: Color(0xFF991B1B),
      };
      priorityHues.forEach((priority, hue) {
        expect(
          PriorityChip.colorsFor(colors, priority).hue,
          hue,
          reason: priority.code,
        );
      });
      const statusHues = {
        IncidentStatus.open: Color(0xFF2563EB),
        IncidentStatus.assigned: Color(0xFF7C3AED),
        IncidentStatus.inProgress: Color(0xFFEA8C00),
        IncidentStatus.resolved: Color(0xFF16A34A),
        IncidentStatus.closed: Color(0xFF6B7280),
      };
      statusHues.forEach((status, hue) {
        expect(
          StatusChip.colorsFor(colors, status).hue,
          hue,
          reason: status.code,
        );
      });
    });

    test('every chip text meets WCAG AA (4.5:1) on its tinted background', () {
      for (final chip in colors.allChips) {
        final ratio = contrastRatio(chip.foreground, chip.background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'chip ${chip.hue} has contrast ${ratio.toStringAsFixed(2)}:1',
        );
      }
      expect(
        contrastRatio(colors.sidebarForeground, colors.sidebarBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(
          colors.sidebarActiveForeground,
          colors.sidebarActiveBackground,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('priority and status chips render with their token colours', (
      tester,
    ) async {
      final chips = <(Widget, ChipColors)>[
        for (final p in Priority.values)
          (PriorityChip(p), PriorityChip.colorsFor(colors, p)),
        for (final s in IncidentStatus.values)
          (StatusChip(s), StatusChip.colorsFor(colors, s)),
      ];
      for (final (chip, expected) in chips) {
        await tester.pumpWidget(themedTestApp(chip));

        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byWidget(chip),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(
          (box.decoration as BoxDecoration).color,
          expected.background,
          reason: '$chip',
        );
        final label = tester.widget<Text>(
          find.descendant(of: find.byWidget(chip), matching: find.byType(Text)),
        );
        expect(label.style?.color, expected.foreground, reason: '$chip');
      }
    });

    testWidgets(
      'the shell uses the navy sidebar, a highlighted active item and white rounded cards',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        // AB#13 removed the placeholder user: a fake repository supplies the signed-in user.
        await tester.pumpWidget(
          ResolveItApp(
            overrides: [
              currentUserRepositoryProvider.overrideWithValue(
                FakeCurrentUserRepository.signedInAs(Role.admin),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        final sidebar = tester.widget<Container>(
          find.byKey(const Key('app-sidebar')),
        );
        expect(sidebar.color, colors.sidebarBackground);

        Material itemMaterial(String name) => tester.widget<Material>(
          find.descendant(
            of: find.byKey(Key('menu-item-$name')),
            matching: find.byType(Material),
          ),
        );
        expect(
          itemMaterial('dashboard').color,
          colors.sidebarActiveBackground,
          reason: 'active item',
        );
        expect(
          itemMaterial('profile').color,
          colors.sidebarBackground,
          reason: 'inactive item',
        );

        final context = tester.element(
          find.byKey(const Key('app-sidebar')),
        );
        final theme = Theme.of(context);
        expect(theme.scaffoldBackgroundColor, colors.pageBackground);
        expect(theme.cardTheme.color, colors.cardBackground);
        expect(
          theme.cardTheme.elevation,
          greaterThan(0),
          reason: 'soft shadow',
        );
        expect(
          theme.cardTheme.shape,
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.radii.card),
          ),
        );
      },
    );

    test(
      'widgets outside lib/app/theme use theme tokens only (no raw colours, text styles or magic sizes)',
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
          ],
          allowedPrefixes: ['app/theme/'],
        );
        expect(hits, isEmpty, reason: hits.join('\n'));
      },
    );
  });
}
