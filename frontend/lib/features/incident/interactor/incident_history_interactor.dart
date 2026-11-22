import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_history_entry.dart';
import 'package:resolveit/features/incident/domain/usecase/get_incident_history.dart';

/// Coordinates the incident history use case (RIT-US-13).
final class IncidentHistoryInteractor {
  const IncidentHistoryInteractor(this._getHistory);

  final GetIncidentHistory _getHistory;

  Future<Result<List<IncidentHistoryEntry>>> load(String incidentId) =>
      _getHistory(incidentId);
}
