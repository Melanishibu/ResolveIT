import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/repository/incident_transition_repository.dart';

/// Resolve an incident with notes: IN_PROGRESS → RESOLVED (RIT-US-16). The backend checks the notes.
final class ResolveIncident {
  const ResolveIncident(this._repository);

  final IncidentTransitionRepository _repository;

  Future<Result<IncidentDetails>> call(String incidentId, String notes) =>
      _repository.transition(
        incidentId,
        IncidentStatus.resolved,
        resolutionNotes: notes,
      );
}

/// Close a resolved incident: RESOLVED → CLOSED, final (RIT-US-18).
final class CloseIncident {
  const CloseIncident(this._repository);

  final IncidentTransitionRepository _repository;

  Future<Result<IncidentDetails>> call(String incidentId) =>
      _repository.transition(incidentId, IncidentStatus.closed);
}

/// Reopen a resolved incident with a reason: RESOLVED → IN_PROGRESS (RIT-US-17). The backend checks the reason.
final class ReopenIncident {
  const ReopenIncident(this._repository);

  final IncidentTransitionRepository _repository;

  Future<Result<IncidentDetails>> call(String incidentId, String reason) =>
      _repository.transition(
        incidentId,
        IncidentStatus.inProgress,
        reason: reason,
      );
}
