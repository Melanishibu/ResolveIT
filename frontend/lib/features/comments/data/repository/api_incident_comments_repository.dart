import 'package:dio/dio.dart';
import 'package:resolveit/core/adapters/http/problem_details_mapper.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/comments/domain/entity/incident_comment.dart';
import 'package:resolveit/features/comments/domain/repository/incident_comments_repository.dart';

/// Implements [IncidentCommentsRepository] on the REST API; API errors become [Failure]s.
final class ApiIncidentCommentsRepository
    implements IncidentCommentsRepository {
  ApiIncidentCommentsRepository(this._dio);

  /// The tab shows up to this many comments (the API's maximum page size).
  static const pageSize = 100;

  final Dio _dio;

  @override
  Future<Result<IncidentCommentPage>> list(String incidentId) async {
    try {
      final response = await _dio.get<Object?>(
        '/tickets/${Uri.encodeComponent(incidentId)}/comments',
        queryParameters: {'page': 0, 'size': pageSize},
      );
      final page = commentPageFromJson(response.data);
      return page == null ? Failure(ApiFailure.unknown()) : Success(page);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }

  @override
  Future<Result<IncidentComment>> add(String incidentId, String text) async {
    try {
      final response = await _dio.post<Object?>(
        '/tickets/${Uri.encodeComponent(incidentId)}/comments',
        data: {'text': text},
      );
      final comment = commentFromJson(response.data);
      return comment == null ? Failure(ApiFailure.unknown()) : Success(comment);
    } on DioException catch (exception) {
      return Failure(mapDioException(exception));
    }
  }
}

/// Data model: maps the API's comment page; null when the body is not usable.
IncidentCommentPage? commentPageFromJson(Object? data) {
  if (data is! Map) return null;
  final items = <IncidentComment>[];
  for (final item in data['items'] as List? ?? const []) {
    final comment = commentFromJson(item);
    if (comment == null) return null;
    items.add(comment);
  }
  final total = data['totalItems'];
  return IncidentCommentPage(
    items: items,
    totalItems: total is num ? total.toInt() : items.length,
  );
}

/// Data model: maps one API comment; null when the body is not usable.
IncidentComment? commentFromJson(Object? data) {
  if (data is! Map) return null;
  try {
    return IncidentComment(
      id: data['id'] as String,
      authorName: (data['author'] as Map?)?['name'] as String?,
      text: data['text'] as String,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  } on Object {
    return null;
  }
}
