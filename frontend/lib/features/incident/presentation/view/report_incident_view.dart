import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/incident/domain/entity/incident_category.dart';
import 'package:resolveit/features/incident/domain/entity/new_incident.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/presentation/presenter/report_incident_presenter.dart';
import 'package:resolveit/features/incident/widgets/category_label.dart';
import 'package:resolveit/features/incident/widgets/help_panel.dart';
import 'package:resolveit/features/incident/widgets/priority_chip.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// An Employee reports an IT incident (`/incidents/new`, RIT-US-09): the help panel beside a form
/// with Title, Category, Priority and Description, plus Cancel and Submit Incident. No attachments
/// (deferred). Built only from the shared UI components (US-28).
class ReportIncidentView extends ConsumerStatefulWidget {
  const ReportIncidentView({super.key});

  static const path = '/incidents/new';

  /// Where the Employee goes after reporting or cancelling. The incident details screen arrives
  /// with RIT-US-10, which then opens the new incident instead (Plan question 1).
  static const myIncidentsPath = '/my-incidents';

  @override
  ConsumerState<ReportIncidentView> createState() => _ReportIncidentViewState();
}

class _ReportIncidentViewState extends ConsumerState<ReportIncidentView> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  IncidentCategory? _category;
  Priority? _priority;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() => ref
      .read(reportIncidentPresenterProvider.notifier)
      .submit(
        NewIncident(
          title: _title.text,
          description: _description.text,
          category: _category,
          priority: _priority,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    ref.listen(reportIncidentPresenterProvider, (previous, next) {
      final reported = next.reported;
      if (reported != null && previous?.reported == null) {
        AppToast.success(
          context,
          l10n.createIncidentSuccess(reported.ticketNumber),
        );
        context.go(ReportIncidentView.myIncidentsPath);
      }
    });
    final state = ref.watch(reportIncidentPresenterProvider);
    final presenter = ref.read(reportIncidentPresenterProvider.notifier);
    final failure = state.failure;
    String? invalid(NewIncidentField field, String message) =>
        state.invalidFields.contains(field) ? message : null;

    final form = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failure != null) ...[
            ErrorPanel(
              key: const Key('create-incident-error'),
              failure: failure,
            ),
            SizedBox(height: spacing.l),
          ],
          AppTextField(
            key: const Key('create-incident-title'),
            label: l10n.createIncidentTitleLabel,
            hint: l10n.createIncidentTitleHint,
            isRequired: true,
            maxLength: NewIncident.titleMaxLength,
            controller: _title,
            errorText: invalid(
              NewIncidentField.title,
              l10n.createIncidentTitleRequired,
            ),
            onChanged: (_) => presenter.fieldChanged(NewIncidentField.title),
          ),
          SizedBox(height: spacing.m),
          AppDropdown<IncidentCategory>(
            key: const Key('create-incident-category'),
            label: l10n.createIncidentCategoryLabel,
            isRequired: true,
            value: _category,
            options: [
              for (final category in IncidentCategory.values)
                AppDropdownOption(category, categoryLabel(l10n, category)),
            ],
            errorText: invalid(
              NewIncidentField.category,
              l10n.createIncidentCategoryRequired,
            ),
            onChanged: (category) {
              setState(() => _category = category);
              presenter.fieldChanged(NewIncidentField.category);
            },
          ),
          SizedBox(height: spacing.m),
          AppDropdown<Priority>(
            key: const Key('create-incident-priority'),
            label: l10n.createIncidentPriorityLabel,
            isRequired: true,
            value: _priority,
            options: [
              for (final priority in Priority.values)
                AppDropdownOption(
                  priority,
                  PriorityChip.labelFor(l10n, priority),
                ),
            ],
            errorText: invalid(
              NewIncidentField.priority,
              l10n.createIncidentPriorityRequired,
            ),
            onChanged: (priority) {
              setState(() => _priority = priority);
              presenter.fieldChanged(NewIncidentField.priority);
            },
          ),
          SizedBox(height: spacing.m),
          AppTextField(
            key: const Key('create-incident-description'),
            label: l10n.createIncidentDescriptionLabel,
            hint: l10n.createIncidentDescriptionHint,
            isRequired: true,
            maxLength: NewIncident.descriptionMaxLength,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            controller: _description,
            errorText: invalid(
              NewIncidentField.description,
              l10n.createIncidentDescriptionRequired,
            ),
            onChanged: (_) =>
                presenter.fieldChanged(NewIncidentField.description),
          ),
          SizedBox(height: spacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                key: const Key('create-incident-cancel'),
                label: l10n.createIncidentCancel,
                variant: AppButtonVariant.secondary,
                onPressed: state.isSubmitting
                    ? null
                    : () => context.go(ReportIncidentView.myIncidentsPath),
              ),
              SizedBox(width: spacing.m),
              AppButton(
                key: const Key('create-incident-submit'),
                label: l10n.createIncidentSubmit,
                isLoading: state.isSubmitting,
                onPressed: state.isSubmitting ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: l10n.menuCreateIncident,
          subtitle: l10n.createIncidentSubtitle,
        ),
        SizedBox(height: spacing.l),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < spacing.twoColumnMinWidth) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HelpPanel(),
                  SizedBox(height: spacing.l),
                  form,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(flex: 2, child: HelpPanel()),
                SizedBox(width: spacing.l),
                Expanded(flex: 3, child: form),
              ],
            );
          },
        ),
      ],
    );
  }
}
