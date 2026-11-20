import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/app_button.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Builds a field label with an optional required asterisk (shared by the form components).
Widget fieldLabel(
  BuildContext context,
  String label, {
  required bool isRequired,
}) => Text.rich(
  TextSpan(
    text: label,
    children: [
      if (isRequired)
        TextSpan(
          text: ' *',
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.appColors.error.foreground,
          ),
        ),
    ],
  ),
);

/// The only text input features use (US-28): label with required asterisk, hint, error text,
/// character counter and a password show/hide toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.isRequired = false,
    this.hint,
    this.errorText,
    this.maxLength,
    this.isPassword = false,
    this.controller,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final bool isRequired;
  final String? hint;
  final String? errorText;
  final int? maxLength;
  final bool isPassword;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = context.textTheme;
    final colors = context.appColors;
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      obscureText: widget.isPassword && _obscured,
      keyboardType: widget.keyboardType,
      style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        label: fieldLabel(context, widget.label, isRequired: widget.isRequired),
        hintText: widget.hint,
        errorText: widget.errorText,
        counterStyle: textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
        ),
        suffixIcon: widget.isPassword
            ? AppIconButton(
                key: const Key('password-toggle'),
                icon: _obscured ? Icons.visibility : Icons.visibility_off,
                semanticLabel: _obscured
                    ? l10n.passwordShow
                    : l10n.passwordHide,
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
