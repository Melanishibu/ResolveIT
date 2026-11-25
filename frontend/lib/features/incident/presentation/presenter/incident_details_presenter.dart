import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/providers.dart';

/// The incident details screen's state (RIT-US-10): loading, the incident, or a failure from the backend.
final incidentDetailsPresenterProvider = FutureProvider.autoDispose
    .family<IncidentDetails, String>((ref, id) async {
      final result = await ref.read(incidentDetailsInteractorProvider).load(id);
      return switch (result) {
        Success(:final value) => value,
        Failure(:final failure) => throw failure,
      };
    });
