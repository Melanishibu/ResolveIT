import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/features/incident/domain/repository/incident_transition_repository.dart';
import 'package:resolveit/features/incident/domain/usecase/resolve_incident.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_status_repository.dart';
import 'package:resolveit/features/incident/domain/repository/incident_status_repository.dart';
import 'package:resolveit/features/incident/domain/usecase/start_work.dart';
import 'package:resolveit/features/incident/interactor/incident_status_interactor.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_assignment_repository.dart';
import 'package:resolveit/features/incident/domain/repository/incident_assignment_repository.dart';
import 'package:resolveit/features/incident/domain/usecase/assign_incident.dart';
import 'package:resolveit/features/incident/interactor/incident_assignment_interactor.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_list_repository.dart';
import 'package:resolveit/features/incident/domain/repository/incident_list_repository.dart';
import 'package:resolveit/features/incident/domain/usecase/list_incidents.dart';
import 'package:resolveit/features/incident/interactor/incident_list_interactor.dart';
import 'package:resolveit/features/incident/data/datasource/incident_remote_datasource.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_repository.dart';
import 'package:resolveit/features/incident/domain/repository/incident_repository.dart';
import 'package:resolveit/features/incident/data/repository/api_incident_details_repository.dart';
import 'package:resolveit/features/incident/domain/repository/incident_details_repository.dart';
import 'package:resolveit/features/incident/domain/usecase/get_incident_details.dart';
import 'package:resolveit/features/incident/interactor/incident_details_interactor.dart';
import 'package:resolveit/features/incident/domain/usecase/report_incident.dart';
import 'package:resolveit/features/incident/interactor/report_incident_interactor.dart';

/// The HTTP client of the incident API. The composition root (`lib/app/app.dart`) binds it to the
/// shared API client; features never import the composition root.
final incidentHttpClientProvider = Provider<Dio>(
  (ref) => throw StateError(
    'incidentHttpClientProvider is bound by the composition root (ResolveItApp)',
  ),
);

/// Incidents in the backend (RIT-US-09). Tests override it with a fake.
final incidentRepositoryProvider = Provider<IncidentRepository>(
  (ref) => ApiIncidentRepository(
    IncidentRemoteDataSource(ref.watch(incidentHttpClientProvider)),
  ),
);

/// One incident from the backend (RIT-US-10). Tests override it with a fake.
final incidentDetailsRepositoryProvider = Provider<IncidentDetailsRepository>(
  (ref) => ApiIncidentDetailsRepository(ref.watch(incidentHttpClientProvider)),
);

/// What the incident details presenter calls.
final incidentDetailsInteractorProvider = Provider<IncidentDetailsInteractor>(
  (ref) => IncidentDetailsInteractor(
    GetIncidentDetails(ref.watch(incidentDetailsRepositoryProvider)),
  ),
);

/// What the create-incident presenter calls.
final reportIncidentInteractorProvider = Provider<ReportIncidentInteractor>(
  (ref) => ReportIncidentInteractor(
    ReportIncident(ref.watch(incidentRepositoryProvider)),
  ),
);

/// The incident list (RIT-US-11). Tests override it with a fake.
final incidentListRepositoryProvider = Provider<IncidentListRepository>(
  (ref) => ApiIncidentListRepository(ref.watch(incidentHttpClientProvider)),
);

/// What the incident list presenter calls.
final incidentListInteractorProvider = Provider<IncidentListInteractor>(
  (ref) => IncidentListInteractor(
    ListIncidents(ref.watch(incidentListRepositoryProvider)),
  ),
);

/// Assignment (RIT-US-14). Tests override it with a fake.
final incidentAssignmentRepositoryProvider =
    Provider<IncidentAssignmentRepository>(
      (ref) => ApiIncidentAssignmentRepository(
        ref.watch(incidentHttpClientProvider),
      ),
    );

/// What the assign panel's presenter calls.
final incidentAssignmentInteractorProvider =
    Provider<IncidentAssignmentInteractor>((ref) {
      final repository = ref.watch(incidentAssignmentRepositoryProvider);
      return IncidentAssignmentInteractor(
        ListAssignableAgents(repository),
        AssignIncident(repository),
      );
    });

/// Status changes (RIT-US-15). Tests override it with a fake.
final incidentStatusRepositoryProvider = Provider<IncidentStatusRepository>(
  (ref) => ApiIncidentStatusRepository(ref.watch(incidentHttpClientProvider)),
);

/// What the status presenter calls.
final incidentStatusInteractorProvider = Provider<IncidentStatusInteractor>(
  (ref) => IncidentStatusInteractor(
    StartWork(ref.watch(incidentStatusRepositoryProvider)),
    ResolveIncident(ref.watch(incidentTransitionRepositoryProvider)),
    CloseIncident(ref.watch(incidentTransitionRepositoryProvider)),
    ReopenIncident(ref.watch(incidentTransitionRepositoryProvider)),
  ),
);

/// Status changes with notes or a reason (RIT-US-16 to RIT-US-18). Tests override it with a fake.
final incidentTransitionRepositoryProvider =
    Provider<IncidentTransitionRepository>(
      (ref) =>
          ApiIncidentStatusRepository(ref.watch(incidentHttpClientProvider)),
    );
