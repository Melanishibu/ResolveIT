import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';

import '../../../support/component_test_app.dart';

// Scenario: Loading button cannot be pressed twice
//   Given a primary AppButton in loading state
//   When it is tapped
//   Then its action is not called and a spinner is shown
void main() {
  testWidgets('Loading button cannot be pressed twice', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      componentTestApp(
        AppButton(label: 'Save', isLoading: true, onPressed: () => calls++),
      ),
    );

    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    await tester.pump();

    expect(calls, 0);
    expect(find.byKey(const Key('app-button-spinner')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('the same button calls its action once it is not loading', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      componentTestApp(AppButton(label: 'Save', onPressed: () => calls++)),
    );

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(calls, 1);
    expect(find.byKey(const Key('app-button-spinner')), findsNothing);
  });

  testWidgets('a disabled button (no action) ignores taps', (tester) async {
    await tester.pumpWidget(
      componentTestApp(
        const AppButton(
          label: 'Delete',
          variant: AppButtonVariant.danger,
          onPressed: null,
        ),
      ),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });
}
