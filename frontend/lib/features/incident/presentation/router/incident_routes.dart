import 'package:go_router/go_router.dart';
import 'package:resolveit/features/incident/domain/entity/incident_list.dart';
import 'package:resolveit/features/incident/domain/entity/incident_status.dart';
import 'package:resolveit/features/incident/domain/entity/priority.dart';
import 'package:resolveit/features/incident/presentation/view/incident_details_view.dart';
import 'package:resolveit/features/incident/presentation/view/incident_list_view.dart';
import 'package:resolveit/features/incident/presentation/view/report_incident_view.dart';

/// The incident routes inside the app shell. Create Incident is in the Employee menu; Admins may open
/// it too (permission table, bug AB#181). The router's role guard keeps Support Agents out.
List<RouteBase> incidentRoutes() => [
  for (final path in [IncidentListView.adminPath, IncidentListView.ownPath])
    GoRoute(
      path: path,
      pageBuilder: (context, state) => NoTransitionPage(
        child: IncidentListView(initialFilter: _filterFrom(state.uri)),
      ),
    ),
  GoRoute(
    path: ReportIncidentView.path,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: ReportIncidentView()),
  ),
  GoRoute(
    path: IncidentDetailsView.pathPattern,
    pageBuilder: (context, state) => NoTransitionPage(
      child: IncidentDetailsView(incidentId: state.pathParameters['id']!),
    ),
  ),
];

/// The status and priority narrowing in the list URL (`?status=OPEN&priority=CRITICAL`, RIT-US-21); unknown
/// values are ignored.
IncidentListFilter _filterFrom(Uri uri) {
  final query = uri.queryParametersAll;
  return IncidentListFilter(
    statuses: [
      for (final code in query['status'] ?? const <String>[])
        ...IncidentStatus.values.where((s) => s.code == code),
    ],
    priorities: [
      for (final code in query['priority'] ?? const <String>[])
        ...Priority.values.where((p) => p.code == code),
    ],
  );
}
