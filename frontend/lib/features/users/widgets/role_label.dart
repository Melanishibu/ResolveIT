import 'package:resolveit/core/domain/role.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The user-facing role name. SUPPORT_AGENT is shown as "Technician" everywhere.
String roleLabel(AppLocalizations l10n, Role role) => switch (role) {
  Role.admin => l10n.roleAdmin,
  Role.supportAgent => l10n.roleSupportAgent,
  Role.employee => l10n.roleEmployee,
};
