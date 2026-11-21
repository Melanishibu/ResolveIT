import 'package:resolveit/features/incident/domain/entity/incident_category.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';

/// The list's sortable columns; [name] is the API's `sort` field (RIT-US-11).
enum IncidentSortField { ticketNumber, priority, status, createdAt, updatedAt }

/// Page and sort of the incident list (RIT-US-11). Default: newest first, 20 per page.
final class IncidentListFilter {
  const IncidentListFilter({
    this.page = 0,
    this.sortField = IncidentSortField.createdAt,
    this.ascending = false,
  });

  static const pageSize = 20;

  final int page;
  final IncidentSortField sortField;
  final bool ascending;

  IncidentListFilter copyWith({
    int? page,
    IncidentSortField? sortField,
    bool? ascending,
  }) => IncidentListFilter(
    page: page ?? this.page,
    sortField: sortField ?? this.sortField,
    ascending: ascending ?? this.ascending,
  );

  @override
  bool operator ==(Object other) =>
      other is IncidentListFilter &&
      other.page == page &&
      other.sortField == sortField &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(page, sortField, ascending);
}

/// One row of the incident list.
final class IncidentListItem {
  const IncidentListItem({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.assigneeName,
    required this.createdAt,
  });

  final String id;
  final String ticketNumber;
  final String title;
  final IncidentCategory category;
  final Priority priority;
  final IncidentStatus status;

  /// Null when unassigned.
  final String? assigneeName;
  final DateTime createdAt;
}

/// One page of incidents.
final class IncidentPage {
  const IncidentPage({required this.items, required this.totalItems});

  final List<IncidentListItem> items;
  final int totalItems;
}
