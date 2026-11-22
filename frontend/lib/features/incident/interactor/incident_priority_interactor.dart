import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/domain/usecase/change_incident_priority.dart';

/// Interactor for priority actions (RIT-US-19).
final class IncidentPriorityInteractor {
  const IncidentPriorityInteractor(this._changePriority);

  final ChangeIncidentPriority _changePriority;

  Future<Result<IncidentDetails>> changePriority(
    String incidentId,
    Priority priority,
  ) => _changePriority(incidentId, priority);
}
