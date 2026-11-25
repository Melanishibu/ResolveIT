import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';

/// Contract: change priority (RIT-US-19): `PATCH /tickets/{id}/priority`.
abstract interface class IncidentPriorityRepository {
  Future<Result<IncidentDetails>> changePriority(
    String incidentId,
    Priority priority,
  );
}
