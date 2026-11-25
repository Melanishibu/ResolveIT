import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';

/// Contract: one incident from the backend (`GET /tickets/{id}`, RIT-US-10).
abstract interface class IncidentDetailsRepository {
  Future<Result<IncidentDetails>> details(String id);
}
