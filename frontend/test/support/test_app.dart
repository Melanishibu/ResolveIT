import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/app_theme.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/identity/identity.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// English strings, as the app shows them (D3).
final AppLocalizations l10nEn = lookupAppLocalizations(const Locale('en'));

/// Hosts [child] with the real app theme and localisation.
Widget themedTestApp(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

/// A current-user gateway that answers with a fixed result.
final class FakeCurrentUserGateway implements CurrentUserGateway {
  FakeCurrentUserGateway.signedInAs(
    Role role, {
    String displayName = 'Sarah Johnson',
  }) : _result = Success(
         CurrentUser(id: 'u-1', displayName: displayName, role: role),
       );

  FakeCurrentUserGateway.failing(Failure<CurrentUser> failure)
    : _result = failure;

  final Result<CurrentUser> _result;

  @override
  Future<Result<CurrentUser>> currentUser() async => _result;
}
