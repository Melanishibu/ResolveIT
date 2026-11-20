import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/incident/domain/value_objects/incident_status.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Status chip: OPEN blue, ASSIGNED purple, IN_PROGRESS orange, RESOLVED green, CLOSED grey
/// (built on AppChip, US-28).
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final IncidentStatus status;

  static ChipColors colorsFor(AppColors colors, IncidentStatus status) =>
      switch (status) {
        IncidentStatus.open => colors.statusOpen,
        IncidentStatus.assigned => colors.statusAssigned,
        IncidentStatus.inProgress => colors.statusInProgress,
        IncidentStatus.resolved => colors.statusResolved,
        IncidentStatus.closed => colors.statusClosed,
      };

  static String labelFor(AppLocalizations l10n, IncidentStatus status) =>
      switch (status) {
        IncidentStatus.open => l10n.statusOpen,
        IncidentStatus.assigned => l10n.statusAssigned,
        IncidentStatus.inProgress => l10n.statusInProgress,
        IncidentStatus.resolved => l10n.statusResolved,
        IncidentStatus.closed => l10n.statusClosed,
      };

  @override
  Widget build(BuildContext context) => AppChip(
    label: labelFor(AppLocalizations.of(context), status),
    colors: colorsFor(context.appColors, status),
  );
}
