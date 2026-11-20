import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';

/// Page title, optional subtitle and actions (US-28). The title carries the key `page-title`,
/// so every screen exposes its title the same way.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  static const titleKey = Key('page-title');

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.spacing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                key: titleKey,
                style: context.textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: spacing.xs),
                Text(
                  subtitle!,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final action in actions) ...[SizedBox(width: spacing.s), action],
      ],
    );
  }
}
