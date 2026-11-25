import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_status_presenter.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The resolve panel (RIT-US-16): resolution notes (10–2000 characters, checked by the backend), Resolve and
/// Cancel. Shown inline above the tabs, because features may not open free dialogs (US-28 raw-control guard).
class ResolveIncidentPanel extends ConsumerStatefulWidget {
  const ResolveIncidentPanel({super.key, required this.incidentId});

  final String incidentId;

  @override
  ConsumerState<ResolveIncidentPanel> createState() =>
      _ResolveIncidentPanelState();
}

class _ResolveIncidentPanelState extends ConsumerState<ResolveIncidentPanel> {
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final provider = incidentStatusPresenterProvider(widget.incidentId);
    final state = ref.watch(provider);
    final presenter = ref.read(provider.notifier);
    if (!state.isResolveOpen) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.l),
      child: AppCard(
        key: const Key('resolve-panel'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.resolvePanelTitle, style: context.textTheme.titleMedium),
            SizedBox(height: spacing.m),
            AppTextField(
              key: const Key('resolve-notes'),
              label: l10n.resolvePanelNotes,
              hint: l10n.resolvePanelNotesHint,
              isRequired: true,
              controller: _notes,
              maxLength: 2000,
              maxLines: 4,
              enabled: !state.isSaving,
            ),
            SizedBox(height: spacing.m),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: spacing.m,
              children: [
                AppButton(
                  key: const Key('resolve-cancel'),
                  label: l10n.confirmCancel,
                  variant: AppButtonVariant.text,
                  onPressed: state.isSaving ? null : presenter.cancelResolve,
                ),
                AppButton(
                  key: const Key('resolve-submit'),
                  label: l10n.incidentActionResolve,
                  isLoading: state.isSaving,
                  onPressed: state.isSaving
                      ? null
                      : () => presenter.resolve(_notes.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
