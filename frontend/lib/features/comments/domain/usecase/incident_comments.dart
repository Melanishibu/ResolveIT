import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/comments/domain/entity/incident_comment.dart';
import 'package:resolveit/features/comments/domain/repository/incident_comments_repository.dart';

/// Loads the comments of an incident, oldest first (RIT-US-20).
final class ListComments {
  const ListComments(this._repository);

  final IncidentCommentsRepository _repository;

  Future<Result<IncidentCommentPage>> call(String incidentId) =>
      _repository.list(incidentId);
}

/// Adds a comment to an incident (RIT-US-20).
final class AddComment {
  const AddComment(this._repository);

  final IncidentCommentsRepository _repository;

  Future<Result<IncidentComment>> call(String incidentId, String text) =>
      _repository.add(incidentId, text);
}
