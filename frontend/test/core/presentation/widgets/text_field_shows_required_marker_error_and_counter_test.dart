import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';

import '../../../support/component_test_app.dart';

// Scenario: Text field shows required marker, error and counter
//   Given a required AppTextField with a 120-character limit and an error message
//   When it is rendered
//   Then the label shows an asterisk, the error text is shown and the counter reads "0/120"
void main() {
  testWidgets('Text field shows required marker, error and counter', (
    tester,
  ) async {
    await tester.pumpWidget(
      componentTestApp(
        const AppTextField(
          label: 'Title',
          isRequired: true,
          maxLength: 120,
          errorText: 'Enter a title.',
        ),
      ),
    );

    expect(find.text('Title *', findRichText: true), findsOneWidget);
    expect(find.text('Enter a title.'), findsOneWidget);
    expect(find.text('0/120'), findsOneWidget);
  });

  testWidgets('an optional field has no asterisk', (tester) async {
    await tester.pumpWidget(
      componentTestApp(const AppTextField(label: 'Description')),
    );

    expect(find.text('Description', findRichText: true), findsOneWidget);
    expect(find.text('Description *', findRichText: true), findsNothing);
  });
}
