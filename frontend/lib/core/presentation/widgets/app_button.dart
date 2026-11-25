import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The visual weight of an [AppButton].
enum AppButtonVariant { primary, secondary, text, danger }

/// The only button features use (US-28). While [isLoading] is true, or when [onPressed] is null,
/// the button is disabled and [onPressed] is never called; loading also shows a spinner.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.spacing;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.radii.control),
    );
    final minimumSize = Size(
      spacing.controlMinHeight,
      spacing.controlMinHeight,
    );
    final callback = isLoading ? null : onPressed;

    final (Color background, Color foreground) = switch (variant) {
      AppButtonVariant.primary => (colors.primary, colors.onPrimary),
      AppButtonVariant.danger => (colors.danger, colors.onDanger),
      AppButtonVariant.secondary ||
      AppButtonVariant.text => (colors.cardBackground, colors.primary),
    };

    final Widget? leading = isLoading
        ? SizedBox(
            key: const Key('app-button-spinner'),
            width: spacing.spinnerSize,
            height: spacing.spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: spacing.spinnerStroke,
              color: foreground,
              semanticsLabel: AppLocalizations.of(context).loadingLabel,
            ),
          )
        : (icon == null ? null : Icon(icon));
    final text = Text(label);

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        final style = FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          // A loading button keeps its colours; a disabled one uses the default disabled look.
          disabledBackgroundColor: isLoading ? background : null,
          disabledForegroundColor: isLoading ? foreground : null,
          minimumSize: minimumSize,
          shape: shape,
        );
        return leading == null
            ? FilledButton(onPressed: callback, style: style, child: text)
            : FilledButton.icon(
                onPressed: callback,
                style: style,
                icon: leading,
                label: text,
              );
      case AppButtonVariant.secondary:
        final style = OutlinedButton.styleFrom(
          foregroundColor: foreground,
          disabledForegroundColor: isLoading ? foreground : null,
          side: BorderSide(
            color: callback == null ? colors.border : foreground,
          ),
          minimumSize: minimumSize,
          shape: shape,
        );
        return leading == null
            ? OutlinedButton(onPressed: callback, style: style, child: text)
            : OutlinedButton.icon(
                onPressed: callback,
                style: style,
                icon: leading,
                label: text,
              );
      case AppButtonVariant.text:
        final style = TextButton.styleFrom(
          foregroundColor: foreground,
          disabledForegroundColor: isLoading ? foreground : null,
          minimumSize: minimumSize,
          shape: shape,
        );
        return leading == null
            ? TextButton(onPressed: callback, style: style, child: text)
            : TextButton.icon(
                onPressed: callback,
                style: style,
                icon: leading,
                label: text,
              );
    }
  }
}

/// Icon-only button. [semanticLabel] is required: it is the tooltip and what screen readers say.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon),
    tooltip: semanticLabel,
    color: context.appColors.textSecondary,
    onPressed: onPressed,
  );
}
