/// A comment on an incident (RIT-US-20).
final class IncidentComment {
  const IncidentComment({
    required this.id,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  final String id;

  /// Null when the author no longer exists.
  final String? authorName;
  final String text;
  final DateTime createdAt;
}

/// The comments of an incident, oldest first, and how many there are in total.
final class IncidentCommentPage {
  const IncidentCommentPage({required this.items, required this.totalItems});

  final List<IncidentComment> items;
  final int totalItems;
}
