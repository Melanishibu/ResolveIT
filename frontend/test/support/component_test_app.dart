import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resolveit/app/dev/component_gallery_view.dart';
import 'package:resolveit/app/theme/app_theme.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Hosts [child] (top-aligned, scrollable) with the real theme and localisation.
Widget componentTestApp(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

/// A large desktop viewport, reset after the test.
void useDesktopViewport(WidgetTester tester, {double height = 900}) {
  tester.view.physicalSize = Size(1440, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The gallery shows spinners that animate forever, so `pumpAndSettle` would never settle:
/// pump enough fixed frames for route and dialog transitions to finish instead.
Future<void> pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps the component gallery on its own (the route test covers the router).
Future<void> pumpGallery(WidgetTester tester) async {
  // Tall enough that the whole gallery is laid out at once.
  useDesktopViewport(tester, height: 8000);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ComponentGalleryView(),
    ),
  );
  await pumpFrames(tester);
}
