import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_category.dart';
import 'package:resolveit/features/incident/domain/entity/incident_list.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/domain/repository/incident_list_repository.dart';

/// Implements [IncidentListRepository] on `GET /tickets`; API errors become [Failure]s.
final class ApiIncidentListRepository implements IncidentListRepository {
  ApiIncidentListRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<IncidentPage>> list(IncidentListFilter filter) async {
    final direction = filter.ascending ? 'asc' : 'desc';
    try {
      final response = await _dio.get<Object?>(
        '/tickets',
        queryParameters: {
          'page': filter.page,
          'size': IncidentListFilter.pageSize,
          'sort': '${filter.sortField.name},$direction',
          if (filter.q != null && filter.q!.trim().isNotEmpty)
            'q': filter.q!.trim(),
          if (filter.statuses.isNotEmpty)
            'status': [for (final s in filter.statuses) s.code],
          if (filter.priorities.isNotEmpty)
            'priority': [for (final p in filter.priorities) p.code],
          if (filter.categories.isNotEmpty)
            'category': [for (final c in filter.categories) c.code],
          if (filter.createdFrom != null)
            'createdFrom': filter.createdFrom!.toUtc().toIso8601String(),
          if (filter.createdTo != null)
            'createdTo': filter.createdTo!.toUtc().toIso8601String(),
        },
      );
      final page = incidentPageFromJson(response.data);
      return page == null ? Failure(ApiFailure.unknown()) : Success(page);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}

/// Data model: maps the API's incident page; null when the body is not usable.
IncidentPage? incidentPageFromJson(Object? data) {
  if (data is! Map) return null;
  try {
    return IncidentPage(
      totalItems: (data['totalItems'] as num).toInt(),
      items: [
        for (final item in data['items'] as List)
          IncidentListItem(
            id: item['id'] as String,
            ticketNumber: item['ticketNumber'] as String,
            title: item['title'] as String,
            category: IncidentCategory.values.firstWhere(
              (category) => category.code == item['category'],
            ),
            priority: Priority.fromCode(item['priority'] as String),
            status: IncidentStatus.fromCode(item['status'] as String),
            assigneeName: (item['assignee'] as Map?)?['name'] as String?,
            assigneeActive:
                (item['assignee'] as Map?)?['active'] as bool? ?? true,
            createdAt: DateTime.parse(item['createdAt'] as String),
          ),
      ],
    );
  } on Object {
    return null;
  }
}
