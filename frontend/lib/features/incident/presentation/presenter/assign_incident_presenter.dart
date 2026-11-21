import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/assignable_agent.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_details_presenter.dart';
import 'package:resolveit/features/incident/providers.dart';

/// State of the assign panel on the incident details screen (RIT-US-14).
final class AssignIncidentState {
  const AssignIncidentState({
    this.isOpen = false,
    this.agents,
    this.selectedAgentId,
    this.isSaving = false,
    this.failure,
    this.assigned,
  });

  final bool isOpen;

  /// The active Technicians; null while loading.
  final List<AssignableAgent>? agents;
  final String? selectedAgentId;
  final bool isSaving;
  final ApiFailure? failure;

  /// Set after a successful assignment, for the success toast.
  final IncidentDetails? assigned;
}

final assignIncidentPresenterProvider = NotifierProvider.autoDispose
    .family<AssignIncidentPresenter, AssignIncidentState, String>(
      AssignIncidentPresenter.new,
    );

class AssignIncidentPresenter extends Notifier<AssignIncidentState> {
  AssignIncidentPresenter(this.incidentId);

  final String incidentId;

  @override
  AssignIncidentState build() => const AssignIncidentState();

  /// The Admin chose Assign or Reassign: show the panel and load the active Technicians.
  Future<void> open() async {
    state = const AssignIncidentState(isOpen: true);
    final result = await ref
        .read(incidentAssignmentInteractorProvider)
        .agents();
    if (!ref.mounted || !state.isOpen) return;
    state = switch (result) {
      Success(:final value) => AssignIncidentState(isOpen: true, agents: value),
      Failure(:final failure) => AssignIncidentState(
        isOpen: true,
        agents: const [],
        failure: failure,
      ),
    };
  }

  void select(String? agentId) => state = AssignIncidentState(
    isOpen: true,
    agents: state.agents,
    selectedAgentId: agentId,
  );

  void cancel() => state = const AssignIncidentState();

  Future<void> submit() async {
    final agentId = state.selectedAgentId;
    if (agentId == null || state.isSaving) return;
    final agents = state.agents;
    state = AssignIncidentState(
      isOpen: true,
      agents: agents,
      selectedAgentId: agentId,
      isSaving: true,
    );
    final result = await ref
        .read(incidentAssignmentInteractorProvider)
        .assign(incidentId, agentId);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = AssignIncidentState(assigned: value);
        ref.invalidate(incidentDetailsPresenterProvider(incidentId));
      case Failure(:final failure):
        state = AssignIncidentState(
          isOpen: true,
          agents: agents,
          selectedAgentId: agentId,
          failure: failure,
        );
    }
  }
}
