import 'package:dio/dio.dart';
import 'package:resolveit/features/incident/domain/entity/new_incident.dart';

/// The incident REST calls (`POST /tickets`, relative to the API base URL). Errors surface as
/// [DioException].
final class IncidentRemoteDataSource {
  IncidentRemoteDataSource(this._dio);

  final Dio _dio;

  /// `POST /tickets`: the response body.
  Future<Object?> report(NewIncident incident) async =>
      (await _dio.post<Object?>(
        '/tickets',
        data: {
          'title': incident.title.trim(),
          'description': incident.description.trim(),
          'category': incident.category?.code,
          'priority': incident.priority?.code,
        },
      )).data;
}

/// Data model: maps the API's reported incident; null when the body is not usable.
ReportedIncident? reportedIncidentFromJson(Object? data) {
  if (data is! Map) return null;
  final id = data['id'];
  final ticketNumber = data['ticketNumber'];
  if (id is! String || ticketNumber is! String) return null;
  return ReportedIncident(id: id, ticketNumber: ticketNumber);
}
