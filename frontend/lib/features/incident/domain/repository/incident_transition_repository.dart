import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';

/// Contract: status changes that carry text (`PATCH /tickets/{id}/status`): resolve with notes (RIT-US-16),
/// reopen with a reason (RIT-US-17) and close (RIT-US-18).
abstract interface class IncidentTransitionRepository {
  Future<Result<IncidentDetails>> transition(
    String incidentId,
    IncidentStatus target, {
    String? resolutionNotes,
    String? reason,
  });
}
