import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_history_entry.dart';
import 'package:resolveit/features/incident/providers.dart';

/// The incident history state (RIT-US-13): loading, history list, or failure.
final incidentHistoryPresenterProvider = FutureProvider.autoDispose
    .family<List<IncidentHistoryEntry>, String>((ref, id) async {
      final result = await ref.read(incidentHistoryInteractorProvider).load(id);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final failure) => throw failure,
      };
    });
