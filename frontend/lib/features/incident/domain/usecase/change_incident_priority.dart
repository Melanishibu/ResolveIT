import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/domain/repository/incident_priority_repository.dart';

/// Admin changes an incident's priority (RIT-US-19).
final class ChangeIncidentPriority {
  const ChangeIncidentPriority(this._repository);

  final IncidentPriorityRepository _repository;

  Future<Result<IncidentDetails>> call(String incidentId, Priority priority) =>
      _repository.changePriority(incidentId, priority);
}
