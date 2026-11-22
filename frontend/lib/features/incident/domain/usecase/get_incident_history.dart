import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_history_entry.dart';
import 'package:resolveit/features/incident/domain/repository/incident_history_repository.dart';

/// Loads the full history of an incident newest first (RIT-US-13).
final class GetIncidentHistory {
  const GetIncidentHistory(this._repository);

  final IncidentHistoryRepository _repository;

  Future<Result<List<IncidentHistoryEntry>>> call(String incidentId) =>
      _repository.history(incidentId);
}
