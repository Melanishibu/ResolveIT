import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/dashboard/domain/entity/dashboard.dart';
import 'package:resolveit/features/dashboard/providers.dart';

/// The dashboard (RIT-US-21); the key says whether to load the Technician's recent assigned incidents.
final dashboardPresenterProvider = FutureProvider.autoDispose
    .family<DashboardData, bool>((ref, withRecentAssigned) async {
      final result = await ref
          .read(dashboardInteractorProvider)
          .load(withRecentAssigned: withRecentAssigned);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final failure) => throw failure,
      };
    });

/// The counts for the cards above the incident list; null when they can't be loaded (the list still works).
final incidentCountsPresenterProvider =
    FutureProvider.autoDispose<DashboardCounts?>((ref) async {
      final result = await ref.read(dashboardInteractorProvider).counts();
      return switch (result) {
        Success(:final value) => value,
        Failure() => null,
      };
    });
