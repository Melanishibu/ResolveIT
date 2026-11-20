import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The "We're here to help!" panel beside the create-incident form (RIT-US-09 UI reference).
class HelpPanel extends StatelessWidget {
  const HelpPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final colors = context.appColors;
    final text = context.textTheme;
    return AppCard(
      key: const Key('create-incident-help'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent,
            size: spacing.illustrationIcon,
            color: colors.primary,
            semanticLabel: l10n.createIncidentHelpTitle,
          ),
          SizedBox(height: spacing.l),
          Text(
            l10n.createIncidentHelpTitle,
            style: text.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing.s),
          Text(
            l10n.createIncidentHelpBody,
            style: text.bodyMedium?.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
