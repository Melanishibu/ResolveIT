import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_history_entry.dart';
import 'package:resolveit/features/incident/domain/repository/incident_history_repository.dart';

/// Implements [IncidentHistoryRepository] on `GET /tickets/{id}/history` (RIT-US-13).
final class ApiIncidentHistoryRepository implements IncidentHistoryRepository {
  ApiIncidentHistoryRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<IncidentHistoryEntry>>> history(String incidentId) async {
    try {
      final response = await _dio.get<Object?>(
        '/tickets/${Uri.encodeComponent(incidentId)}/history',
      );
      final entries = incidentHistoryFromJson(response.data);
      return entries == null ? Failure(ApiFailure.unknown()) : Success(entries);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}

/// Data model: maps the API's incident history JSON; null when the body is not usable.
List<IncidentHistoryEntry>? incidentHistoryFromJson(Object? data) {
  if (data is! List) return null;
  final entries = <IncidentHistoryEntry>[];
  for (final item in data) {
    if (item is! Map) return null;
    final action = item['action'] as String?;
    final actorName = (item['actorName'] ?? item['actor']) as String?;
    final occurredAtStr = (item['occurredAt'] ?? item['timestamp']) as String?;
    if (action == null || actorName == null || occurredAtStr == null) {
      return null;
    }
    final occurredAt = DateTime.tryParse(occurredAtStr);
    if (occurredAt == null) return null;
    entries.add(
      IncidentHistoryEntry(
        action: action,
        actorName: actorName,
        oldValue: item['oldValue'] as String?,
        newValue: item['newValue'] as String?,
        occurredAt: occurredAt,
      ),
    );
  }
  return entries;
}
