import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Whether a user account is active (built on AppChip, US-28).
class ActiveChip extends StatelessWidget {
  const ActiveChip({super.key, required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return AppChip(
      label: isActive ? l10n.userActive : l10n.userInactive,
      colors: isActive ? colors.activeChip : colors.inactiveChip,
    );
  }
}
