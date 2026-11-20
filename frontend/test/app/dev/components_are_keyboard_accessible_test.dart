import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/app/dev/component_gallery_view.dart';

import '../../support/component_test_app.dart';

// Scenario: Components are keyboard accessible
//   Given the gallery
//   When I move through it with the Tab key
//   Then every interactive component receives focus and has a semantics label
void main() {
  testWidgets('Components are keyboard accessible', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpGallery(tester);

    final expected = ComponentGalleryView.interactiveKeys.toSet();
    final reached = <Key>{};
    for (var i = 0; i < 300 && reached.length < expected.length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus?.context;
      focused?.visitAncestorElements((element) {
        final key = element.widget.key;
        if (key != null && expected.contains(key)) reached.add(key);
        return true;
      });
      if (focused?.widget.key case final Key key when expected.contains(key)) {
        reached.add(key);
      }
    }

    expect(
      expected.difference(reached),
      isEmpty,
      reason: 'never reached with the Tab key',
    );
    // Every tappable element has a semantics label.
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
