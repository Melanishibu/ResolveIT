import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/dashboard/domain/entity/dashboard.dart';
import 'package:resolveit/features/dashboard/domain/repository/dashboard_repository.dart';

/// Loads the dashboard: counts, recent activity and, for Technicians, the 5 latest assigned incidents.
final class LoadDashboard {
  const LoadDashboard(this._repository);

  final DashboardRepository _repository;

  Future<Result<DashboardData>> call({required bool withRecentAssigned}) async {
    final counts = await _repository.counts();
    if (counts case Failure(:final failure)) return Failure(failure);
    final activity = await _repository.activity();
    if (activity case Failure(:final failure)) return Failure(failure);
    var recent = const <RecentIncident>[];
    if (withRecentAssigned) {
      final result = await _repository.recentAssigned();
      if (result case Failure(:final failure)) return Failure(failure);
      recent = (result as Success<List<RecentIncident>>).value;
    }
    return Success(
      DashboardData(
        counts: (counts as Success<DashboardCounts>).value,
        activity: (activity as Success<List<ActivityEntry>>).value,
        recentAssigned: recent,
      ),
    );
  }
}

/// Loads only the counts (the cards above the incident list).
final class LoadIncidentCounts {
  const LoadIncidentCounts(this._repository);

  final DashboardRepository _repository;

  Future<Result<DashboardCounts>> call() => _repository.counts();
}
