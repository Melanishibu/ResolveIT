/// One audit log entry of an incident (RIT-US-13).
final class IncidentHistoryEntry {
  const IncidentHistoryEntry({
    required this.action,
    required this.actorName,
    this.oldValue,
    this.newValue,
    required this.occurredAt,
  });

  /// The action code: CREATED, ASSIGNED, REASSIGNED, STARTED, RESOLVED, REOPENED, CLOSED, PRIORITY_CHANGED.
  final String action;

  /// Display name of the user who performed the action.
  final String actorName;

  /// The previous state/value, if applicable.
  final String? oldValue;

  /// The new state/value, if applicable.
  final String? newValue;

  /// Timestamp in UTC when the action occurred.
  final DateTime occurredAt;
}
