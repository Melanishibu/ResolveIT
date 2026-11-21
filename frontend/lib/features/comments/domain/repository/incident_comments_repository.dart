import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/comments/domain/entity/incident_comment.dart';

/// Contract: comments of an incident (`/tickets/{id}/comments`, RIT-US-20).
abstract interface class IncidentCommentsRepository {
  Future<Result<IncidentCommentPage>> list(String incidentId);

  Future<Result<IncidentComment>> add(String incidentId, String text);
}
