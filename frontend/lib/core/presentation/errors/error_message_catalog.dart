import 'package:resolveit/core/domain/api_failure.dart';
import 'package:resolveit/l10n/app_localizations.dart';

/// Looks up a failure's parameter, showing "not available" when the backend did not send it.
final class ErrorParams {
  const ErrorParams(this._values, this._l10n);

  final Map<String, String> _values;
  final AppLocalizations _l10n;

  String call(String name) {
    final value = _values[name];
    return (value == null || value.isEmpty)
        ? _l10n.errorValueUnavailable
        : value;
  }
}

typedef ErrorText = String Function(AppLocalizations l10n, ErrorParams params);

/// One catalogue entry: title (what happened), why (the rule and the things involved), next step.
final class ErrorCatalogEntry {
  const ErrorCatalogEntry({
    required this.title,
    required this.why,
    required this.nextStep,
  });

  final ErrorText title;
  final ErrorText why;
  final ErrorText nextStep;
}

/// A message ready to show, plus the technical details for the collapsed Details section.
final class ResolvedErrorMessage {
  const ResolvedErrorMessage({
    required this.title,
    required this.why,
    required this.nextStep,
    required this.failure,
  });

  final String title;
  final String why;
  final String nextStep;

  /// The original failure: its code, HTTP status and trace id go into Details, never the main text.
  final ApiFailure failure;
}

/// The single error-message catalogue of the app, keyed by backend `code`
/// (see `contracts/error-codes.json`) plus the frontend-only [ClientErrorCodes].
final class ErrorMessageCatalog {
  const ErrorMessageCatalog(this.entries);

  final Map<String, ErrorCatalogEntry> entries;

