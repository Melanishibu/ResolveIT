import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/data/datasource/incident_remote_datasource.dart';
import 'package:resolveit/features/incident/domain/entity/new_incident.dart';
import 'package:resolveit/features/incident/domain/repository/incident_repository.dart';

/// Implements [IncidentRepository] on the incident REST API; API errors become [Failure]s.
final class ApiIncidentRepository implements IncidentRepository {
  ApiIncidentRepository(this._remote);

  final IncidentRemoteDataSource _remote;

  @override
  Future<Result<ReportedIncident>> report(NewIncident incident) async {
    try {
      final reported = reportedIncidentFromJson(await _remote.report(incident));
      return reported == null
          ? Failure(ApiFailure.unknown())
          : Success(reported);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}
