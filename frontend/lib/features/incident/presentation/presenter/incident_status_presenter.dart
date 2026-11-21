import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_details_presenter.dart';
import 'package:resolveit/features/incident/providers.dart';

/// State of the status actions on the details screen (RIT-US-15).
final class IncidentStatusState {
  const IncidentStatusState({
    this.isSaving = false,
    this.failure,
    this.started,
  });

  final bool isSaving;

  /// The backend refused (shown through the structured error panel).
  final ApiFailure? failure;

  /// Set after work was started, for the success toast.
  final IncidentDetails? started;
}

final incidentStatusPresenterProvider = NotifierProvider.autoDispose
    .family<IncidentStatusPresenter, IncidentStatusState, String>(
      IncidentStatusPresenter.new,
    );

class IncidentStatusPresenter extends Notifier<IncidentStatusState> {
  IncidentStatusPresenter(this.incidentId);

  final String incidentId;

  @override
  IncidentStatusState build() => const IncidentStatusState();

  Future<void> startWork() async {
    if (state.isSaving) return;
    state = const IncidentStatusState(isSaving: true);
    final result = await ref
        .read(incidentStatusInteractorProvider)
        .startWork(incidentId);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = IncidentStatusState(started: value);
        ref.invalidate(incidentDetailsPresenterProvider(incidentId));
      case Failure(:final failure):
        state = IncidentStatusState(failure: failure);
    }
  }
}
