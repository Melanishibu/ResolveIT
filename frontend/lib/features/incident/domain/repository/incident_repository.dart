import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/new_incident.dart';

/// Contract: incidents in the backend (`POST /tickets`, RIT-US-09).
abstract interface class IncidentRepository {
  Future<Result<ReportedIncident>> report(NewIncident incident);
}
