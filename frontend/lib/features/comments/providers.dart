import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/features/comments/data/repository/api_incident_comments_repository.dart';
import 'package:resolveit/features/comments/domain/repository/incident_comments_repository.dart';
import 'package:resolveit/features/comments/domain/usecase/incident_comments.dart';
import 'package:resolveit/features/comments/interactor/incident_comments_interactor.dart';

/// The HTTP client of the comments API. The composition root (`lib/app/app.dart`) binds it to the
/// shared API client; features never import the composition root.
final commentsHttpClientProvider = Provider<Dio>(
  (ref) => throw StateError(
    'commentsHttpClientProvider is bound by the composition root (ResolveItApp)',
  ),
);

/// Comments in the backend (RIT-US-20). Tests override it with a fake.
final incidentCommentsRepositoryProvider = Provider<IncidentCommentsRepository>(
  (ref) => ApiIncidentCommentsRepository(ref.watch(commentsHttpClientProvider)),
);

/// What the comments presenter calls.
final incidentCommentsInteractorProvider = Provider<IncidentCommentsInteractor>(
  (ref) {
    final repository = ref.watch(incidentCommentsRepositoryProvider);
    return IncidentCommentsInteractor(
      ListComments(repository),
      AddComment(repository),
    );
  },
);
