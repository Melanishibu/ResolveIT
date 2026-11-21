import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/new_incident.dart';
import 'package:resolveit/features/incident/domain/repository/incident_repository.dart';

/// Use case: an Employee reports an incident. Never sends a request with an invalid field.
final class ReportIncident {
  const ReportIncident(this._repository);

  final IncidentRepository _repository;

  Future<Result<ReportedIncident>> call(NewIncident incident) {
    final invalid = incident.invalidFields;
    if (invalid.isNotEmpty) {
      return Future.value(
        Failure(
          ApiFailure(
            code: 'VALIDATION_FAILED',
            params: {'fields': invalid.map((field) => field.name).join(', ')},
            httpStatus: 400,
          ),
        ),
      );
    }
    return _repository.report(incident);
  }
}
