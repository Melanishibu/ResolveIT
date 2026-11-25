import 'package:resolveit/features/incident/domain/entity/incident_category.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';

/// The list's sortable columns; [name] is the API's `sort` field (RIT-US-11).
enum IncidentSortField { ticketNumber, priority, status, createdAt, updatedAt }

/// Quick date range options for the incident list date filter (RIT-US-12).
enum DateRangeOption {
  allTime('ALL_TIME'),
  last7Days('LAST_7_DAYS'),
  last30Days('LAST_30_DAYS'),
  custom('CUSTOM');

  const DateRangeOption(this.code);
  final String code;

  static DateRangeOption fromCode(String? code) => switch (code) {
    'LAST_7_DAYS' || 'last7Days' => last7Days,
    'LAST_30_DAYS' || 'last30Days' => last30Days,
    'CUSTOM' || 'custom' => custom,
    _ => allTime,
  };
}

/// Computes (from, to) UTC boundaries for a [DateRangeOption].
(DateTime? from, DateTime? to) datesForOption(
  DateRangeOption option, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  switch (option) {
    case DateRangeOption.allTime:
      return (null, null);
    case DateRangeOption.last7Days:
      final start = DateTime(current.year, current.month, current.day - 7);
      final end = DateTime(
        current.year,
        current.month,
        current.day,
        23,
        59,
        59,
        999,
      );
      return (start.toUtc(), end.toUtc());
    case DateRangeOption.last30Days:
      final start = DateTime(current.year, current.month, current.day - 30);
      final end = DateTime(
        current.year,
        current.month,
        current.day,
        23,
        59,
        59,
        999,
      );
      return (start.toUtc(), end.toUtc());
    case DateRangeOption.custom:
      return (null, null);
  }
}

/// Page, sort and search/filter narrowing of the incident list (RIT-US-11, RIT-US-12, RIT-US-21).
/// Default: newest first, 20 per page, every status, priority and category.
final class IncidentListFilter {
  const IncidentListFilter({
    this.page = 0,
    this.sortField = IncidentSortField.createdAt,
    this.ascending = false,
    this.q,
    this.statuses = const [],
    this.priorities = const [],
    this.categories = const [],
    this.createdFrom,
    this.createdTo,
    this.dateRange = DateRangeOption.allTime,
  });

  static const pageSize = 20;

  final int page;
  final IncidentSortField sortField;
  final bool ascending;

  /// Search term (ticket number exact case-insensitive, or title substring case-insensitive).
  final String? q;

  /// Empty = every status.
  final List<IncidentStatus> statuses;

  /// Empty = every priority.
  final List<Priority> priorities;

  /// Empty = every category.
  final List<IncidentCategory> categories;

  /// Date filters (UTC day boundary converted).
  final DateTime? createdFrom;
  final DateTime? createdTo;

  final DateRangeOption dateRange;

  bool get hasFilters =>
      (q != null && q!.trim().isNotEmpty) ||
      statuses.isNotEmpty ||
      priorities.isNotEmpty ||
      categories.isNotEmpty ||
      dateRange != DateRangeOption.allTime ||
      createdFrom != null ||
      createdTo != null;

  IncidentListFilter copyWith({
    int? page,
    IncidentSortField? sortField,
    bool? ascending,
    String? Function()? q,
    List<IncidentStatus>? statuses,
    List<Priority>? priorities,
    List<IncidentCategory>? categories,
    DateTime? Function()? createdFrom,
    DateTime? Function()? createdTo,
    DateRangeOption? dateRange,
  }) => IncidentListFilter(
    page: page ?? this.page,
    sortField: sortField ?? this.sortField,
    ascending: ascending ?? this.ascending,
    q: q == null ? this.q : q(),
    statuses: statuses ?? this.statuses,
    priorities: priorities ?? this.priorities,
    categories: categories ?? this.categories,
    createdFrom: createdFrom == null ? this.createdFrom : createdFrom(),
    createdTo: createdTo == null ? this.createdTo : createdTo(),
    dateRange: dateRange ?? this.dateRange,
  );

  @override
  bool operator ==(Object other) =>
      other is IncidentListFilter &&
      other.page == page &&
      other.sortField == sortField &&
      other.ascending == ascending &&
      other.q == q &&
      _sameItems(other.statuses, statuses) &&
      _sameItems(other.priorities, priorities) &&
      _sameItems(other.categories, categories) &&
      other.createdFrom == createdFrom &&
      other.createdTo == createdTo &&
      other.dateRange == dateRange;

  @override
  int get hashCode => Object.hash(
    page,
    sortField,
    ascending,
    q,
    Object.hashAllUnordered(statuses),
    Object.hashAllUnordered(priorities),
    Object.hashAllUnordered(categories),
    createdFrom,
    createdTo,
    dateRange,
  );

  static bool _sameItems<T>(List<T> a, List<T> b) =>
      a.length == b.length && a.toSet().containsAll(b);
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
    this.assigneeActive = true,
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

  /// False when the assigned Technician has been deactivated.
  final bool assigneeActive;
  final DateTime createdAt;
}

/// One page of incidents.
final class IncidentPage {
  const IncidentPage({required this.items, required this.totalItems});

  final List<IncidentListItem> items;
  final int totalItems;
}
