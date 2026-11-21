import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/domain/result.dart';
import 'package:resolveit/features/comments/domain/entity/incident_comment.dart';
import 'package:resolveit/features/comments/providers.dart';

/// State of an incident's Comments tab (RIT-US-20).
final class IncidentCommentsState {
  const IncidentCommentsState({
    this.page,
    this.isLoading = true,
    this.loadFailure,
    this.isSaving = false,
    this.addFailure,
    this.addedCount = 0,
  });

  /// The comments, oldest first; null before the first load.
  final IncidentCommentPage? page;
  final bool isLoading;
  final ApiFailure? loadFailure;
  final bool isSaving;
  final ApiFailure? addFailure;

  /// Grows by one per comment added, so the view can clear its input.
  final int addedCount;

  int get count => page?.totalItems ?? 0;
}

final incidentCommentsPresenterProvider = NotifierProvider.autoDispose
    .family<IncidentCommentsPresenter, IncidentCommentsState, String>(
      IncidentCommentsPresenter.new,
    );

class IncidentCommentsPresenter extends Notifier<IncidentCommentsState> {
  IncidentCommentsPresenter(this.incidentId);

  final String incidentId;

  @override
  IncidentCommentsState build() {
    Future.microtask(_load);
    return const IncidentCommentsState();
  }

  Future<void> add(String text) async {
    if (state.isSaving) return;
    state = IncidentCommentsState(
      page: state.page,
      isLoading: false,
      isSaving: true,
      addedCount: state.addedCount,
    );
    final result = await ref
        .read(incidentCommentsInteractorProvider)
        .add(incidentId, text);
    if (!ref.mounted) return;
    switch (result) {
      case Success(:final value):
        final page = state.page;
        state = IncidentCommentsState(
          page: IncidentCommentPage(
            items: [...?page?.items, value],
            totalItems: (page?.totalItems ?? 0) + 1,
          ),
          isLoading: false,
          addedCount: state.addedCount + 1,
        );
      case Failure(:final failure):
        state = IncidentCommentsState(
          page: state.page,
          isLoading: false,
          addFailure: failure,
          addedCount: state.addedCount,
        );
    }
  }

  Future<void> _load() async {
    final result = await ref
        .read(incidentCommentsInteractorProvider)
        .load(incidentId);
    if (!ref.mounted) return;
    state = switch (result) {
      Success(:final value) => IncidentCommentsState(
        page: value,
        isLoading: false,
      ),
      Failure(:final failure) => IncidentCommentsState(
        isLoading: false,
        loadFailure: failure,
      ),
    };
  }
}
