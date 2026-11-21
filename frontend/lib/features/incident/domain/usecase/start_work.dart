import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/repository/incident_status_repository.dart';

/// Start work on an assigned incident: ASSIGNED → IN_PROGRESS (RIT-US-15).
final class StartWork {
  const StartWork(this._repository);

  final IncidentStatusRepository _repository;

  Future<Result<IncidentDetails>> call(String incidentId) =>
      _repository.changeStatus(incidentId, IncidentStatus.inProgress);
}
