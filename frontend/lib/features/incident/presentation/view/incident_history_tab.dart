import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/incident/domain/entity/incident_history_entry.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_history_presenter.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Full history of an incident (RIT-US-13): newest first, with readable labels and timestamps.
class IncidentHistoryTab extends ConsumerWidget {
  const IncidentHistoryTab({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final history = ref.watch(incidentHistoryPresenterProvider(incidentId));

    return history.when(
      loading: () => const LoadingState(),
      error: (error, _) => ErrorPanel(
        key: const Key('incident-history-error'),
        failure: error is ApiFailure ? error : ApiFailure.unknown(),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return EmptyState(
            key: const Key('incident-history-empty'),
            icon: Icons.history,
            message: l10n.incidentHistoryEmpty,
          );
        }
        return Column(
          key: const Key('incident-history-list'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in entries) ...[
              _HistoryEntryCard(entry: entry),
              SizedBox(height: spacing.m),
            ],
          ],
        );
      },
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({required this.entry});

  final IncidentHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final local = MaterialLocalizations.of(context);
    final spacing = context.spacing;
    final time = entry.occurredAt.toLocal();

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(entry.action), color: context.appColors.primary),
          SizedBox(width: spacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _actionLabel(l10n, entry),
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: spacing.xs),
                Text(
                  '${local.formatShortDate(time)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(time))} · ${l10n.incidentHistoryBy(entry.actorName)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconFor(String action) => switch (action) {
  'CREATED' => Icons.add_circle_outline,
  'ASSIGNED' || 'REASSIGNED' => Icons.person_outline,
  'STARTED' => Icons.play_circle_outline,
  'RESOLVED' => Icons.check_circle_outline,
  'REOPENED' => Icons.replay,
  'CLOSED' => Icons.lock_outline,
  'PRIORITY_CHANGED' => Icons.flag_outlined,
  _ => Icons.history,
};

String _actionLabel(
  AppLocalizations l10n,
  IncidentHistoryEntry entry,
) => switch (entry.action) {
  'CREATED' => l10n.incidentHistoryActionCreated,
  'ASSIGNED' => l10n.incidentHistoryActionAssigned,
  'REASSIGNED' => l10n.incidentHistoryActionReassigned,
  'STARTED' => l10n.incidentHistoryActionStarted,
  'RESOLVED' => l10n.incidentHistoryActionResolved,
  'REOPENED' => l10n.incidentHistoryActionReopened,
  'CLOSED' => l10n.incidentHistoryActionClosed,
  'PRIORITY_CHANGED' =>
    entry.oldValue != null && entry.newValue != null
        ? '${l10n.incidentDetailsPriority}: ${entry.oldValue} → ${entry.newValue}'
        : l10n.incidentHistoryActionPriorityChanged,
  _ => entry.action,
};
