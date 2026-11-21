import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_category.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/domain/repository/incident_details_repository.dart';

/// Implements [IncidentDetailsRepository] on `GET /tickets/{id}`; API errors become [Failure]s.
final class ApiIncidentDetailsRepository implements IncidentDetailsRepository {
  ApiIncidentDetailsRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<IncidentDetails>> details(String id) async {
    try {
      final response = await _dio.get<Object?>(
        '/tickets/${Uri.encodeComponent(id)}',
      );
      final details = incidentDetailsFromJson(response.data);
      return details == null ? Failure(ApiFailure.unknown()) : Success(details);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}

/// Data model: maps the API's incident details; null when the body is not usable.
IncidentDetails? incidentDetailsFromJson(Object? data) {
  if (data is! Map) return null;
  try {
    return IncidentDetails(
      id: data['id'] as String,
      ticketNumber: data['ticketNumber'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      category: IncidentCategory.values.firstWhere(
        (category) => category.code == data['category'],
      ),
      priority: Priority.fromCode(data['priority'] as String),
      status: IncidentStatus.fromCode(data['status'] as String),
      createdBy: _person(data['createdBy'])!,
      assignee: _person(data['assignee']),
      resolutionNotes: data['resolutionNotes'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      allowedActions: [
        for (final code in (data['allowedActions'] as List? ?? const []))
          ?IncidentAction.tryParse(code.toString()),
      ],
    );
  } on Object {
    return null;
  }
}

IncidentPerson? _person(Object? data) {
  if (data is! Map) return null;
  return IncidentPerson(
    id: data['id'] as String,
    name: data['name'] as String?,
    department: data['department'] as String?,
    active: data['active'] as bool? ?? true,
  );
}
