// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ResolveIT';

  @override
  String get appBrand => 'IT Service Desk';

  @override
  String get menuDashboard => 'Dashboard';

  @override
  String get menuIncidents => 'Incidents';

  @override
  String get menuMyIncidents => 'My Incidents';

  @override
  String get menuCreateIncident => 'Create Incident';

  @override
  String get menuUserManagement => 'User Management';

  @override
  String get menuProfile => 'Profile';

  @override
  String get menuLogout => 'Logout';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleSupportAgent => 'Technician';

  @override
  String get roleEmployee => 'Employee';

  @override
  String avatarTooltip(String name, String role) {
    return 'Signed in as $name ($role)';
  }

  @override
  String get loadingLabel => 'Loading…';

  @override
  String get placeholderComingSoon => 'This screen is coming in a later story.';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityCritical => 'Critical';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusAssigned => 'Assigned';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusClosed => 'Closed';

  @override
  String get userActive => 'Active';

  @override
  String get userInactive => 'Inactive';

  @override
  String get passwordShow => 'Show password';

  @override
  String get passwordHide => 'Hide password';

  @override
  String get searchHint => 'Search…';

  @override
  String get searchClear => 'Clear search';

  @override
  String tableShowing(int from, int to, int total) {
    return 'Showing $from–$to of $total';
  }

  @override
  String get tableActions => 'Actions';

  @override
  String get tablePreviousPage => 'Previous page';

  @override
  String get tableNextPage => 'Next page';

  @override
  String tablePage(int page) {
    return 'Page $page';
  }

  @override
  String get confirmCancel => 'Cancel';

  @override
  String get confirmConfirm => 'Confirm';

  @override
  String get errorWhatToDo => 'What to do';

  @override
  String get errorDetails => 'Details';

  @override
  String get errorClose => 'Close';

  @override
  String errorDetailsCode(String code) {
    return 'Code: $code';
  }

  @override
  String errorDetailsStatus(String status) {
    return 'HTTP status: $status';
  }

  @override
  String errorDetailsReference(String traceId) {
    return 'Reference: $traceId';
  }

  @override
  String get errorValueUnavailable => 'not available';

  @override
  String get errorInternalErrorTitle => 'Something went wrong on our side';

  @override
  String get errorInternalErrorWhy =>
      'ResolveIT couldn\'t complete the request because of an unexpected error.';

  @override
  String get errorInternalErrorNextStep =>
      'Try again in a moment. If it keeps happening, contact the ResolveIT administrator and quote the reference shown under Details.';

  @override
  String get errorMethodNotAllowedTitle => 'This action isn\'t available here';

  @override
  String errorMethodNotAllowedWhy(String path, String method) {
    return '$path does not accept $method requests.';
  }

  @override
  String get errorMethodNotAllowedNextStep =>
      'Reload the page and try again. If it keeps happening, report it to the ResolveIT administrator.';

  @override
  String get errorRequestNotSupportedTitle =>
      'This request can\'t be processed';

  @override
  String errorRequestNotSupportedWhy(String path) {
    return 'The request to $path uses a format or option that ResolveIT doesn\'t support.';
  }

  @override
  String get errorRequestNotSupportedNextStep =>
      'Reload the page and try again. If it keeps happening, report it to the ResolveIT administrator.';

  @override
  String get errorResourceNotFoundTitle => 'This page or item doesn\'t exist';

  @override
  String errorResourceNotFoundWhy(String path) {
    return 'Nothing is available at $path. The link may be outdated or mistyped.';
  }

  @override
  String get errorResourceNotFoundNextStep =>
      'Check the address, or go back to the dashboard and open the item from there.';

  @override
  String get errorValidationFailedTitle =>
      'Some information is missing or invalid';

  @override
  String errorValidationFailedWhy(String fields) {
    return 'The request could not be accepted because these fields are missing or invalid: $fields.';
  }

  @override
  String get errorValidationFailedNextStep =>
      'Correct the highlighted fields and submit again.';

  @override
  String get errorUnknownErrorTitle => 'Something went wrong';

  @override
  String get errorUnknownErrorWhy =>
      'ResolveIT received a response it doesn\'t recognise.';

  @override
  String get errorUnknownErrorNextStep =>
      'Try again. If it keeps happening, contact the ResolveIT administrator and quote the code shown under Details.';

  @override
  String get errorNetworkUnavailableTitle => 'Can\'t reach ResolveIT';

  @override
  String get errorNetworkUnavailableWhy =>
      'The app couldn\'t connect to the ResolveIT server.';

  @override
  String get errorNetworkUnavailableNextStep =>
      'Check your network connection and try again in a moment.';

  @override
  String get errorAuthInvalidCredentialsTitle =>
      'Email or password is incorrect';

  @override
  String get errorAuthInvalidCredentialsWhy =>
      'The email address and password you entered don\'t match an active ResolveIT account.';

  @override
  String get errorAuthInvalidCredentialsNextStep =>
      'Check both and try again. After 5 failed attempts in a row, login is blocked for 15 minutes. If you forgot your password, contact your ResolveIT administrator.';

  @override
  String get errorAuthLoginTemporarilyBlockedTitle =>
      'Login is temporarily blocked';

  @override
  String errorAuthLoginTemporarilyBlockedWhy(String retryAfterMinutes) {
    return 'There were 5 failed login attempts in a row for this account, so login is blocked for security for about $retryAfterMinutes more minute(s).';
  }

  @override
  String get errorAuthLoginTemporarilyBlockedNextStep =>
      'Wait until the block ends, then log in with the correct password. If you don\'t remember it, contact your ResolveIT administrator.';

  @override
  String get errorAuthUnauthenticatedTitle => 'You\'re not logged in';

  @override
  String get errorAuthUnauthenticatedWhy =>
      'Your session has ended or is no longer valid, for example after you logged out, after 8 hours, or because your account was deactivated.';

  @override
  String get errorAuthUnauthenticatedNextStep =>
      'Log in again with your email address and password.';

  @override
  String get errorAuthForbiddenTitle => 'You don\'t have access to this';

  @override
  String get errorAuthForbiddenWhy =>
      'Your role doesn\'t allow this action or page in ResolveIT.';

  @override
  String get errorAuthForbiddenNextStep =>
      'If you need it for your work, ask your ResolveIT administrator. Otherwise go back to the dashboard.';

  @override
  String get errorAuthCsrfInvalidTitle => 'This request couldn\'t be verified';

  @override
  String get errorAuthCsrfInvalidWhy =>
      'The security token that protects your session was missing or didn\'t match, so ResolveIT refused the change.';

  @override
  String get errorAuthCsrfInvalidNextStep =>
      'Reload the page and try again. If it keeps happening, log out and log in again.';

  @override
  String get notAllowedBackToDashboard => 'Back to the dashboard';

  @override
  String get errorUserEmailTakenTitle => 'This email address is already in use';

  @override
  String errorUserEmailTakenWhy(String email) {
    return 'A ResolveIT user with the email address $email already exists. Email addresses are unique, regardless of upper or lower case.';
  }

  @override
  String get errorUserEmailTakenNextStep =>
      'Use a different email address, or find the existing user in User Management.';

  @override
  String get errorUserRoleNotAllowedTitle =>
      'This role can\'t be given to a new user';

  @override
  String errorUserRoleNotAllowedWhy(String role) {
    return 'New users can only be Technicians or Employees; the role $role can\'t be created here.';
  }

  @override
  String get errorUserRoleNotAllowedNextStep =>
      'Choose Technician or Employee and create the user again.';

  @override
  String get createUserTitle => 'Add user';

  @override
  String get createUserSubtitle =>
      'The new user gets an email with a link to set their own password.';

  @override
  String get createUserNameLabel => 'Name';

  @override
  String get createUserEmailLabel => 'Email';

  @override
  String get createUserRoleLabel => 'Role';

  @override
  String get createUserDepartmentLabel => 'Department';

  @override
  String get createUserButton => 'Create user';

  @override
  String get createUserNameRequired => 'Enter the user\'s name.';

  @override
  String get createUserEmailRequired => 'Enter the user\'s email address.';

  @override
  String get createUserRoleRequired => 'Choose a role.';

  @override
  String get createUserDepartmentRequired => 'Enter the user\'s department.';

  @override
  String createUserSuccess(String email) {
    return 'User created. The invitation email goes to $email.';
  }

  @override
  String get loginTitle => 'Log in to ResolveIT';

  @override
  String get loginSubtitle =>
      'IT Service Desk – use your work email and password.';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginButton => 'Log in';

  @override
  String get loginEmailRequired => 'Enter your email address.';

  @override
  String get loginPasswordRequired => 'Enter your password.';

  @override
  String get errorAuthTokenInvalidTitle => 'This link can\'t be used';

  @override
  String get errorAuthTokenInvalidWhy =>
      'The link to set your password is not valid or was already used. Each link works only once.';

  @override
  String get errorAuthTokenInvalidNextStep =>
      'If you already set your password, log in. Otherwise ask your ResolveIT administrator for a new invitation.';

  @override
  String get errorAuthTokenExpiredTitle => 'This link has expired';

  @override
  String get errorAuthTokenExpiredWhy =>
      'Links to set a password are valid for 24 hours, and this one is older.';

  @override
  String get errorAuthTokenExpiredNextStep =>
      'Ask your ResolveIT administrator for a new invitation.';

  @override
  String get errorPasswordPolicyViolationTitle =>
      'This password isn\'t strong enough';

  @override
  String get errorPasswordPolicyViolationWhy =>
      'A password needs 12 to 128 characters, at least one letter and one digit, and must not be your email address.';

  @override
  String get errorPasswordPolicyViolationNextStep =>
      'Choose a password that meets these rules and try again.';

  @override
  String get errorAuthCurrentPasswordWrongTitle =>
      'Current password is incorrect';

  @override
  String get errorAuthCurrentPasswordWrongWhy =>
      'The current password you entered doesn\'t match the password on your account.';

  @override
  String get errorAuthCurrentPasswordWrongNextStep =>
      'Enter your current password and try again.';

  @override
  String get errorPasswordSameAsCurrentTitle => 'New password must differ';

  @override
  String get errorPasswordSameAsCurrentWhy =>
      'Your new password is the same as your current password.';

  @override
  String get errorPasswordSameAsCurrentNextStep =>
      'Choose a different password that you haven\'t used recently.';

  @override
  String get profileTitle => 'My Profile';

  @override
  String get profileSubtitle =>
      'Check your details and keep your account secure.';

  @override
  String get profileTabPersonalInfo => 'Personal Info';

  @override
  String get profileTabSecurity => 'Security';

  @override
  String get profileName => 'Name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileRole => 'Role';

  @override
  String get profileDepartment => 'Department';

  @override
  String get profileMemberSince => 'Member since';

  @override
  String get profileChangePasswordTitle => 'Change Password';

  @override
  String get profileCurrentPassword => 'Current password';

  @override
  String get profileNewPassword => 'New password';

  @override
  String get profileConfirmPassword => 'Confirm new password';

  @override
  String get profileChangePasswordButton => 'Change password';

  @override
  String get profilePasswordChangedSuccess => 'Password changed successfully.';

  @override
  String get profilePasswordsDoNotMatch =>
      'New password and confirmation do not match.';

  @override
  String get profilePasswordSameAsCurrent =>
      'New password must differ from current password.';

  @override
  String get profileCurrentPasswordRequired => 'Enter your current password.';

  @override
  String get profileNewPasswordRequired => 'Enter a new password.';

  @override
  String get profileConfirmPasswordRequired => 'Confirm your new password.';

  @override
  String get errorUserNotFoundTitle => 'This user doesn\'t exist';

  @override
  String errorUserNotFoundWhy(String id) {
    return 'ResolveIT has no user with the id $id. The list may be out of date.';
  }

  @override
  String get errorUserNotFoundNextStep =>
      'Reload User Management and pick the user again.';

  @override
  String get errorUserCannotDeactivateSelfTitle =>
      'You can\'t deactivate your own account';

  @override
  String get errorUserCannotDeactivateSelfWhy =>
      'An Admin cannot deactivate themselves, so ResolveIT always keeps an Admin who can manage users.';

  @override
  String get errorUserCannotDeactivateSelfNextStep =>
      'Ask another Admin to deactivate your account if that is really needed.';

  @override
  String get userListSubtitle =>
      'Everyone who can use ResolveIT, with their role and status.';

  @override
  String get userListAdd => 'Add user';

  @override
  String get userListSearchHint => 'Search by name or email';

  @override
  String get userListRoleFilter => 'Role';

  @override
  String get userListStatusFilter => 'Status';

  @override
  String get userListAllRoles => 'All Roles';

  @override
  String get userListAllStatuses => 'All Statuses';

  @override
  String get userListName => 'Name';

  @override
  String get userListEmail => 'Email';

  @override
  String get userListRole => 'Role';

  @override
  String get userListDepartment => 'Department';

  @override
  String get userListStatus => 'Status';

  @override
  String get userListInvitation => 'Invitation';

  @override
  String get userListActions => 'Actions';

  @override
  String get userListActivate => 'Activate';

  @override
  String get userListDeactivate => 'Deactivate';

  @override
  String userListDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get userListDeactivateMessage =>
      'They will no longer be able to log in, and any open session ends with their next request. Their incidents stay as they are. You can activate them again at any time.';

  @override
  String userListActivated(String name) {
    return '$name is active again and can log in.';
  }

  @override
  String userListDeactivated(String name) {
    return '$name is deactivated.';
  }

  @override
  String get userListEmpty => 'No users match these filters.';

  @override
  String get invitationPending => 'Pending';

  @override
  String get invitationAccepted => 'Accepted';

  @override
  String get invitationExpired => 'Expired';

  @override
  String get invitationSendFailed => 'Email failed';

  @override
  String get invitationNone => '–';

  @override
  String get setPasswordTitle => 'Set your password';

  @override
  String get setPasswordSubtitle =>
      'Choose the password you will use to log in to ResolveIT.';

  @override
  String get setPasswordPolicy =>
      'Your password needs 12 to 128 characters, at least one letter and one digit, and must not be your email address.';

  @override
  String get setPasswordNewLabel => 'New password';

  @override
  String get setPasswordConfirmLabel => 'Confirm password';

  @override
  String get setPasswordButton => 'Set password';

  @override
  String get setPasswordRequired => 'Enter a password.';

  @override
  String get setPasswordConfirmRequired => 'Enter the password again.';

  @override
  String get setPasswordMismatch =>
      'The passwords don\'t match. Type the same password in both fields.';

  @override
  String get setPasswordSuccess =>
      'Your password is set. Log in with your email address and the new password.';

  @override
  String get categoryHardware => 'Hardware';

  @override
  String get categorySoftware => 'Software';

  @override
  String get categoryNetwork => 'Network';

  @override
  String get categoryAccess => 'Access';

  @override
  String get categoryOther => 'Other';

  @override
  String get createIncidentSubtitle =>
      'Describe the problem and the support team will pick it up.';

  @override
  String get createIncidentHelpTitle => 'We\'re here to help!';

  @override
  String get createIncidentHelpBody =>
      'Tell us what happened, when it started and what you already tried. A clear title and description help the support team solve it faster.';

  @override
  String get createIncidentTitleLabel => 'Title';

  @override
  String get createIncidentTitleHint => 'For example: Laptop won\'t start';

  @override
  String get createIncidentCategoryLabel => 'Category';

  @override
  String get createIncidentPriorityLabel => 'Priority';

  @override
  String get createIncidentDescriptionLabel => 'Description';

  @override
  String get createIncidentDescriptionHint =>
      'What happened, since when, and what you already tried.';

  @override
  String get createIncidentCancel => 'Cancel';

  @override
  String get createIncidentSubmit => 'Submit Incident';

  @override
  String get createIncidentTitleRequired =>
      'Enter a title (up to 120 characters).';

  @override
  String get createIncidentCategoryRequired => 'Choose a category.';

  @override
  String get createIncidentPriorityRequired => 'Choose a priority.';

  @override
  String get createIncidentDescriptionRequired =>
      'Enter a description (up to 2000 characters).';

  @override
  String createIncidentSuccess(String ticketNumber) {
    return 'Incident $ticketNumber created. The support team will pick it up.';
  }

  @override
  String get errorIncidentNotFoundTitle => 'This incident doesn\'t exist';

  @override
  String get errorIncidentNotFoundWhy =>
      'ResolveIT has no incident at this address. The link may be outdated or mistyped.';

  @override
  String get errorIncidentNotFoundNextStep =>
      'Go back to your incident list and open the incident from there.';

  @override
  String get errorIncidentAccessDeniedTitle => 'You can\'t open this incident';

  @override
  String get errorIncidentAccessDeniedWhy =>
      'Your role only lets you see incidents you reported or that are assigned to you.';

  @override
  String get errorIncidentAccessDeniedNextStep =>
      'Open one of your own incidents, or ask your ResolveIT administrator if you need access.';

  @override
  String get incidentDetailsBackToMyIncidents => 'Back to My Incidents';

  @override
  String get incidentDetailsBackToIncidents => 'Back to Incidents';

  @override
  String get incidentDetailsActions => 'Actions';

  @override
  String get incidentDetailsActionLater => 'Available in a later release';

  @override
  String get incidentDetailsOverview => 'Overview';

  @override
  String incidentDetailsComments(int count) {
    return 'Comments ($count)';
  }

  @override
  String get incidentDetailsHistory => 'History';

  @override
  String get incidentDetailsInformation => 'Incident Information';

  @override
  String get incidentDetailsTitle => 'Title';

  @override
  String get incidentDetailsDescription => 'Description';

  @override
  String get incidentDetailsCategory => 'Category';

  @override
  String get incidentDetailsPriority => 'Priority';

  @override
  String get incidentDetailsStatus => 'Status';

  @override
  String get incidentDetailsCreatedBy => 'Created by';

  @override
  String get incidentDetailsCreatedAt => 'Created at';

  @override
  String get incidentDetailsAssignedTo => 'Assigned to';

  @override
  String get incidentDetailsNotAssigned => 'Not assigned';

  @override
  String get incidentDetailsInactiveAssignee => 'inactive';

  @override
  String get incidentDetailsDepartment => 'Department';

  @override
  String get incidentDetailsResolutionNotes => 'Resolution notes';

  @override
  String get incidentDetailsNone => '—';

  @override
  String get incidentDetailsCommentsLater =>
      'Comments arrive in a later release.';

  @override
  String get incidentDetailsHistoryLater =>
      'The history arrives in a later release.';

  @override
  String get incidentActionAssign => 'Assign';

  @override
  String get incidentActionReassign => 'Reassign';

  @override
  String get incidentActionStart => 'Start work';

  @override
  String get incidentActionResolve => 'Resolve';

  @override
  String get incidentActionReopen => 'Reopen';

  @override
  String get incidentActionClose => 'Close';

  @override
  String get incidentActionChangePriority => 'Change priority';

  @override
  String get incidentListSubtitleAll => 'All incidents, newest first.';

  @override
  String get incidentListSubtitleAssigned =>
      'Incidents assigned to you, newest first.';

  @override
  String get incidentListSubtitleOwn => 'Incidents you reported, newest first.';

  @override
  String get incidentListEmpty => 'No incidents to show yet.';

  @override
  String get incidentListNumber => 'Incident #';

  @override
  String get incidentListOpen => 'View';

  @override
  String get statusStartedDone =>
      'Work started. The incident is now In Progress.';

  @override
  String get statusResolvedDone =>
      'Incident resolved. The reporter can now close or reopen it.';

  @override
  String get statusClosedDone => 'Incident closed.';

  @override
  String get statusReopenedDone =>
      'Incident reopened. It is In Progress again.';

  @override
  String get dashboardAdminTitle => 'Administrator Dashboard';

  @override
  String get dashboardTechnicianTitle => 'Technician Dashboard';

  @override
  String get dashboardEmployeeTitle => 'Your incidents at a glance';

  @override
  String get dashboardTotal => 'Total';

  @override
  String get dashboardRecentActivity => 'Recent Activity';

  @override
  String get dashboardRecentAssigned => 'Recent Assigned Incidents';

  @override
  String get dashboardNoActivity => 'No recent activity yet.';

  @override
  String get dashboardNoAssigned => 'No incidents are assigned to you yet.';

  @override
  String get activityCreated => 'Created';

  @override
  String get activityAssigned => 'Assigned';

  @override
  String get activityReassigned => 'Reassigned';

  @override
  String get activityStarted => 'Work started';

  @override
  String get activityResolved => 'Resolved';

  @override
  String get activityReopened => 'Reopened';

  @override
  String get activityClosed => 'Closed';

  @override
  String get activityPriorityChanged => 'Priority changed';

  @override
  String get reopenPanelTitle => 'Reopen this incident';

  @override
  String get reopenPanelReason => 'Reason';

  @override
  String get reopenPanelReasonHint =>
      'What still doesn\'t work? (10 to 500 characters)';

  @override
  String get errorIncidentReopenReasonRequiredTitle =>
      'Say why you\'re reopening';

  @override
  String errorIncidentReopenReasonRequiredWhy(String min, String max) {
    return 'A resolved incident can only be reopened with a reason of $min to $max characters, so the Technician knows what is still wrong.';
  }

  @override
  String get errorIncidentReopenReasonRequiredNextStep =>
      'Describe what still doesn\'t work, then reopen again.';

  @override
  String closeConfirmTitle(String ticketNumber) {
    return 'Close $ticketNumber?';
  }

  @override
  String get closeConfirmMessage =>
      'A closed incident is final: it can\'t be reopened, commented on or changed. If the problem comes back, report a new incident.';

  @override
  String get resolvePanelTitle => 'Resolve this incident';

  @override
  String get resolvePanelNotes => 'Resolution notes';

  @override
  String get resolvePanelNotesHint =>
      'What did you do to fix it? (10 to 2000 characters)';

  @override
  String get errorIncidentResolutionNotesRequiredTitle =>
      'Add resolution notes';

  @override
  String errorIncidentResolutionNotesRequiredWhy(String min, String max) {
    return 'An incident can only be resolved with notes of $min to $max characters, so the reporter knows what was done.';
  }

  @override
  String get errorIncidentResolutionNotesRequiredNextStep =>
      'Describe what you did to fix it, then resolve again.';

  @override
  String get commentsEmpty => 'No comments yet.';

  @override
  String get commentsInputLabel => 'Add a comment';

  @override
  String get commentsInputHint =>
      'Ask a question or share an update (up to 1000 characters).';

  @override
  String get commentsAdd => 'Add comment';

  @override
  String get errorIncidentClosedTitle => 'This incident is closed';

  @override
  String get errorIncidentClosedWhy =>
      'A closed incident is final, so it takes no new comments.';

  @override
  String get errorIncidentClosedNextStep =>
      'If the problem is back, report a new incident and mention this one.';

  @override
  String get assignPanelTitle => 'Assign to a Technician';

  @override
  String get assignPanelAgent => 'Technician';

  @override
  String assignPanelDone(String name) {
    return 'Assigned to $name.';
  }

  @override
  String get errorIncidentInvalidTransitionTitle =>
      'This action isn\'t possible right now';

  @override
  String errorIncidentInvalidTransitionWhy(String status) {
    return 'The incident is $status, and this action isn\'t allowed in that status.';
  }

  @override
  String get errorIncidentInvalidTransitionNextStep =>
      'Reload the incident to see its current status and the actions it allows.';

  @override
  String get errorAssigneeNotActiveAgentTitle =>
      'This person can\'t take incidents';

  @override
  String get errorAssigneeNotActiveAgentWhy =>
      'Incidents can only be assigned to active Technicians.';

  @override
  String get errorAssigneeNotActiveAgentNextStep =>
      'Choose an active Technician from the list.';
}
