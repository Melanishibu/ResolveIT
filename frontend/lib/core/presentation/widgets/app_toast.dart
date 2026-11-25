import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';

/// Short, non-blocking **success** feedback (US-28), e.g. "Incident created".
///
/// Success only: errors always go through `ErrorPanel` / `showErrorDialog`. This file is one of
/// the two allowed exceptions in the US-02 free-text dialog scan (approved by Melani Shibu
/// 11/20/2026, AB#170).
abstract final class AppToast {
  static const toastKey = Key('app-toast');

  static void success(BuildContext context, String message) {
    final colors = context.appColors;
    final spacing = context.spacing;
    final tone = colors.success;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: toastKey,
          behavior: SnackBarBehavior.floating,
          backgroundColor: tone.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.radii.control),
          ),
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: tone.foreground),
              SizedBox(width: spacing.s),
              Expanded(
                child: Text(
                  message,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: tone.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
