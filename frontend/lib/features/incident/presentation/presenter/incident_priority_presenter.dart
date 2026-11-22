import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_details_presenter.dart';
import 'package:resolveit/features/incident/providers.dart';

/// State of priority changes on the details screen (RIT-US-19).
final class IncidentPriorityState {
  const IncidentPriorityState({
    this.isOpen = false,
    this.selectedPriority,
    this.isSaving = false,
    this.failure,
    this.updated,
  });

  final bool isOpen;
  final Priority? selectedPriority;
  final bool isSaving;
  final ApiFailure? failure;
  final IncidentDetails? updated;
}

final incidentPriorityPresenterProvider = NotifierProvider.autoDispose
    .family<IncidentPriorityPresenter, IncidentPriorityState, String>(
      IncidentPriorityPresenter.new,
    );

class IncidentPriorityPresenter extends Notifier<IncidentPriorityState> {
  IncidentPriorityPresenter(this.incidentId);

  final String incidentId;

  @override
  IncidentPriorityState build() => const IncidentPriorityState();

  void open(Priority currentPriority) {
    state = IncidentPriorityState(
      isOpen: true,
      selectedPriority: currentPriority,
    );
  }

  void cancel() {
    state = const IncidentPriorityState(isOpen: false);
  }

  void select(Priority? priority) {
    if (priority == null) return;
    state = IncidentPriorityState(
      isOpen: true,
      selectedPriority: priority,
      failure: state.failure,
    );
  }

  Future<void> submit() async {
    final priority = state.selectedPriority;
    if (priority == null || state.isSaving) return;
    await changePriority(priority);
  }

  Future<void> changePriority(Priority priority) async {
    if (state.isSaving) return;
    state = IncidentPriorityState(
      isOpen: state.isOpen,
      selectedPriority: priority,
      isSaving: true,
    );
    final result = await ref
        .read(incidentPriorityInteractorProvider)
        .changePriority(incidentId, priority);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = IncidentPriorityState(isOpen: false, updated: value);
        ref.invalidate(incidentDetailsPresenterProvider(incidentId));
      case Failure(:final failure):
        state = IncidentPriorityState(
          isOpen: true,
          selectedPriority: priority,
          failure: failure,
        );
    }
  }
}
