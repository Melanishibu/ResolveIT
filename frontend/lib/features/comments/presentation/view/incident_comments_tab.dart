import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/features/comments/domain/entity/incident_comment.dart';
import 'package:resolveit/features/comments/presentation/presenter/incident_comments_presenter.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The Comments tab of the incident details screen (RIT-US-20): the comments oldest first, then an input box.
/// [canComment] is false for a CLOSED incident (the backend refuses anyway with INCIDENT_CLOSED).
class IncidentCommentsTab extends ConsumerStatefulWidget {
  const IncidentCommentsTab({
    super.key,
    required this.incidentId,
    required this.canComment,
  });

  final String incidentId;
  final bool canComment;

  @override
  ConsumerState<IncidentCommentsTab> createState() =>
      _IncidentCommentsTabState();
}

class _IncidentCommentsTabState extends ConsumerState<IncidentCommentsTab> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spacing = context.spacing;
    final provider = incidentCommentsPresenterProvider(widget.incidentId);
    ref.listen(provider, (previous, next) {
      if (next.addedCount > (previous?.addedCount ?? 0)) _text.clear();
    });
    final state = ref.watch(provider);
    final presenter = ref.read(provider.notifier);
    final page = state.page;
    final loadFailure = state.loadFailure;
    final addFailure = state.addFailure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loadFailure != null)
          ErrorPanel(key: const Key('comments-error'), failure: loadFailure)
        else if (state.isLoading)
          const LoadingState()
        else if (page == null || page.items.isEmpty)
          EmptyState(
            key: const Key('comments-empty'),
            icon: Icons.chat_bubble_outline,
            message: l10n.commentsEmpty,
          )
        else
          for (final comment in page.items) ...[
            _CommentCard(comment: comment),
            SizedBox(height: spacing.m),
          ],
        if (widget.canComment) ...[
          SizedBox(height: spacing.l),
          if (addFailure != null) ...[
            ErrorPanel(
              key: const Key('comment-add-error'),
              failure: addFailure,
            ),
            SizedBox(height: spacing.m),
          ],
          AppTextField(
            key: const Key('comment-input'),
            label: l10n.commentsInputLabel,
            hint: l10n.commentsInputHint,
            controller: _text,
            maxLength: 1000,
            maxLines: 3,
            enabled: !state.isSaving,
          ),
          SizedBox(height: spacing.m),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              key: const Key('comment-submit'),
              label: l10n.commentsAdd,
              isLoading: state.isSaving,
              onPressed: state.isSaving
                  ? null
                  : () => presenter.add(_text.text),
            ),
          ),
        ],
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final IncidentComment comment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final local = MaterialLocalizations.of(context);
    final created = comment.createdAt.toLocal();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${comment.authorName ?? l10n.incidentDetailsNone} · '
            '${local.formatShortDate(created)} '
            '${local.formatTimeOfDay(TimeOfDay.fromDateTime(created))}',
            style: context.textTheme.labelMedium,
          ),
          SizedBox(height: context.spacing.s),
          Text(comment.text),
        ],
      ),
    );
  }
}
