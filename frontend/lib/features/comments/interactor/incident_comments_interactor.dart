import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/comments/domain/entity/incident_comment.dart';
import 'package:resolveit/features/comments/domain/usecase/incident_comments.dart';

/// Coordinates the Comments tab's use cases (RIT-US-20).
final class IncidentCommentsInteractor {
  const IncidentCommentsInteractor(this._list, this._add);

  final ListComments _list;
  final AddComment _add;

  Future<Result<IncidentCommentPage>> load(String incidentId) =>
      _list(incidentId);

  Future<Result<IncidentComment>> add(String incidentId, String text) =>
      _add(incidentId, text);
}
