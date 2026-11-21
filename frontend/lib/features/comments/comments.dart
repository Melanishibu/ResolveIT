/// Public API of the comments feature (RIT-US-20). Other features and the app import only this file.
library;

export 'package:resolveit/features/comments/domain/entity/incident_comment.dart';
export 'package:resolveit/features/comments/domain/repository/incident_comments_repository.dart';
export 'package:resolveit/features/comments/presentation/presenter/incident_comments_presenter.dart'
    show incidentCommentsPresenterProvider;
export 'package:resolveit/features/comments/presentation/view/incident_comments_tab.dart';
export 'package:resolveit/features/comments/providers.dart'
    show commentsHttpClientProvider, incidentCommentsRepositoryProvider;
