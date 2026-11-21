import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/assignable_agent.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/usecase/assign_incident.dart';

/// Coordinates the assign panel's use cases (RIT-US-14).
final class IncidentAssignmentInteractor {
  const IncidentAssignmentInteractor(this._agents, this._assign);

  final ListAssignableAgents _agents;
  final AssignIncident _assign;

  Future<Result<List<AssignableAgent>>> agents() => _agents();

  Future<Result<IncidentDetails>> assign(String incidentId, String agentId) =>
      _assign(incidentId, agentId);
}
