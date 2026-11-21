import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/assignable_agent.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';

/// Contract: assignment (RIT-US-14): `GET /users/agents` and `PATCH /tickets/{id}/assign`.
abstract interface class IncidentAssignmentRepository {
  Future<Result<List<AssignableAgent>>> activeAgents();

  Future<Result<IncidentDetails>> assign(String incidentId, String agentId);
}
