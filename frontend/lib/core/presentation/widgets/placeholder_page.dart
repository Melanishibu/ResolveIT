import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Empty state for a menu destination whose screen arrives in a later story.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          key: const Key('page-title'),
          style: context.textTheme.headlineSmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: spacing.l),
        Card(
          key: const Key('placeholder-card'),
          child: Padding(
            padding: EdgeInsets.all(spacing.xl),
            child: Row(
              children: [
                Icon(Icons.construction_outlined, color: colors.textSecondary),
                SizedBox(width: spacing.m),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).placeholderComingSoon,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
