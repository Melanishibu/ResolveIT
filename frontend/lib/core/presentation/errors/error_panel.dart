import 'package:flutter/material.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/errors/error_message_catalog.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The only way the app shows an error: title, why, what to do, and a collapsed grey Details
/// section with the code, HTTP status and reference. Use it inline as a banner, or through
/// [showErrorDialog] for blocking errors.
class ErrorPanel extends StatefulWidget {
  const ErrorPanel({super.key, required this.failure, this.catalog});

  final ApiFailure failure;
  final ErrorMessageCatalog? catalog;

  @override
  State<ErrorPanel> createState() => _ErrorPanelState();
}

class _ErrorPanelState extends State<ErrorPanel> {
  bool _detailsOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = widget.catalog ?? ErrorMessageCatalog.standard;
    final message = catalog.resolve(widget.failure, l10n);
    final colors = context.appColors;
    final spacing = context.spacing;
    final text = context.textTheme;
    final isWarning = widget.failure.severity == FailureSeverity.warning;
    final tone = isWarning ? colors.warning : colors.error;

    return DecoratedBox(
      key: const Key('error-panel'),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(context.radii.card),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
                  color: tone.foreground,
                ),
                SizedBox(width: spacing.s),
                Expanded(
                  child: Text(
                    message.title,
                    style: text.titleMedium?.copyWith(
                      color: tone.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.s),
            Text(
              message.why,
              style: text.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: spacing.m),
            Text(
              l10n.errorWhatToDo,
              style: text.labelLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              message.nextStep,
              style: text.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: spacing.s),
            TextButton.icon(
              key: const Key('error-details-toggle'),
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
              ),
              onPressed: () => setState(() => _detailsOpen = !_detailsOpen),
              icon: Icon(_detailsOpen ? Icons.expand_less : Icons.expand_more),
              label: Text(l10n.errorDetails),
            ),
            if (_detailsOpen) _Details(failure: message.failure),
          ],
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.failure});

  final ApiFailure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = context.textTheme.bodySmall?.copyWith(
      color: context.appColors.textSecondary,
    );
    final status = failure.httpStatus;
    final traceId = failure.traceId;
    return Padding(
      key: const Key('error-details'),
      padding: EdgeInsets.only(left: context.spacing.s),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.errorDetailsCode(failure.code), style: style),
            if (status != null)
              Text(l10n.errorDetailsStatus('$status'), style: style),
            if (traceId != null)
              Text(l10n.errorDetailsReference(traceId), style: style),
          ],
        ),
      ),
    );
  }
}

/// Shows [failure] as a blocking dialog built from [ErrorPanel].
Future<void> showErrorDialog(BuildContext context, ApiFailure failure) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final spacing = dialogContext.spacing;
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: spacing.dialogMaxWidth),
            child: Padding(
              padding: EdgeInsets.all(spacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ErrorPanel(failure: failure),
                  SizedBox(height: spacing.s),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(AppLocalizations.of(dialogContext).errorClose),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
