import 'package:resolveit/features/users/domain/entity/user_summary.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// The user-facing invitation status (RIT-US-08); "–" when there is none.
String invitationStatusLabel(AppLocalizations l10n, InvitationStatus? status) =>
    switch (status) {
      InvitationStatus.pending => l10n.invitationPending,
      InvitationStatus.accepted => l10n.invitationAccepted,
      InvitationStatus.expired => l10n.invitationExpired,
      InvitationStatus.sendFailed => l10n.invitationSendFailed,
      null => l10n.invitationNone,
    };
