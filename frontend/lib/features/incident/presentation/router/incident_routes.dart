import 'package:go_router/go_router.dart';
import 'package:resolveit/features/incident/presentation/view/report_incident_view.dart';

/// The incident routes inside the app shell. Create Incident is in the Employee menu; the router's
/// role guard keeps other roles out (the API also allows Admins, Plan question 2).
List<RouteBase> incidentRoutes() => [
  GoRoute(
    path: ReportIncidentView.path,
    pageBuilder: (context, state) =>
        const NoTransitionPage(child: ReportIncidentView()),
  ),
];
