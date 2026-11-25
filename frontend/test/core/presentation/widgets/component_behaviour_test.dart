import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/app/theme/app_colors.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/users/users.dart';

import '../../../support/component_test_app.dart';
import '../../../support/test_app.dart';

void main() {
  testWidgets('AppSearchField calls back 300 ms after the last keystroke', (
    tester,
  ) async {
    final searches = <String>[];
    await tester.pumpWidget(
      componentTestApp(AppSearchField(onSearch: searches.add)),
    );

    await tester.enterText(find.byType(TextField), 'net');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'network');
    await tester.pump(const Duration(milliseconds: 299));
    expect(searches, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    expect(searches, ['network']);

    await tester.tap(find.byKey(const Key('search-clear')));
    await tester.pump();
    expect(searches, ['network', '']);
  });

  testWidgets('AppDropdown reports the chosen option', (tester) async {
    String? chosen;
    await tester.pumpWidget(
      componentTestApp(
        AppDropdown<String>(
          label: 'Category',
          isRequired: true,
          value: 'HARDWARE',
          options: const [
            AppDropdownOption('HARDWARE', 'Hardware'),
            AppDropdownOption('NETWORK', 'Network'),
          ],
          onChanged: (value) => chosen = value,
        ),
      ),
    );
    expect(find.text('Category *', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Hardware'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Network').last);
    await tester.pumpAndSettle();

    expect(chosen, 'NETWORK');
  });

  testWidgets(
    'AppDropdown with a null value option keeps the field non-empty so label floats',
    (tester) async {
      await tester.pumpWidget(
        componentTestApp(
          AppDropdown<String?>(
            label: 'Role',
            value: null,
            options: const [
              AppDropdownOption(null, 'All Roles'),
              AppDropdownOption('ADMIN', 'Admin'),
            ],
            onChanged: (_) {},
          ),
        ),
      );
      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(decorator.isEmpty, isFalse);
      expect(find.text('All Roles'), findsOneWidget);
    },
  );

  testWidgets('showConfirmDialog returns true on confirm and false on cancel', (
    tester,
  ) async {
    final results = <bool>[];
    await tester.pumpWidget(
      componentTestApp(
        Builder(
          builder: (context) => AppButton(
            label: 'Ask',
            onPressed: () async => results.add(
              await showConfirmDialog(
                context,
                title: 'Close incident?',
                message: 'It will be closed.',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.confirmConfirm));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.confirmCancel));
    await tester.pumpAndSettle();

    expect(results, [true, false]);
  });

  testWidgets('AppToast shows success feedback in the success colours', (
    tester,
  ) async {
    await tester.pumpWidget(
      componentTestApp(
        Builder(
          builder: (context) => AppButton(
            label: 'Save',
            onPressed: () => AppToast.success(context, 'Incident created.'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    final toast = tester.widget<SnackBar>(find.byKey(AppToast.toastKey));
    expect(toast.backgroundColor, AppColors.light.success.background);
    expect(find.text('Incident created.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('EmptyState offers its action', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      componentTestApp(
        EmptyState(
          icon: Icons.inbox_outlined,
          message: 'No incidents yet.',
          actionLabel: 'Create Incident',
          onAction: () => pressed = true,
        ),
      ),
    );

    await tester.tap(find.text('Create Incident'));
    expect(pressed, isTrue);
  });

  testWidgets(
    'RoleChip shows SUPPORT_AGENT as Technician; ActiveChip colours',
    (tester) async {
      await tester.pumpWidget(
        componentTestApp(
          const Column(
            children: [
              RoleChip(Role.supportAgent),
              ActiveChip(isActive: true),
              ActiveChip(isActive: false),
            ],
          ),
        ),
      );

      expect(find.text('Technician'), findsOneWidget);
      expect(find.textContaining('SUPPORT_AGENT'), findsNothing);
      Color? textColour(String text) =>
          tester.widget<Text>(find.text(text)).style?.color;
      expect(
        textColour(l10nEn.userActive),
        AppColors.light.activeChip.foreground,
      );
      expect(
        textColour(l10nEn.userInactive),
        AppColors.light.inactiveChip.foreground,
      );
    },
  );

  testWidgets('PageHeader shows title, subtitle and actions', (tester) async {
    await tester.pumpWidget(
      componentTestApp(
        PageHeader(
          title: 'My Incidents',
          subtitle: 'Track the status of your IT requests',
          actions: [AppButton(label: 'Create Incident', onPressed: () {})],
        ),
      ),
    );

    expect(find.byKey(PageHeader.titleKey), findsOneWidget);
    expect(find.text('Track the status of your IT requests'), findsOneWidget);
    expect(find.text('Create Incident'), findsOneWidget);
  });

  testWidgets('AppTabs switches content', (tester) async {
    await tester.pumpWidget(
      componentTestApp(
        const AppTabs(
          tabs: [
            AppTab(label: 'Personal Info', child: Text('Personal info tab')),
            AppTab(label: 'Security', child: Text('Security tab')),
          ],
        ),
      ),
    );
    expect(find.text('Personal info tab'), findsOneWidget);

    await tester.tap(find.text('Security'));
    await tester.pumpAndSettle();

    expect(find.text('Security tab'), findsOneWidget);
    expect(find.text('Personal info tab'), findsNothing);
  });
}
