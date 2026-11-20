import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/dev/component_gallery_view.dart';
import 'package:resolveit/app/router/app_router.dart';
import 'package:resolveit/app/theme/app_theme.dart';
import 'package:resolveit/l10n/app_localizations.dart';

import '../../support/component_test_app.dart';
import '../../support/test_app.dart';

// Scenario: Gallery is not part of release builds
//   Given a release build of the app
//   When I open /dev/components
//   Then the route does not exist
//
// `kDebugMode` is a compile-time constant and is always true under `flutter test`, so the release
// router is built the way the release composition root builds it: without dev routes. The real
// release build is checked separately (no gallery code in build/web/main.dart.js, see Evidence).

Future<void> _openGallery(WidgetTester tester, GoRouter router) async {
  useDesktopViewport(tester);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  router.go(ComponentGalleryView.path);
  await pumpFrames(tester);
}

void main() {
  testWidgets('Gallery is not part of release builds', (tester) async {
    await _openGallery(tester, buildAppRouter());

    expect(find.byType(ComponentGalleryView), findsNothing);
    expect(find.byKey(const Key('error-panel')), findsOneWidget);
    expect(find.text(l10nEn.errorResourceNotFoundTitle), findsOneWidget);
  });

  testWidgets('a debug build serves the gallery at /dev/components', (
    tester,
  ) async {
    await _openGallery(tester, buildAppRouter(devRoutes: devComponentRoutes()));

    expect(find.byType(ComponentGalleryView), findsOneWidget);
    expect(find.text(ComponentGalleryView.title), findsOneWidget);
  });
}
