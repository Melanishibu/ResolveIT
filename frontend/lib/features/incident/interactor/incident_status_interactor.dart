import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/usecase/resolve_incident.dart';
import 'package:resolveit/features/incident/domain/usecase/start_work.dart';

/// Coordinates the status actions on the details screen (RIT-US-15, RIT-US-16).
final class IncidentStatusInteractor {
  const IncidentStatusInteractor(this._startWork, this._resolve);

  final StartWork _startWork;
  final ResolveIncident _resolve;

  Future<Result<IncidentDetails>> startWork(String incidentId) =>
      _startWork(incidentId);

  Future<Result<IncidentDetails>> resolve(String incidentId, String notes) =>
      _resolve(incidentId, notes);
}
