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
}
