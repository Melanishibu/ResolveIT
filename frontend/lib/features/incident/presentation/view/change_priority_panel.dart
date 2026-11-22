import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_priority_presenter.dart';
import 'package:resolveit/features/incident/widgets/priority_chip.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The Admin's change priority panel (RIT-US-19): a dropdown of priorities, Change Priority and Cancel.
/// Shown inline above the tabs, like AssignIncidentPanel (US-28 raw-control guard).
class ChangePriorityPanel extends ConsumerWidget {
  const ChangePriorityPanel({super.key, required this.incident});

  final IncidentDetails incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final state = ref.watch(incidentPriorityPresenterProvider(incident.id));
    final presenter = ref.read(
      incidentPriorityPresenterProvider(incident.id).notifier,
    );
    if (!state.isOpen) return const SizedBox.shrink();
    final failure = state.failure;
    final currentPriority = state.selectedPriority ?? incident.priority;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.l),
      child: AppCard(
        key: const Key('change-priority-panel'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.incidentActionChangePriority,
              style: context.textTheme.titleMedium,
            ),
            SizedBox(height: spacing.m),
            if (failure != null) ...[
              ErrorPanel(key: const Key('priority-error'), failure: failure),
              SizedBox(height: spacing.m),
            ],
            SizedBox(
              width: spacing.fieldMaxWidth,
              child: AppDropdown<Priority>(
                key: const Key('incident-change-priority'),
                label: l10n.incidentDetailsPriority,
                isRequired: true,
                value: currentPriority,
                options: [
                  for (final p in Priority.values)
                    AppDropdownOption(p, PriorityChip.labelFor(l10n, p)),
                ],
                onChanged: state.isSaving ? null : presenter.select,
              ),
            ),
            SizedBox(height: spacing.m),
            Wrap(
              spacing: spacing.m,
              children: [
                AppButton(
                  key: const Key('change-priority-cancel'),
                  label: l10n.confirmCancel,
                  variant: AppButtonVariant.text,
                  onPressed: state.isSaving ? null : presenter.cancel,
                ),
                AppButton(
                  key: const Key('change-priority-submit'),
                  label: l10n.incidentActionChangePriority,
                  isLoading: state.isSaving,
                  onPressed: state.isSaving ? null : presenter.submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
