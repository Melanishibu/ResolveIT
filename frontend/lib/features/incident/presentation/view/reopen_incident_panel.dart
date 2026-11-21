import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_status_presenter.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The reopen panel (RIT-US-17): a reason (10–500 characters, checked by the backend), Reopen and
/// Cancel. Shown inline above the tabs, because features may not open free dialogs (US-28 raw-control guard).
class ReopenIncidentPanel extends ConsumerStatefulWidget {
  const ReopenIncidentPanel({super.key, required this.incidentId});

  final String incidentId;

  @override
  ConsumerState<ReopenIncidentPanel> createState() =>
      _ReopenIncidentPanelState();
}

class _ReopenIncidentPanelState extends ConsumerState<ReopenIncidentPanel> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final provider = incidentStatusPresenterProvider(widget.incidentId);
    final state = ref.watch(provider);
    final presenter = ref.read(provider.notifier);
    if (!state.isReopenOpen) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: spacing.l),
      child: AppCard(
        key: const Key('reopen-panel'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.reopenPanelTitle, style: context.textTheme.titleMedium),
            SizedBox(height: spacing.m),
            AppTextField(
              key: const Key('reopen-reason'),
              label: l10n.reopenPanelReason,
              hint: l10n.reopenPanelReasonHint,
              isRequired: true,
              controller: _reason,
              maxLength: 500,
              maxLines: 4,
              enabled: !state.isSaving,
            ),
            SizedBox(height: spacing.m),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: spacing.m,
              children: [
                AppButton(
                  key: const Key('reopen-cancel'),
                  label: l10n.confirmCancel,
                  variant: AppButtonVariant.text,
                  onPressed: state.isSaving ? null : presenter.cancelReopen,
                ),
                AppButton(
                  key: const Key('reopen-submit'),
                  label: l10n.incidentActionReopen,
                  isLoading: state.isSaving,
                  onPressed: state.isSaving
                      ? null
                      : () => presenter.reopen(_reason.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
