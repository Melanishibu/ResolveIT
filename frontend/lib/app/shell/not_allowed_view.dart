import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resolveit/app/shell/navigation_menu.dart';
import 'package:resolveit/app/theme/theme_context.dart';
import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/core/presentation/widgets/widgets.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The "not allowed" page (RIT-US-05): shown when a signed-in user opens a page that isn't in
/// their role's menu. The backend still enforces every rule; this only explains the refusal.
class NotAllowedView extends StatelessWidget {
  const NotAllowedView({super.key});

  static const path = '/not-allowed';

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Center(
      key: const Key('not-allowed-page'),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: spacing.dialogMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErrorPanel(
              failure: ApiFailure(code: 'AUTH_FORBIDDEN', httpStatus: 403),
            ),
            SizedBox(height: spacing.l),
            AppButton(
              key: const Key('not-allowed-back'),
              label: AppLocalizations.of(context).notAllowedBackToDashboard,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(MenuDestination.dashboard.path),
            ),
          ],
        ),
      ),
    );
  }
}
