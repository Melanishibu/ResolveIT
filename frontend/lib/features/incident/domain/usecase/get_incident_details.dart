import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/repository/incident_details_repository.dart';

/// Use case: open one incident (RIT-US-10). Access is decided by the backend.
final class GetIncidentDetails {
  const GetIncidentDetails(this._repository);

  final IncidentDetailsRepository _repository;

  Future<Result<IncidentDetails>> call(String id) => _repository.details(id);
}
