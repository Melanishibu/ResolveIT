import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/assignable_agent.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/repository/incident_assignment_repository.dart';

/// Loads the active Technicians an incident can be assigned to (RIT-US-14).
final class ListAssignableAgents {
  const ListAssignableAgents(this._repository);

  final IncidentAssignmentRepository _repository;

  Future<Result<List<AssignableAgent>>> call() => _repository.activeAgents();
}

/// Assigns or reassigns an incident to a Technician (RIT-US-14).
final class AssignIncident {
  const AssignIncident(this._repository);

  final IncidentAssignmentRepository _repository;

  Future<Result<IncidentDetails>> call(String incidentId, String agentId) =>
      _repository.assign(incidentId, agentId);
}
