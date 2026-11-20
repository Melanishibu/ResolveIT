import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/users/users.dart';
import 'package:resolveit/features/incident/incident.dart';

import '../../support/component_test_app.dart';

// Scenario: Gallery shows every component in every state
//   Given a debug build of the app
//   When I open /dev/components
//   Then every component of the library is shown in each of its states

/// Public widget classes declared in the component library folder.
List<String> _libraryWidgetClasses() {
  final declaration = RegExp(
    r'^class\s+([A-Z]\w*)(?:<[^>]*>)?\s+extends\s+(?:StatelessWidget|StatefulWidget)',
    multiLine: true,
  );
  return [
    for (final file in Directory(
      'lib/core/presentation/widgets',
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart')))
      ...declaration
          .allMatches(file.readAsStringSync())
          .map((m) => m.group(1)!),
    'ErrorPanel', // re-exported from core/presentation/errors (US-02)
  ];
}

void main() {
  group('Gallery shows every component in every state', () {
    test(
      'every public component of the library appears in the gallery source',
      () {
        final gallery = File(
          'lib/app/dev/component_gallery_view.dart',
        ).readAsStringSync();
        // Shown through a helper function rather than constructed directly.
        const shownVia = {'ConfirmDialog': 'showConfirmDialog'};
        final missing = [
          for (final name in _libraryWidgetClasses())
            if (!RegExp(
              '\\b${shownVia[name] ?? name}\\s*[(<]',
            ).hasMatch(gallery))
              name,
        ];
        expect(missing, isEmpty, reason: 'not shown in the gallery: $missing');
        expect(gallery, contains('showConfirmDialog('));
        expect(gallery, contains('AppToast.success('));
      },
    );

    testWidgets('the gallery renders every component and state', (
      tester,
    ) async {
      await pumpGallery(tester);
      expect(tester.takeException(), isNull);

      for (final type in [
        AppButton,
        AppIconButton,
        AppTextField,
        AppDropdown<String>,
        AppSearchField,
        AppFormSection,
        AppCard,
        StatCard,
        AppChip,
        AvatarInitials,
        PageHeader,
        AppTabs,
        LoadingState,
        EmptyState,
        ErrorPanel,
        PlaceholderPage,
        PriorityChip,
        StatusChip,
        RoleChip,
        ActiveChip,
      ]) {
        expect(find.byType(type), findsWidgets, reason: '$type');
      }
      expect(find.byKey(const Key('gallery-table')), findsOneWidget);

      // Button states: normal, disabled, loading for every variant.
      for (final variant in AppButtonVariant.values) {
        for (final state in ['', '-disabled', '-loading']) {
          expect(
            find.byKey(Key('gallery-button-${variant.name}$state')),
            findsOneWidget,
            reason: '${variant.name}$state',
          );
        }
      }
      // Field, chip and feedback states.
      expect(find.text('Enter a title.'), findsOneWidget);
      expect(find.text('0/120'), findsOneWidget);
      expect(
        find.byKey(const Key('gallery-text-field-disabled')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('gallery-dropdown-error')), findsOneWidget);
      expect(
        find.byType(PriorityChip),
        findsNWidgets(Priority.values.length + 20),
      );
      expect(
        find.byType(StatusChip),
        findsNWidgets(IncidentStatus.values.length),
      );
      expect(find.byType(RoleChip), findsNWidgets(Role.values.length));
      expect(find.byType(ActiveChip), findsNWidgets(2));
      expect(find.byKey(const Key('gallery-error-warning')), findsOneWidget);
      expect(find.byKey(const Key('gallery-error-error')), findsOneWidget);
      expect(find.byKey(const Key('gallery-table-empty')), findsOneWidget);
      expect(find.text('Showing 1–20 of 45'), findsOneWidget);
    });

    testWidgets('the gallery opens the confirm dialog and the success toast', (
      tester,
    ) async {
      await pumpGallery(tester);

      await tester.tap(find.byKey(const Key('gallery-confirm-danger-open')));
      await pumpFrames(tester);
      expect(find.byType(ConfirmDialog), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-dialog-cancel')));
      await pumpFrames(tester);
      expect(find.byType(ConfirmDialog), findsNothing);

      await tester.tap(find.byKey(const Key('gallery-toast-open')));
      await tester.pump();
      expect(find.byKey(AppToast.toastKey), findsOneWidget);
      // Let the toast time out so no timer is left pending.
      await tester.pump(const Duration(seconds: 5));
      await pumpFrames(tester);
    });
  });
}
