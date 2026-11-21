import 'package:flutter/material.dart';
import 'package:resolveit/features/auth/auth.dart';
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

/// Whether [role] may open [destination]'s page. This is the route guard's rule, taken from the
/// permission table in the common rules (AB#14), and it is deliberately separate from [menuFor]:
/// a role may open a page that its menu doesn't list. Example (bug AB#181): the Admin may create
/// incidents and reaches `/incidents/new` through the "+ Create Incident" button (AB#39), but the
/// Admin menu has no Create Incident entry (Update 01). The backend still enforces every rule.
bool mayOpen(Role role, MenuDestination destination) => switch (destination) {
  MenuDestination.createIncident => role == Role.admin || role == Role.employee,
  _ => menuFor(role).contains(destination),
};

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
