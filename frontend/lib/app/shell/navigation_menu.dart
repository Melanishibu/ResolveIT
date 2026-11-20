import 'package:flutter/material.dart';
import 'package:resolveit/features/identity/identity.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// A screen reachable from the side menu. Logout is a separate action, shown for every role.
enum MenuDestination {
  dashboard('/dashboard', Icons.dashboard_outlined),
  incidents('/incidents', Icons.assignment_outlined),
  myIncidents('/my-incidents', Icons.assignment_ind_outlined),
  createIncident('/incidents/new', Icons.add_circle_outline),
  userManagement('/admin/users', Icons.manage_accounts_outlined),
  profile('/profile', Icons.person_outline);

  const MenuDestination(this.path, this.icon);

  final String path;
  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
    MenuDestination.dashboard => l10n.menuDashboard,
    MenuDestination.incidents => l10n.menuIncidents,
    MenuDestination.myIncidents => l10n.menuMyIncidents,
    MenuDestination.createIncident => l10n.menuCreateIncident,
    MenuDestination.userManagement => l10n.menuUserManagement,
    MenuDestination.profile => l10n.menuProfile,
  };

  /// The destination whose path is the longest prefix of [location] (so `/incidents/new`
  /// selects Create Incident, not Incidents).
  static MenuDestination? forLocation(String location) {
    MenuDestination? best;
    for (final destination in values) {
      final matches =
          location == destination.path ||
          location.startsWith('${destination.path}/');
      if (matches &&
          (best == null || destination.path.length > best.path.length)) {
        best = destination;
      }
    }
    return best;
  }
}

/// Menu per role (story AB#11, Update 01 of 11/20/2026). The backend enforces access;
/// this only decides what the menu offers.
List<MenuDestination> menuFor(Role role) => switch (role) {
  Role.admin => const [
    MenuDestination.dashboard,
    MenuDestination.incidents,
    MenuDestination.userManagement,
    MenuDestination.profile,
  ],
  Role.supportAgent => const [
    MenuDestination.dashboard,
    MenuDestination.myIncidents,
    MenuDestination.profile,
  ],
  Role.employee => const [
    MenuDestination.dashboard,
    MenuDestination.myIncidents,
    MenuDestination.createIncident,
    MenuDestination.profile,
  ],
};
