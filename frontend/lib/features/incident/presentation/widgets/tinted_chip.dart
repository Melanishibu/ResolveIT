import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';

/// A small rounded label: tinted background, darker text of the same hue (all from theme tokens).
class TintedChip extends StatelessWidget {
  const TintedChip({super.key, required this.label, required this.colors});

  final String label;
  final ChipColors colors;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(context.radii.chip),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.chipHorizontal,
          vertical: spacing.chipVertical,
        ),
        child: Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
