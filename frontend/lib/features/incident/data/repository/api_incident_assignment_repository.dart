import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_details_repository.dart';
import 'package:resolveit/features/incident/domain/entity/assignable_agent.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/repository/incident_assignment_repository.dart';

/// Implements [IncidentAssignmentRepository] on the REST API; API errors become [Failure]s.
final class ApiIncidentAssignmentRepository
    implements IncidentAssignmentRepository {
  ApiIncidentAssignmentRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<AssignableAgent>>> activeAgents() async {
    try {
      final response = await _dio.get<Object?>('/users/agents');
      final data = response.data;
      if (data is! List) return Failure(ApiFailure.unknown());
      return Success([
        for (final item in data)
          AssignableAgent(
            id: item['id'] as String,
            name: item['name'] as String,
            email: item['email'] as String,
          ),
      ]);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }

  @override
  Future<Result<IncidentDetails>> assign(
    String incidentId,
    String agentId,
  ) async {
    try {
      final response = await _dio.patch<Object?>(
        '/tickets/${Uri.encodeComponent(incidentId)}/assign',
        data: {'agentId': agentId},
      );
      final details = incidentDetailsFromJson(response.data);
      return details == null ? Failure(ApiFailure.unknown()) : Success(details);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}
