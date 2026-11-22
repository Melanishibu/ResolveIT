import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/dashboard/domain/entity/dashboard.dart';
import 'package:resolveit/features/dashboard/domain/usecase/load_dashboard.dart';

/// Coordinates the dashboard's use cases (RIT-US-21).
final class DashboardInteractor {
  const DashboardInteractor(this._load, this._counts);

  final LoadDashboard _load;
  final LoadIncidentCounts _counts;

  Future<Result<DashboardData>> load({required bool withRecentAssigned}) =>
      _load(withRecentAssigned: withRecentAssigned);

  Future<Result<DashboardCounts>> counts() => _counts();
}
