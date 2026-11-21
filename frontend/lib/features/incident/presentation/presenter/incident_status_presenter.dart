import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/incident/domain/entity/incident_details.dart';
import 'package:resolveit/features/incident/presentation/presenter/incident_details_presenter.dart';
import 'package:resolveit/features/incident/providers.dart';

/// State of the status actions on the details screen (RIT-US-15, RIT-US-16).
final class IncidentStatusState {
  const IncidentStatusState({
    this.isSaving = false,
    this.failure,
    this.started,
    this.isResolveOpen = false,
    this.resolved,
    this.closed,
    this.isReopenOpen = false,
    this.reopened,
  });

  final bool isSaving;

  /// The backend refused (shown through the structured error panel).
  final ApiFailure? failure;

  /// Set after work was started, for the success toast.
  final IncidentDetails? started;

  /// The resolve panel (notes input) is shown.
  final bool isResolveOpen;

  /// Set after the incident was resolved, for the success toast.
  final IncidentDetails? resolved;

  /// Set after the incident was closed, for the success toast.
  final IncidentDetails? closed;

  /// The reopen panel (reason input) is shown.
  final bool isReopenOpen;

  /// Set after the incident was reopened, for the success toast.
  final IncidentDetails? reopened;
}

final incidentStatusPresenterProvider = NotifierProvider.autoDispose
    .family<IncidentStatusPresenter, IncidentStatusState, String>(
      IncidentStatusPresenter.new,
    );

class IncidentStatusPresenter extends Notifier<IncidentStatusState> {
  IncidentStatusPresenter(this.incidentId);

  final String incidentId;

  @override
  IncidentStatusState build() => const IncidentStatusState();

  Future<void> startWork() async {
    if (state.isSaving) return;
    state = const IncidentStatusState(isSaving: true);
    final result = await ref
        .read(incidentStatusInteractorProvider)
        .startWork(incidentId);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = IncidentStatusState(started: value);
        ref.invalidate(incidentDetailsPresenterProvider(incidentId));
      case Failure(:final failure):
        state = IncidentStatusState(failure: failure);
    }
  }

  /// Close a resolved incident (RIT-US-18); the view asks for confirmation first.
  Future<void> close() async {
    if (state.isSaving) return;
    state = const IncidentStatusState(isSaving: true);
    final result = await ref
        .read(incidentStatusInteractorProvider)
        .close(incidentId);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = IncidentStatusState(closed: value);
        ref.invalidate(incidentDetailsPresenterProvider(incidentId));
      case Failure(:final failure):
        state = IncidentStatusState(failure: failure);
    }
  }

  /// The user chose Reopen: show the reason panel (RIT-US-17).
  void openReopen() => state = const IncidentStatusState(isReopenOpen: true);

  void cancelReopen() => state = const IncidentStatusState();

  Future<void> reopen(String reason) async {
    if (state.isSaving) return;
    state = const IncidentStatusState(isSaving: true, isReopenOpen: true);
    final result = await ref
        .read(incidentStatusInteractorProvider)
        .reopen(incidentId, reason);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = IncidentStatusState(reopened: value);
        ref.invalidate(incidentDetailsPresenterProvider(incidentId));
      case Failure(:final failure):
        state = IncidentStatusState(failure: failure, isReopenOpen: true);
    }
  }

  /// The user chose Resolve: show the notes panel.
  void openResolve() => state = const IncidentStatusState(isResolveOpen: true);

  void cancelResolve() => state = const IncidentStatusState();

  Future<void> resolve(String notes) async {
    if (state.isSaving) return;
    state = const IncidentStatusState(isSaving: true, isResolveOpen: true);
    final result = await ref
        .read(incidentStatusInteractorProvider)
        .resolve(incidentId, notes);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        state = IncidentStatusState(resolved: value);
        ref.invalidate(incidentDetailsPresenterProvider(incidentId));
      case Failure(:final failure):
        state = IncidentStatusState(failure: failure, isResolveOpen: true);
    }
  }
}
