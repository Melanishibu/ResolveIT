import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_history_entry.dart';

/// Contract: the audit history of an incident from the backend (`GET /tickets/{id}/history`, RIT-US-13).
abstract interface class IncidentHistoryRepository {
  Future<Result<List<IncidentHistoryEntry>>> history(String incidentId);
}
