import 'package:resolveit/features/incident/domain/entity/incident_category.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';

/// An action the backend allows on an incident (RIT-US-10 `allowedActions`).
enum IncidentAction {
  assign('ASSIGN'),
  reassign('REASSIGN'),
  start('START'),
  resolve('RESOLVE'),
  reopen('REOPEN'),
  close('CLOSE'),
  changePriority('CHANGE_PRIORITY');

  const IncidentAction(this.code);

  final String code;

  static IncidentAction? tryParse(String code) {
    for (final action in values) {
      if (action.code == code) return action;
    }
    return null;
  }
}

/// A user shown on an incident; [name] and [department] are null if the user no longer exists.
final class IncidentPerson {
  const IncidentPerson({
    required this.id,
    this.name,
    this.department,
    this.active = true,
  });

  final String id;
  final String? name;
  final String? department;
  final bool active;
}

/// One incident as its viewer sees it (RIT-US-10).
final class IncidentDetails {
  const IncidentDetails({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.assignee,
    this.resolutionNotes,
    this.allowedActions = const [],
  });

  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final IncidentCategory category;
  final Priority priority;
  final IncidentStatus status;
  final IncidentPerson createdBy;
  final IncidentPerson? assignee;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<IncidentAction> allowedActions;
}
