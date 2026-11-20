import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/app_button.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Loading state of a screen or section (US-28).
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: context.appColors.primary,
            semanticsLabel:
                message ?? AppLocalizations.of(context).loadingLabel,
          ),
          if (message != null) ...[
            SizedBox(height: spacing.m),
            Text(
              message!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state: icon, message and an optional action (US-28).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.appColors;
    final label = actionLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: spacing.emptyStateIcon, color: colors.textSecondary),
        SizedBox(height: spacing.m),
        Text(
          message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyLarge?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        if (label != null && onAction != null) ...[
          SizedBox(height: spacing.l),
          AppButton(label: label, onPressed: onAction),
        ],
      ],
    );
  }
}
