import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
