import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/core/domain/role.dart';
import 'package:resolveit/features/users/widgets/role_label.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Role chip (built on AppChip, US-28). SUPPORT_AGENT is shown as "Technician".
class RoleChip extends StatelessWidget {
  const RoleChip(this.role, {super.key});

  final Role role;

  @override
  Widget build(BuildContext context) => AppChip(
    label: roleLabel(AppLocalizations.of(context), role),
    colors: context.appColors.roleChip,
  );
}
