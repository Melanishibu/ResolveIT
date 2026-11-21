import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_list.dart';
import 'package:resolveit/features/incident/domain/usecase/list_incidents.dart';

/// Coordinates the incident list screen's use case (RIT-US-11).
final class IncidentListInteractor {
  const IncidentListInteractor(this._list);

  final ListIncidents _list;

  Future<Result<IncidentPage>> load(IncidentListFilter filter) => _list(filter);
}
