import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/features/dashboard/data/repository/api_dashboard_repository.dart';
import 'package:resolveit/features/dashboard/domain/repository/dashboard_repository.dart';
import 'package:resolveit/features/dashboard/domain/usecase/load_dashboard.dart';
import 'package:resolveit/features/dashboard/interactor/dashboard_interactor.dart';

/// The HTTP client of the dashboard API. The composition root (`lib/app/app.dart`) binds it to the
/// shared API client; features never import the composition root.
final dashboardHttpClientProvider = Provider<Dio>(
  (ref) => throw StateError(
    'dashboardHttpClientProvider is bound by the composition root (ResolveItApp)',
  ),
);

/// The dashboard API (RIT-US-21). Tests override it with a fake.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => ApiDashboardRepository(ref.watch(dashboardHttpClientProvider)),
);

/// What the dashboard presenters call.
final dashboardInteractorProvider = Provider<DashboardInteractor>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardInteractor(
    LoadDashboard(repository),
    LoadIncidentCounts(repository),
  );
});
