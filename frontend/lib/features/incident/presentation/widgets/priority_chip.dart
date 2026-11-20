import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/features/incident/domain/value_objects/priority.dart';
import 'package:resolveit/features/incident/presentation/widgets/tinted_chip.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Priority chip: LOW green, MEDIUM orange, HIGH red, CRITICAL dark red.
class PriorityChip extends StatelessWidget {
  const PriorityChip(this.priority, {super.key});

  final Priority priority;

  static ChipColors colorsFor(AppColors colors, Priority priority) =>
      switch (priority) {
        Priority.low => colors.priorityLow,
        Priority.medium => colors.priorityMedium,
        Priority.high => colors.priorityHigh,
        Priority.critical => colors.priorityCritical,
      };

  static String labelFor(AppLocalizations l10n, Priority priority) =>
      switch (priority) {
        Priority.low => l10n.priorityLow,
        Priority.medium => l10n.priorityMedium,
        Priority.high => l10n.priorityHigh,
        Priority.critical => l10n.priorityCritical,
      };

  @override
  Widget build(BuildContext context) => TintedChip(
    label: labelFor(AppLocalizations.of(context), priority),
    colors: colorsFor(context.appColors, priority),
  );
}
