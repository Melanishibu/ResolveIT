/// Incident counts in the user's role scope (RIT-US-21). critical = CRITICAL and not closed.
final class DashboardCounts {
  const DashboardCounts({
    required this.total,
    required this.open,
    required this.assigned,
    required this.inProgress,
    required this.resolved,
    required this.critical,
  });

  final int total;
  final int open;
  final int assigned;
  final int inProgress;
  final int resolved;
  final int critical;
}

/// One recent change on an incident in scope.
final class ActivityEntry {
  const ActivityEntry({
    required this.incidentId,
    required this.ticketNumber,
    required this.action,
    required this.actorName,
    required this.occurredAt,
  });

  final String incidentId;
  final String ticketNumber;

  /// Audit action code, for example `ASSIGNED`.
  final String action;

  /// Null when the user no longer exists.
  final String? actorName;
  final DateTime occurredAt;
}

/// An incident in the Technician's "Recent Assigned Incidents" panel.
final class RecentIncident {
  const RecentIncident({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.status,
  });

  final String id;
  final String ticketNumber;
  final String title;

  /// API status code, for example `IN_PROGRESS`.
  final String status;
}

/// Everything the dashboard shows.
final class DashboardData {
  const DashboardData({
    required this.counts,
    required this.activity,
    required this.recentAssigned,
  });

  final DashboardCounts counts;
  final List<ActivityEntry> activity;

  /// Only loaded for Technicians; empty otherwise.
  final List<RecentIncident> recentAssigned;
}
