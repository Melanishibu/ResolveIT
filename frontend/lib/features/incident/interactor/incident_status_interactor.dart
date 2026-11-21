import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/usecase/start_work.dart';

/// Coordinates the status actions on the details screen (RIT-US-15).
final class IncidentStatusInteractor {
  const IncidentStatusInteractor(this._startWork);

  final StartWork _startWork;

  Future<Result<IncidentDetails>> startWork(String incidentId) =>
      _startWork(incidentId);
}
