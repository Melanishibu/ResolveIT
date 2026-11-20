// ARCH-DEVIATION: D2 – no Apex UI access; Material widgets; approved by Melani Shibu 11/19/2026
//
// Composition root (AB#11): provider scope, router, theme and localisation. Only this folder
// wires concrete adapters to ports.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:resolveit/app/config/http_providers.dart';
import 'package:resolveit/app/router/app_router.dart';
import 'package:resolveit/app/theme/app_theme.dart';
import 'package:resolveit/features/identity/identity.dart';
import 'package:resolveit/l10n/app_localizations.dart';

class ResolveItApp extends StatelessWidget {
  const ResolveItApp({super.key, this.overrides = const []});

  /// Test seam: replace ports (for example the current-user gateway) with fakes.
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      // Composition root: the identity feature talks to the shared API client (AB#13).
      identityHttpClientProvider.overrideWith(
        (ref) => ref.watch(apiClientProvider),
      ),
      ...overrides,
    ],
    // Failures are shown to the user through the error panel, not retried silently.
    retry: (retryCount, error) => null,
    child: const _ResolveItRouterApp(),
  );
}

class _ResolveItRouterApp extends ConsumerWidget {
  const _ResolveItRouterApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: ref.watch(appRouterProvider),
  );
}
