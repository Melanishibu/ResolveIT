import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/dashboard/domain/entity/dashboard.dart';

/// Contract: the dashboard API (RIT-US-21) and the latest assigned incidents from the incident list API.
abstract interface class DashboardRepository {
  Future<Result<DashboardCounts>> counts();

  Future<Result<List<ActivityEntry>>> activity({int limit = 10});

  Future<Result<List<RecentIncident>>> recentAssigned({int limit = 5});
}
