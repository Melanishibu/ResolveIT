import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_list.dart';
import 'package:resolveit/features/incident/domain/repository/incident_list_repository.dart';

/// Loads one page of the incidents the user may see (RIT-US-11).
final class ListIncidents {
  const ListIncidents(this._repository);

  final IncidentListRepository _repository;

  Future<Result<IncidentPage>> call(IncidentListFilter filter) =>
      _repository.list(filter);
}
