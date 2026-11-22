import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/incident/domain/entity/incident_history_entry.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_history_presenter.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Activity Timeline on the Overview tab (RIT-US-13): latest 5 entries with a "View all" link to the History tab.
class ActivityTimelinePanel extends ConsumerWidget {
  const ActivityTimelinePanel({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final history = ref.watch(incidentHistoryPresenterProvider(incidentId));

    return AppCard(
      key: const Key('activity-timeline-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.incidentTimelineTitle,
                  style: context.textTheme.titleMedium,
                ),
              ),
              AppButton(
                key: const Key('activity-timeline-view-all'),
                label: l10n.incidentTimelineViewAll,
                variant: AppButtonVariant.text,
                onPressed: () {
                  final controller = DefaultTabController.maybeOf(context);
                  controller?.animateTo(2);
                },
              ),
            ],
          ),
          SizedBox(height: spacing.m),
          history.when(
            loading: () => const LoadingState(),
            error: (error, stackTrace) => const SizedBox.shrink(),
            data: (entries) {
              if (entries.isEmpty) {
                return Text(
                  l10n.incidentHistoryEmpty,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                );
              }
              final latest = entries.take(5).toList();
              return Column(
                children: [
                  for (var i = 0; i < latest.length; i++) ...[
                    _TimelineRow(entry: latest[i]),
                    if (i < latest.length - 1)
                      Divider(
                        height: spacing.l,
                        color: context.appColors.border,
                      ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry});

  final IncidentHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final local = MaterialLocalizations.of(context);
    final spacing = context.spacing;
    final time = entry.occurredAt.toLocal();

    return Row(
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
                style: context.textTheme.bodyMedium?.copyWith(
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
