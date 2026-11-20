import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/new_incident.dart';
import 'package:resolveit/features/incident/providers.dart';

/// State of the create-incident screen (RIT-US-09).
final class ReportIncidentState {
  const ReportIncidentState({
    this.invalidFields = const {},
    this.isSubmitting = false,
    this.failure,
    this.reported,
  });

  final Set<NewIncidentField> invalidFields;
  final bool isSubmitting;

  /// The backend refused (shown through the structured error panel).
  final ApiFailure? failure;

  /// Set once the incident was created: the screen confirms with the ticket number and moves on.
  final ReportedIncident? reported;
}

final reportIncidentPresenterProvider =
    NotifierProvider.autoDispose<ReportIncidentPresenter, ReportIncidentState>(
      ReportIncidentPresenter.new,
    );

class ReportIncidentPresenter extends Notifier<ReportIncidentState> {
  @override
  ReportIncidentState build() => const ReportIncidentState();

  Future<void> submit(NewIncident incident) async {
    final invalid = incident.invalidFields;
    if (invalid.isNotEmpty) {
      state = ReportIncidentState(invalidFields: invalid);
      return;
    }
    state = const ReportIncidentState(isSubmitting: true);
    final result = await ref
        .read(reportIncidentInteractorProvider)
        .report(incident);
    if (!ref.mounted) return;
    state = switch (result) {
      Success(:final value) => ReportIncidentState(reported: value),
      Failure(:final failure) => ReportIncidentState(failure: failure),
    };
  }

  /// The Employee changed [field]: its message goes away.
  void fieldChanged(NewIncidentField field) {
    if (!state.invalidFields.contains(field)) return;
    state = ReportIncidentState(
      invalidFields: {...state.invalidFields}..remove(field),
      failure: state.failure,
    );
  }
}
