import 'package:go_router/go_router.dart';
import 'package:resolveit/features/incident/presentation/view/incident_details_view.dart';
import 'package:resolveit/features/incident/presentation/view/report_incident_view.dart';

/// The incident routes inside the app shell. Create Incident is in the Employee menu; Admins may open
/// it too (permission table, bug AB#181). The router's role guard keeps Support Agents out.
List<RouteBase> incidentRoutes() => [
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
