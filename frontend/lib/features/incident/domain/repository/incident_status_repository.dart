import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';

/// Contract: status changes (`PATCH /tickets/{id}/status`, RIT-US-15).
abstract interface class IncidentStatusRepository {
  Future<Result<IncidentDetails>> changeStatus(
    String incidentId,
    IncidentStatus target,
  );
}
