import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';

import '../../../support/component_test_app.dart';
import '../../../support/test_app.dart';

// Scenario: Password field can be revealed
//   Given an AppTextField for a password
//   When the show/hide icon is tapped
//   Then the text becomes visible and the icon changes
void main() {
  testWidgets('Password field can be revealed', (tester) async {
    await tester.pumpWidget(
      componentTestApp(const AppTextField(label: 'Password', isPassword: true)),
    );
    bool obscured() =>
        tester.widget<EditableText>(find.byType(EditableText)).obscureText;

    expect(obscured(), isTrue);
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byTooltip(l10nEn.passwordShow), findsOneWidget);

    await tester.tap(find.byKey(const Key('password-toggle')));
    await tester.pump();

    expect(obscured(), isFalse, reason: 'the text becomes visible');
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsNothing);
    expect(find.byTooltip(l10nEn.passwordHide), findsOneWidget);
  });
}
