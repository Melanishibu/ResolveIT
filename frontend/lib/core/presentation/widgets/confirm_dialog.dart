import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/app_button.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Asks the user to confirm an action (US-28). Returns true only when they confirm.
///
/// This file is one of the two allowed exceptions in the US-02 free-text dialog scan
/// (approved by Melani Shibu 11/20/2026, AB#170). Errors never use it: they go through
/// `ErrorPanel` / `showErrorDialog`.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool isDanger = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      isDanger: isDanger,
    ),
  );
  return confirmed ?? false;
}

/// The dialog shown by [showConfirmDialog]; danger variant for destructive actions.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.isDanger = false,
  });

  final String title;
  final String message;
  final String? confirmLabel;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return AlertDialog(
      title: Text(
        title,
        style: context.textTheme.titleLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.spacing.dialogMaxWidth),
        child: Text(
          message,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
          ),
        ),
      ),
      actions: [
        AppButton(
          key: const Key('confirm-dialog-cancel'),
          label: l10n.confirmCancel,
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          key: const Key('confirm-dialog-confirm'),
          label: confirmLabel ?? l10n.confirmConfirm,
          variant: isDanger
              ? AppButtonVariant.danger
              : AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
