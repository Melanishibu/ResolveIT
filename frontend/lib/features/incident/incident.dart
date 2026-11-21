/// Public API of the incident feature. Other features and the app import only this file.
library;

export 'package:resolveit/features/incident/domain/entity/incident_category.dart';
export 'package:resolveit/features/incident/domain/entity/incident_status.dart';
export 'package:resolveit/features/incident/domain/entity/new_incident.dart';
export 'package:resolveit/features/incident/domain/entity/priority.dart';
export 'package:resolveit/features/incident/domain/repository/incident_repository.dart';
export 'package:resolveit/features/incident/presentation/router/incident_routes.dart';
export 'package:resolveit/features/incident/domain/entity/incident_details.dart';
export 'package:resolveit/features/incident/domain/repository/incident_details_repository.dart';
export 'package:resolveit/features/incident/domain/entity/assignable_agent.dart';
export 'package:resolveit/features/incident/domain/repository/incident_assignment_repository.dart';
export 'package:resolveit/features/incident/domain/repository/incident_status_repository.dart';
export 'package:resolveit/features/incident/domain/entity/incident_list.dart';
export 'package:resolveit/features/incident/domain/repository/incident_list_repository.dart';
export 'package:resolveit/features/incident/presentation/view/incident_list_view.dart';
export 'package:resolveit/features/incident/presentation/view/incident_details_view.dart';
export 'package:resolveit/features/incident/presentation/view/report_incident_view.dart';
export 'package:resolveit/features/incident/providers.dart'
    show
        incidentHttpClientProvider,
        incidentRepositoryProvider,
        incidentDetailsRepositoryProvider,
        incidentListRepositoryProvider,
        incidentAssignmentRepositoryProvider,
        incidentStatusRepositoryProvider;
export 'package:resolveit/features/incident/widgets/category_label.dart';
export 'package:resolveit/features/incident/widgets/priority_chip.dart';
export 'package:resolveit/features/incident/widgets/status_chip.dart';
