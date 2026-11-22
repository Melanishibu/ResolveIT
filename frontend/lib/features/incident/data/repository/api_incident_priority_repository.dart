import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_details_repository.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/domain/repository/incident_priority_repository.dart';

/// Implements [IncidentPriorityRepository] on `PATCH /tickets/{id}/priority`.
final class ApiIncidentPriorityRepository
    implements IncidentPriorityRepository {
  ApiIncidentPriorityRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<IncidentDetails>> changePriority(
    String incidentId,
    Priority priority,
  ) async {
    try {
      final response = await _dio.patch<Object?>(
        '/tickets/${Uri.encodeComponent(incidentId)}/priority',
        data: {'priority': priority.code},
      );
      final details = incidentDetailsFromJson(response.data);
      return details == null ? Failure(ApiFailure.unknown()) : Success(details);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}