  static final ErrorMessageCatalog standard = ErrorMessageCatalog({
    'AUTH_CSRF_INVALID': ErrorCatalogEntry(
      title: (l, _) => l.errorAuthCsrfInvalidTitle,
      why: (l, _) => l.errorAuthCsrfInvalidWhy,
      nextStep: (l, _) => l.errorAuthCsrfInvalidNextStep,
    ),
    'AUTH_FORBIDDEN': ErrorCatalogEntry(
      title: (l, _) => l.errorAuthForbiddenTitle,
      why: (l, _) => l.errorAuthForbiddenWhy,
      nextStep: (l, _) => l.errorAuthForbiddenNextStep,
    ),
    'AUTH_INVALID_CREDENTIALS': ErrorCatalogEntry(
      title: (l, _) => l.errorAuthInvalidCredentialsTitle,
      why: (l, _) => l.errorAuthInvalidCredentialsWhy,
      nextStep: (l, _) => l.errorAuthInvalidCredentialsNextStep,
    ),
    'AUTH_LOGIN_TEMPORARILY_BLOCKED': ErrorCatalogEntry(
      title: (l, _) => l.errorAuthLoginTemporarilyBlockedTitle,
      why: (l, p) =>
          l.errorAuthLoginTemporarilyBlockedWhy(p('retryAfterMinutes')),
      nextStep: (l, _) => l.errorAuthLoginTemporarilyBlockedNextStep,
    ),
    'AUTH_UNAUTHENTICATED': ErrorCatalogEntry(
      title: (l, _) => l.errorAuthUnauthenticatedTitle,
      why: (l, _) => l.errorAuthUnauthenticatedWhy,
      nextStep: (l, _) => l.errorAuthUnauthenticatedNextStep,
    ),
    'INTERNAL_ERROR': ErrorCatalogEntry(
      title: (l, _) => l.errorInternalErrorTitle,
      why: (l, _) => l.errorInternalErrorWhy,
      nextStep: (l, _) => l.errorInternalErrorNextStep,
    ),
    'METHOD_NOT_ALLOWED': ErrorCatalogEntry(
      title: (l, _) => l.errorMethodNotAllowedTitle,
      why: (l, p) => l.errorMethodNotAllowedWhy(p('path'), p('method')),
      nextStep: (l, _) => l.errorMethodNotAllowedNextStep,
    ),
    'REQUEST_NOT_SUPPORTED': ErrorCatalogEntry(
      title: (l, _) => l.errorRequestNotSupportedTitle,
      why: (l, p) => l.errorRequestNotSupportedWhy(p('path')),
      nextStep: (l, _) => l.errorRequestNotSupportedNextStep,
    ),
    'RESOURCE_NOT_FOUND': ErrorCatalogEntry(
      title: (l, _) => l.errorResourceNotFoundTitle,
      why: (l, p) => l.errorResourceNotFoundWhy(p('path')),
      nextStep: (l, _) => l.errorResourceNotFoundNextStep,
    ),
    'USER_EMAIL_TAKEN': ErrorCatalogEntry(
      title: (l, _) => l.errorUserEmailTakenTitle,
      why: (l, p) => l.errorUserEmailTakenWhy(p('email')),
      nextStep: (l, _) => l.errorUserEmailTakenNextStep,
    ),
    'USER_ROLE_NOT_ALLOWED': ErrorCatalogEntry(
      title: (l, _) => l.errorUserRoleNotAllowedTitle,
      why: (l, p) => l.errorUserRoleNotAllowedWhy(p('role')),
      nextStep: (l, _) => l.errorUserRoleNotAllowedNextStep,
    ),
    'AUTH_TOKEN_INVALID': ErrorCatalogEntry(
      title: (l, _) => l.errorAuthTokenInvalidTitle,
      why: (l, _) => l.errorAuthTokenInvalidWhy,
      nextStep: (l, _) => l.errorAuthTokenInvalidNextStep,
    ),
    'AUTH_TOKEN_EXPIRED': ErrorCatalogEntry(
      title: (l, _) => l.errorAuthTokenExpiredTitle,
      why: (l, _) => l.errorAuthTokenExpiredWhy,
      nextStep: (l, _) => l.errorAuthTokenExpiredNextStep,
    ),
    'INCIDENT_NOT_FOUND': ErrorCatalogEntry(
      title: (l, _) => l.errorIncidentNotFoundTitle,
      why: (l, _) => l.errorIncidentNotFoundWhy,
      nextStep: (l, _) => l.errorIncidentNotFoundNextStep,
    ),
    'INCIDENT_ACCESS_DENIED': ErrorCatalogEntry(
      title: (l, _) => l.errorIncidentAccessDeniedTitle,
      why: (l, _) => l.errorIncidentAccessDeniedWhy,
      nextStep: (l, _) => l.errorIncidentAccessDeniedNextStep,
    ),
    'INCIDENT_INVALID_TRANSITION': ErrorCatalogEntry(
      title: (l, _) => l.errorIncidentInvalidTransitionTitle,
      why: (l, p) => l.errorIncidentInvalidTransitionWhy(p('status')),
      nextStep: (l, _) => l.errorIncidentInvalidTransitionNextStep,
    ),
    'ASSIGNEE_NOT_ACTIVE_AGENT': ErrorCatalogEntry(
      title: (l, _) => l.errorAssigneeNotActiveAgentTitle,
      why: (l, _) => l.errorAssigneeNotActiveAgentWhy,
      nextStep: (l, _) => l.errorAssigneeNotActiveAgentNextStep,
    ),
    'INCIDENT_RESOLUTION_NOTES_REQUIRED': ErrorCatalogEntry(
      title: (l, _) => l.errorIncidentResolutionNotesRequiredTitle,
      why: (l, p) =>
          l.errorIncidentResolutionNotesRequiredWhy(p('min'), p('max')),
      nextStep: (l, _) => l.errorIncidentResolutionNotesRequiredNextStep,
    ),
    'INCIDENT_REOPEN_REASON_REQUIRED': ErrorCatalogEntry(
      title: (l, _) => l.errorIncidentReopenReasonRequiredTitle,
      why: (l, p) => l.errorIncidentReopenReasonRequiredWhy(p('min'), p('max')),
      nextStep: (l, _) => l.errorIncidentReopenReasonRequiredNextStep,
    ),
    'INCIDENT_CLOSED': ErrorCatalogEntry(
      title: (l, _) => l.errorIncidentClosedTitle,
      why: (l, _) => l.errorIncidentClosedWhy,
      nextStep: (l, _) => l.errorIncidentClosedNextStep,
    ),
    'USER_NOT_FOUND': ErrorCatalogEntry(
      title: (l, _) => l.errorUserNotFoundTitle,
      why: (l, p) => l.errorUserNotFoundWhy(p('id')),
      nextStep: (l, _) => l.errorUserNotFoundNextStep,
    ),
    'USER_CANNOT_DEACTIVATE_SELF': ErrorCatalogEntry(
      title: (l, _) => l.errorUserCannotDeactivateSelfTitle,
      why: (l, _) => l.errorUserCannotDeactivateSelfWhy,
      nextStep: (l, _) => l.errorUserCannotDeactivateSelfNextStep,
    ),
    'PASSWORD_POLICY_VIOLATION': ErrorCatalogEntry(
      title: (l, _) => l.errorPasswordPolicyViolationTitle,
      why: (l, _) => l.errorPasswordPolicyViolationWhy,
      nextStep: (l, _) => l.errorPasswordPolicyViolationNextStep,
    ),
    'VALIDATION_FAILED': ErrorCatalogEntry(
      title: (l, _) => l.errorValidationFailedTitle,
      why: (l, p) => l.errorValidationFailedWhy(p('fields')),
      nextStep: (l, _) => l.errorValidationFailedNextStep,
    ),
    ClientErrorCodes.unknown: ErrorCatalogEntry(
      title: (l, _) => l.errorUnknownErrorTitle,
      why: (l, _) => l.errorUnknownErrorWhy,
      nextStep: (l, _) => l.errorUnknownErrorNextStep,
    ),
    ClientErrorCodes.networkUnavailable: ErrorCatalogEntry(
      title: (l, _) => l.errorNetworkUnavailableTitle,
      why: (l, _) => l.errorNetworkUnavailableWhy,
      nextStep: (l, _) => l.errorNetworkUnavailableNextStep,
    ),
  });

  /// Resolves [failure] to a message. Unknown codes get the safe generic message; the original
  /// code stays on [ResolvedErrorMessage.failure] for the Details section.
  ResolvedErrorMessage resolve(ApiFailure failure, AppLocalizations l10n) {
    final entry = entries[failure.code] ?? entries[ClientErrorCodes.unknown]!;
    final params = ErrorParams(failure.params, l10n);
    return ResolvedErrorMessage(
      title: entry.title(l10n, params),
      why: entry.why(l10n, params),
      nextStep: entry.nextStep(l10n, params),
      failure: failure,
    );
  }
}
