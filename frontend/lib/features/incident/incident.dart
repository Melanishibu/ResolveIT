/// Public API of the incident feature. Other features and the app import only this file.
library;

export 'package:resolveit/features/incident/domain/entity/incident_category.dart';
export 'package:resolveit/features/incident/domain/entity/incident_status.dart';
export 'package:resolveit/features/incident/domain/entity/new_incident.dart';
export 'package:resolveit/features/incident/domain/entity/priority.dart';
export 'package:resolveit/features/incident/domain/repository/incident_repository.dart';
export 'package:resolveit/features/incident/presentation/router/incident_routes.dart';
export 'package:resolveit/features/incident/presentation/view/report_incident_view.dart';
export 'package:resolveit/features/incident/providers.dart'
    show incidentHttpClientProvider, incidentRepositoryProvider;
export 'package:resolveit/features/incident/widgets/category_label.dart';
export 'package:resolveit/features/incident/widgets/priority_chip.dart';
export 'package:resolveit/features/incident/widgets/status_chip.dart';
