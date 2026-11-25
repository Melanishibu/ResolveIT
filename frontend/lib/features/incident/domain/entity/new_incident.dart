import 'package:resolveit/features/incident/domain/entity/incident_category.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';

/// A field of the create-incident form.
enum NewIncidentField { title, category, priority, description }

/// What the Employee typed into the create-incident form (RIT-US-09).
///
/// Mirrors the backend's rules for instant feedback (title 1–120 characters, description 1–2000,
/// category and priority chosen); the backend still enforces them.
final class NewIncident {
  const NewIncident({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
  });

  static const titleMaxLength = 120;
  static const descriptionMaxLength = 2000;

  final String title;
  final String description;
  final IncidentCategory? category;
  final Priority? priority;

  /// Fields that are empty, or longer than their limit.
  Set<NewIncidentField> get invalidFields => {
    if (title.trim().isEmpty || title.trim().length > titleMaxLength)
      NewIncidentField.title,
    if (category == null) NewIncidentField.category,
    if (priority == null) NewIncidentField.priority,
    if (description.trim().isEmpty ||
        description.trim().length > descriptionMaxLength)
      NewIncidentField.description,
  };
}

/// The incident the backend created.
final class ReportedIncident {
  const ReportedIncident({required this.id, required this.ticketNumber});

  final String id;

  /// `INC-YYYY-NNNNN`.
  final String ticketNumber;
}
