import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_details_repository.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/repository/incident_status_repository.dart';
import 'package:resolveit/features/incident/domain/repository/incident_transition_repository.dart';

/// Implements [IncidentStatusRepository] and [IncidentTransitionRepository] on `PATCH /tickets/{id}/status`;
/// API errors become [Failure]s.
final class ApiIncidentStatusRepository
    implements IncidentStatusRepository, IncidentTransitionRepository {
  ApiIncidentStatusRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<IncidentDetails>> changeStatus(
    String incidentId,
    IncidentStatus target,
  ) => transition(incidentId, target);

  @override
  Future<Result<IncidentDetails>> transition(
    String incidentId,
    IncidentStatus target, {
    String? resolutionNotes,
    String? reason,
  }) async {
    try {
      final response = await _dio.patch<Object?>(
        '/tickets/${Uri.encodeComponent(incidentId)}/status',
        data: {
          'targetStatus': target.code,
          'resolutionNotes': ?resolutionNotes,
          'reason': ?reason,
        },
      );
      final details = incidentDetailsFromJson(response.data);
      return details == null ? Failure(ApiFailure.unknown()) : Success(details);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}
