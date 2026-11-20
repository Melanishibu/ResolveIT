import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/app_text_field.dart';

/// One selectable value of an [AppDropdown].
@immutable
final class AppDropdownOption<T> {
  const AppDropdownOption(this.value, this.label);

  final T value;
  final String label;
}

/// Labelled single-select (US-28) with required marker and error text. Controlled: the
/// presenter owns [value] and updates it from [onChanged].
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.errorText,
    this.hint,
  });

  final String label;
  final List<AppDropdownOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final bool isRequired;
  final String? errorText;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return InputDecorator(
      isEmpty: value == null,
      decoration: InputDecoration(
        label: fieldLabel(context, label, isRequired: isRequired),
        hintText: hint,
        errorText: errorText,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          onChanged: onChanged,
          style: textTheme.bodyLarge?.copyWith(
            color: context.appColors.textPrimary,
          ),
          items: [
            for (final option in options)
              DropdownMenuItem<T>(
                value: option.value,
                child: Text(option.label),
              ),
          ],
        ),
      ),
    );
  }
}
