import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/incident/presentation/presenter/assign_incident_presenter.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The Admin's assign panel (RIT-US-14): a dropdown of active Technicians, Assign and Cancel. Shown inline
/// above the tabs, because features may not open free dialogs (US-28 raw-control guard).
class AssignIncidentPanel extends ConsumerWidget {
  const AssignIncidentPanel({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final state = ref.watch(assignIncidentPresenterProvider(incidentId));
    final presenter = ref.read(
      assignIncidentPresenterProvider(incidentId).notifier,
    );
    if (!state.isOpen) return const SizedBox.shrink();
    final agents = state.agents;
    final failure = state.failure;
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.l),
      child: AppCard(
        key: const Key('assign-panel'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.assignPanelTitle, style: context.textTheme.titleMedium),
            SizedBox(height: spacing.m),
            if (failure != null) ...[
              ErrorPanel(key: const Key('assign-error'), failure: failure),
              SizedBox(height: spacing.m),
            ],
            if (agents == null)
              const LoadingState()
            else
              SizedBox(
                width: spacing.fieldMaxWidth,
                child: AppDropdown<String>(
                  key: const Key('assign-agent'),
                  label: l10n.assignPanelAgent,
                  isRequired: true,
                  value: state.selectedAgentId,
                  options: [
                    for (final agent in agents)
                      AppDropdownOption(
                        agent.id,
                        '${agent.name} (${agent.email})',
                      ),
                  ],
                  onChanged: state.isSaving ? null : presenter.select,
                ),
              ),
            SizedBox(height: spacing.m),
            Wrap(
              spacing: spacing.m,
              children: [
                AppButton(
                  key: const Key('assign-cancel'),
                  label: l10n.confirmCancel,
                  variant: AppButtonVariant.text,
                  onPressed: state.isSaving ? null : presenter.cancel,
                ),
                AppButton(
                  key: const Key('assign-submit'),
                  label: l10n.incidentActionAssign,
                  isLoading: state.isSaving,
                  onPressed: state.selectedAgentId == null || state.isSaving
                      ? null
                      : presenter.submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
