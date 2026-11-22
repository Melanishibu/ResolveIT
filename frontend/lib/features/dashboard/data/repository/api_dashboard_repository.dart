import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/dashboard/domain/entity/dashboard.dart';
import 'package:resolveit/features/dashboard/domain/repository/dashboard_repository.dart';

/// Implements [DashboardRepository] on `/dashboard/*` and `GET /tickets`; API errors become [Failure]s.
final class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<DashboardCounts>> counts() => _get(
    '/dashboard/summary',
    null,
    (data) => data is Map
        ? DashboardCounts(
            total: _int(data['total']),
            open: _int(data['open']),
            assigned: _int(data['assigned']),
            inProgress: _int(data['inProgress']),
            resolved: _int(data['resolved']),
            critical: _int(data['critical']),
          )
        : null,
  );

  @override
  Future<Result<List<ActivityEntry>>> activity({int limit = 10}) => _get(
    '/dashboard/activity',
    {'limit': limit},
    (data) => data is List
        ? [
            for (final item in data)
              ActivityEntry(
                incidentId: item['incidentId'] as String,
                ticketNumber: item['ticketNumber'] as String,
                action: item['action'] as String,
                actorName: item['actor'] as String?,
                occurredAt: DateTime.parse(item['occurredAt'] as String),
              ),
          ]
        : null,
  );

  @override
  Future<Result<List<RecentIncident>>> recentAssigned({int limit = 5}) => _get(
    '/tickets',
    {'page': 0, 'size': limit, 'sort': 'createdAt,desc'},
    (data) => data is Map
        ? [
            for (final item in data['items'] as List)
              RecentIncident(
                id: item['id'] as String,
                ticketNumber: item['ticketNumber'] as String,
                title: item['title'] as String,
                status: item['status'] as String,
              ),
          ]
        : null,
  );

  Future<Result<T>> _get<T>(
    String path,
    Map<String, Object>? query,
    T? Function(Object? data) map,
  ) async {
    try {
      final response = await _dio.get<Object?>(path, queryParameters: query);
      final T? value;
      try {
        value = map(response.data);
      } on Object {
        return Failure(ApiFailure.unknown());
      }
      return value == null ? Failure(ApiFailure.unknown()) : Success(value);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }

  static int _int(Object? value) => (value as num).toInt();
}
