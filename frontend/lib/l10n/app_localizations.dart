import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ResolveIT'**
  String get appTitle;

  /// No description provided for @appBrand.
  ///
  /// In en, this message translates to:
  /// **'IT Service Desk'**
  String get appBrand;

  /// No description provided for @menuDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get menuDashboard;

  /// No description provided for @menuIncidents.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get menuIncidents;

  /// No description provided for @menuMyIncidents.
  ///
  /// In en, this message translates to:
  /// **'My Incidents'**
  String get menuMyIncidents;

  /// No description provided for @menuCreateIncident.
  ///
  /// In en, this message translates to:
  /// **'Create Incident'**
  String get menuCreateIncident;

  /// No description provided for @menuUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get menuUserManagement;

  /// No description provided for @menuProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get menuProfile;

  /// No description provided for @menuLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get menuLogout;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleSupportAgent.
  ///
  /// In en, this message translates to:
  /// **'Technician'**
  String get roleSupportAgent;

  /// No description provided for @roleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleEmployee;

  /// No description provided for @avatarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name} ({role})'**
  String avatarTooltip(String name, String role);

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingLabel;

  /// No description provided for @placeholderComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This screen is coming in a later story.'**
  String get placeholderComingSoon;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get priorityCritical;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @userActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get userActive;

  /// No description provided for @userInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get userInactive;

  /// No description provided for @passwordShow.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShow;

  /// No description provided for @passwordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHide;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @tableShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing {from}–{to} of {total}'**
  String tableShowing(int from, int to, int total);

  /// No description provided for @tableActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get tableActions;

  /// No description provided for @tablePreviousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get tablePreviousPage;

  /// No description provided for @tableNextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get tableNextPage;

  /// No description provided for @tablePage.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String tablePage(int page);

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get confirmCancel;

  /// No description provided for @confirmConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmConfirm;

  /// No description provided for @errorWhatToDo.
  ///
  /// In en, this message translates to:
  /// **'What to do'**
  String get errorWhatToDo;

  /// No description provided for @errorDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get errorDetails;

  /// No description provided for @errorClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get errorClose;

  /// No description provided for @errorDetailsCode.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String errorDetailsCode(String code);

  /// No description provided for @errorDetailsStatus.
  ///
  /// In en, this message translates to:
  /// **'HTTP status: {status}'**
  String errorDetailsStatus(String status);

  /// No description provided for @errorDetailsReference.
  ///
  /// In en, this message translates to:
  /// **'Reference: {traceId}'**
  String errorDetailsReference(String traceId);

  /// No description provided for @errorValueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'not available'**
  String get errorValueUnavailable;

  /// No description provided for @errorInternalErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side'**
  String get errorInternalErrorTitle;

  /// No description provided for @errorInternalErrorWhy.
  ///
  /// In en, this message translates to:
  /// **'ResolveIT couldn\'t complete the request because of an unexpected error.'**
  String get errorInternalErrorWhy;

  /// No description provided for @errorInternalErrorNextStep.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment. If it keeps happening, contact the ResolveIT administrator and quote the reference shown under Details.'**
  String get errorInternalErrorNextStep;

  /// No description provided for @errorMethodNotAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'This action isn\'t available here'**
  String get errorMethodNotAllowedTitle;

  /// No description provided for @errorMethodNotAllowedWhy.
  ///
  /// In en, this message translates to:
  /// **'{path} does not accept {method} requests.'**
  String errorMethodNotAllowedWhy(String path, String method);

  /// No description provided for @errorMethodNotAllowedNextStep.
  ///
  /// In en, this message translates to:
  /// **'Reload the page and try again. If it keeps happening, report it to the ResolveIT administrator.'**
  String get errorMethodNotAllowedNextStep;

  /// No description provided for @errorRequestNotSupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'This request can\'t be processed'**
  String get errorRequestNotSupportedTitle;

  /// No description provided for @errorRequestNotSupportedWhy.
  ///
  /// In en, this message translates to:
  /// **'The request to {path} uses a format or option that ResolveIT doesn\'t support.'**
  String errorRequestNotSupportedWhy(String path);

  /// No description provided for @errorRequestNotSupportedNextStep.
  ///
  /// In en, this message translates to:
  /// **'Reload the page and try again. If it keeps happening, report it to the ResolveIT administrator.'**
  String get errorRequestNotSupportedNextStep;

  /// No description provided for @errorResourceNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This page or item doesn\'t exist'**
  String get errorResourceNotFoundTitle;

  /// No description provided for @errorResourceNotFoundWhy.
  ///
  /// In en, this message translates to:
  /// **'Nothing is available at {path}. The link may be outdated or mistyped.'**
  String errorResourceNotFoundWhy(String path);

  /// No description provided for @errorResourceNotFoundNextStep.
  ///
  /// In en, this message translates to:
  /// **'Check the address, or go back to the dashboard and open the item from there.'**
  String get errorResourceNotFoundNextStep;

  /// No description provided for @errorValidationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Some information is missing or invalid'**
  String get errorValidationFailedTitle;

  /// No description provided for @errorValidationFailedWhy.
  ///
  /// In en, this message translates to:
  /// **'The request could not be accepted because these fields are missing or invalid: {fields}.'**
  String errorValidationFailedWhy(String fields);

  /// No description provided for @errorValidationFailedNextStep.
  ///
  /// In en, this message translates to:
  /// **'Correct the highlighted fields and submit again.'**
  String get errorValidationFailedNextStep;

  /// No description provided for @errorUnknownErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorUnknownErrorTitle;

  /// No description provided for @errorUnknownErrorWhy.
  ///
  /// In en, this message translates to:
  /// **'ResolveIT received a response it doesn\'t recognise.'**
  String get errorUnknownErrorWhy;

  /// No description provided for @errorUnknownErrorNextStep.
  ///
  /// In en, this message translates to:
  /// **'Try again. If it keeps happening, contact the ResolveIT administrator and quote the code shown under Details.'**
  String get errorUnknownErrorNextStep;

  /// No description provided for @errorNetworkUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach ResolveIT'**
  String get errorNetworkUnavailableTitle;

  /// No description provided for @errorNetworkUnavailableWhy.
  ///
  /// In en, this message translates to:
  /// **'The app couldn\'t connect to the ResolveIT server.'**
  String get errorNetworkUnavailableWhy;

  /// No description provided for @errorNetworkUnavailableNextStep.
  ///
  /// In en, this message translates to:
  /// **'Check your network connection and try again in a moment.'**
  String get errorNetworkUnavailableNextStep;

  /// No description provided for @errorAuthInvalidCredentialsTitle.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect'**
  String get errorAuthInvalidCredentialsTitle;

  /// No description provided for @errorAuthInvalidCredentialsWhy.
  ///
  /// In en, this message translates to:
  /// **'The email address and password you entered don\'t match an active ResolveIT account.'**
  String get errorAuthInvalidCredentialsWhy;

  /// No description provided for @errorAuthInvalidCredentialsNextStep.
  ///
  /// In en, this message translates to:
  /// **'Check both and try again. After 5 failed attempts in a row, login is blocked for 15 minutes. If you forgot your password, contact your ResolveIT administrator.'**
  String get errorAuthInvalidCredentialsNextStep;

  /// No description provided for @errorAuthLoginTemporarilyBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Login is temporarily blocked'**
  String get errorAuthLoginTemporarilyBlockedTitle;

  /// No description provided for @errorAuthLoginTemporarilyBlockedWhy.
  ///
  /// In en, this message translates to:
  /// **'There were 5 failed login attempts in a row for this account, so login is blocked for security for about {retryAfterMinutes} more minute(s).'**
  String errorAuthLoginTemporarilyBlockedWhy(String retryAfterMinutes);

  /// No description provided for @errorAuthLoginTemporarilyBlockedNextStep.
  ///
  /// In en, this message translates to:
  /// **'Wait until the block ends, then log in with the correct password. If you don\'t remember it, contact your ResolveIT administrator.'**
  String get errorAuthLoginTemporarilyBlockedNextStep;

  /// No description provided for @errorAuthUnauthenticatedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re not logged in'**
  String get errorAuthUnauthenticatedTitle;

  /// No description provided for @errorAuthUnauthenticatedWhy.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended or is no longer valid, for example after you logged out, after 8 hours, or because your account was deactivated.'**
  String get errorAuthUnauthenticatedWhy;

  /// No description provided for @errorAuthUnauthenticatedNextStep.
  ///
  /// In en, this message translates to:
  /// **'Log in again with your email address and password.'**
  String get errorAuthUnauthenticatedNextStep;

  /// No description provided for @errorAuthForbiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this'**
  String get errorAuthForbiddenTitle;

  /// No description provided for @errorAuthForbiddenWhy.
  ///
  /// In en, this message translates to:
  /// **'Your role doesn\'t allow this action or page in ResolveIT.'**
  String get errorAuthForbiddenWhy;

  /// No description provided for @errorAuthForbiddenNextStep.
  ///
  /// In en, this message translates to:
  /// **'If you need it for your work, ask your ResolveIT administrator. Otherwise go back to the dashboard.'**
  String get errorAuthForbiddenNextStep;

  /// No description provided for @errorAuthCsrfInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'This request couldn\'t be verified'**
  String get errorAuthCsrfInvalidTitle;

  /// No description provided for @errorAuthCsrfInvalidWhy.
  ///
  /// In en, this message translates to:
  /// **'The security token that protects your session was missing or didn\'t match, so ResolveIT refused the change.'**
  String get errorAuthCsrfInvalidWhy;

  /// No description provided for @errorAuthCsrfInvalidNextStep.
  ///
  /// In en, this message translates to:
  /// **'Reload the page and try again. If it keeps happening, log out and log in again.'**
  String get errorAuthCsrfInvalidNextStep;

  /// No description provided for @notAllowedBackToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to the dashboard'**
  String get notAllowedBackToDashboard;

  /// No description provided for @errorUserEmailTakenTitle.
  ///
  /// In en, this message translates to:
  /// **'This email address is already in use'**
  String get errorUserEmailTakenTitle;

  /// No description provided for @errorUserEmailTakenWhy.
  ///
  /// In en, this message translates to:
  /// **'A ResolveIT user with the email address {email} already exists. Email addresses are unique, regardless of upper or lower case.'**
  String errorUserEmailTakenWhy(String email);

  /// No description provided for @errorUserEmailTakenNextStep.
  ///
  /// In en, this message translates to:
  /// **'Use a different email address, or find the existing user in User Management.'**
  String get errorUserEmailTakenNextStep;

  /// No description provided for @errorUserRoleNotAllowedTitle.
  ///
  /// In en, this message translates to:
  /// **'This role can\'t be given to a new user'**
  String get errorUserRoleNotAllowedTitle;

  /// No description provided for @errorUserRoleNotAllowedWhy.
  ///
  /// In en, this message translates to:
  /// **'New users can only be Technicians or Employees; the role {role} can\'t be created here.'**
  String errorUserRoleNotAllowedWhy(String role);

  /// No description provided for @errorUserRoleNotAllowedNextStep.
  ///
  /// In en, this message translates to:
  /// **'Choose Technician or Employee and create the user again.'**
  String get errorUserRoleNotAllowedNextStep;

  /// No description provided for @createUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get createUserTitle;

  /// No description provided for @createUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The new user gets an email with a link to set their own password.'**
  String get createUserSubtitle;

  /// No description provided for @createUserNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get createUserNameLabel;

  /// No description provided for @createUserEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get createUserEmailLabel;

  /// No description provided for @createUserRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get createUserRoleLabel;

  /// No description provided for @createUserDepartmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get createUserDepartmentLabel;

  /// No description provided for @createUserButton.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get createUserButton;

  /// No description provided for @createUserNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the user\'s name.'**
  String get createUserNameRequired;

  /// No description provided for @createUserEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the user\'s email address.'**
  String get createUserEmailRequired;

  /// No description provided for @createUserRoleRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a role.'**
  String get createUserRoleRequired;

  /// No description provided for @createUserDepartmentRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the user\'s department.'**
  String get createUserDepartmentRequired;

  /// No description provided for @createUserSuccess.
  ///
  /// In en, this message translates to:
  /// **'User created. The invitation email goes to {email}.'**
  String createUserSuccess(String email);

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to ResolveIT'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'IT Service Desk – use your work email and password.'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get loginEmailRequired;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get loginPasswordRequired;

  /// No description provided for @errorAuthTokenInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'This link can\'t be used'**
  String get errorAuthTokenInvalidTitle;

  /// No description provided for @errorAuthTokenInvalidWhy.
  ///
  /// In en, this message translates to:
  /// **'The link to set your password is not valid or was already used. Each link works only once.'**
  String get errorAuthTokenInvalidWhy;

  /// No description provided for @errorAuthTokenInvalidNextStep.
  ///
  /// In en, this message translates to:
  /// **'If you already set your password, log in. Otherwise ask your ResolveIT administrator for a new invitation.'**
  String get errorAuthTokenInvalidNextStep;

  /// No description provided for @errorAuthTokenExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'This link has expired'**
  String get errorAuthTokenExpiredTitle;

  /// No description provided for @errorAuthTokenExpiredWhy.
  ///
  /// In en, this message translates to:
  /// **'Links to set a password are valid for 24 hours, and this one is older.'**
  String get errorAuthTokenExpiredWhy;

  /// No description provided for @errorAuthTokenExpiredNextStep.
  ///
  /// In en, this message translates to:
  /// **'Ask your ResolveIT administrator for a new invitation.'**
  String get errorAuthTokenExpiredNextStep;

  /// No description provided for @errorPasswordPolicyViolationTitle.
  ///
  /// In en, this message translates to:
  /// **'This password isn\'t strong enough'**
  String get errorPasswordPolicyViolationTitle;

  /// No description provided for @errorPasswordPolicyViolationWhy.
  ///
  /// In en, this message translates to:
  /// **'A password needs 12 to 128 characters, at least one letter and one digit, and must not be your email address.'**
  String get errorPasswordPolicyViolationWhy;

  /// No description provided for @errorPasswordPolicyViolationNextStep.
  ///
  /// In en, this message translates to:
  /// **'Choose a password that meets these rules and try again.'**
  String get errorPasswordPolicyViolationNextStep;

  /// No description provided for @errorUserNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This user doesn\'t exist'**
  String get errorUserNotFoundTitle;

  /// No description provided for @errorUserNotFoundWhy.
  ///
  /// In en, this message translates to:
  /// **'ResolveIT has no user with the id {id}. The list may be out of date.'**
  String errorUserNotFoundWhy(String id);

  /// No description provided for @errorUserNotFoundNextStep.
  ///
  /// In en, this message translates to:
  /// **'Reload User Management and pick the user again.'**
  String get errorUserNotFoundNextStep;

  /// No description provided for @errorUserCannotDeactivateSelfTitle.
  ///
  /// In en, this message translates to:
  /// **'You can\'t deactivate your own account'**
  String get errorUserCannotDeactivateSelfTitle;

  /// No description provided for @errorUserCannotDeactivateSelfWhy.
  ///
  /// In en, this message translates to:
  /// **'An Admin cannot deactivate themselves, so ResolveIT always keeps an Admin who can manage users.'**
  String get errorUserCannotDeactivateSelfWhy;

  /// No description provided for @errorUserCannotDeactivateSelfNextStep.
  ///
  /// In en, this message translates to:
  /// **'Ask another Admin to deactivate your account if that is really needed.'**
  String get errorUserCannotDeactivateSelfNextStep;

  /// No description provided for @userListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone who can use ResolveIT, with their role and status.'**
  String get userListSubtitle;

  /// No description provided for @userListAdd.
  ///
  /// In en, this message translates to:
  /// **'Add user'**
  String get userListAdd;

  /// No description provided for @userListSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get userListSearchHint;

  /// No description provided for @userListRoleFilter.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get userListRoleFilter;

  /// No description provided for @userListStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get userListStatusFilter;

  /// No description provided for @userListAllRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get userListAllRoles;

  /// No description provided for @userListAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get userListAllStatuses;

  /// No description provided for @userListName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get userListName;

  /// No description provided for @userListEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get userListEmail;

  /// No description provided for @userListRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get userListRole;

  /// No description provided for @userListDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get userListDepartment;

  /// No description provided for @userListStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get userListStatus;

  /// No description provided for @userListInvitation.
  ///
  /// In en, this message translates to:
  /// **'Invitation'**
  String get userListInvitation;

  /// No description provided for @userListActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get userListActions;

  /// No description provided for @userListActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get userListActivate;

  /// No description provided for @userListDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get userListDeactivate;

  /// No description provided for @userListDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String userListDeactivateTitle(String name);

  /// No description provided for @userListDeactivateMessage.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to log in, and any open session ends with their next request. Their incidents stay as they are. You can activate them again at any time.'**
  String get userListDeactivateMessage;

  /// No description provided for @userListActivated.
  ///
  /// In en, this message translates to:
  /// **'{name} is active again and can log in.'**
  String userListActivated(String name);

  /// No description provided for @userListDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} is deactivated.'**
  String userListDeactivated(String name);

  /// No description provided for @userListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users match these filters.'**
  String get userListEmpty;

  /// No description provided for @invitationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get invitationPending;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get invitationAccepted;

  /// No description provided for @invitationExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get invitationExpired;

  /// No description provided for @invitationSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Email failed'**
  String get invitationSendFailed;

  /// No description provided for @invitationNone.
  ///
  /// In en, this message translates to:
  /// **'–'**
  String get invitationNone;

  /// No description provided for @setPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your password'**
  String get setPasswordTitle;

  /// No description provided for @setPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the password you will use to log in to ResolveIT.'**
  String get setPasswordSubtitle;

  /// No description provided for @setPasswordPolicy.
  ///
  /// In en, this message translates to:
  /// **'Your password needs 12 to 128 characters, at least one letter and one digit, and must not be your email address.'**
  String get setPasswordPolicy;

  /// No description provided for @setPasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get setPasswordNewLabel;

  /// No description provided for @setPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get setPasswordConfirmLabel;

  /// No description provided for @setPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get setPasswordButton;

  /// No description provided for @setPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a password.'**
  String get setPasswordRequired;

  /// No description provided for @setPasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the password again.'**
  String get setPasswordConfirmRequired;

  /// No description provided for @setPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match. Type the same password in both fields.'**
  String get setPasswordMismatch;

  /// No description provided for @setPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password is set. Log in with your email address and the new password.'**
  String get setPasswordSuccess;

  /// No description provided for @categoryHardware.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get categoryHardware;

  /// No description provided for @categorySoftware.
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get categorySoftware;

  /// No description provided for @categoryNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get categoryNetwork;

  /// No description provided for @categoryAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get categoryAccess;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @createIncidentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem and the support team will pick it up.'**
  String get createIncidentSubtitle;

  /// No description provided for @createIncidentHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help!'**
  String get createIncidentHelpTitle;

  /// No description provided for @createIncidentHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened, when it started and what you already tried. A clear title and description help the support team solve it faster.'**
  String get createIncidentHelpBody;

  /// No description provided for @createIncidentTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get createIncidentTitleLabel;

  /// No description provided for @createIncidentTitleHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Laptop won\'t start'**
  String get createIncidentTitleHint;

  /// No description provided for @createIncidentCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get createIncidentCategoryLabel;

  /// No description provided for @createIncidentPriorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get createIncidentPriorityLabel;

  /// No description provided for @createIncidentDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get createIncidentDescriptionLabel;

  /// No description provided for @createIncidentDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What happened, since when, and what you already tried.'**
  String get createIncidentDescriptionHint;

  /// No description provided for @createIncidentCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get createIncidentCancel;

  /// No description provided for @createIncidentSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Incident'**
  String get createIncidentSubmit;

  /// No description provided for @createIncidentTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title (up to 120 characters).'**
  String get createIncidentTitleRequired;

  /// No description provided for @createIncidentCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a category.'**
  String get createIncidentCategoryRequired;

  /// No description provided for @createIncidentPriorityRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a priority.'**
  String get createIncidentPriorityRequired;

  /// No description provided for @createIncidentDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a description (up to 2000 characters).'**
  String get createIncidentDescriptionRequired;

  /// No description provided for @createIncidentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Incident {ticketNumber} created. The support team will pick it up.'**
  String createIncidentSuccess(String ticketNumber);

  /// No description provided for @errorIncidentNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'This incident doesn\'t exist'**
  String get errorIncidentNotFoundTitle;

  /// No description provided for @errorIncidentNotFoundWhy.
  ///
  /// In en, this message translates to:
  /// **'ResolveIT has no incident at this address. The link may be outdated or mistyped.'**
  String get errorIncidentNotFoundWhy;

  /// No description provided for @errorIncidentNotFoundNextStep.
  ///
  /// In en, this message translates to:
  /// **'Go back to your incident list and open the incident from there.'**
  String get errorIncidentNotFoundNextStep;

  /// No description provided for @errorIncidentAccessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'You can\'t open this incident'**
  String get errorIncidentAccessDeniedTitle;

  /// No description provided for @errorIncidentAccessDeniedWhy.
  ///
  /// In en, this message translates to:
  /// **'Your role only lets you see incidents you reported or that are assigned to you.'**
  String get errorIncidentAccessDeniedWhy;

  /// No description provided for @errorIncidentAccessDeniedNextStep.
  ///
  /// In en, this message translates to:
  /// **'Open one of your own incidents, or ask your ResolveIT administrator if you need access.'**
  String get errorIncidentAccessDeniedNextStep;

  /// No description provided for @incidentDetailsBackToMyIncidents.
  ///
  /// In en, this message translates to:
  /// **'Back to My Incidents'**
  String get incidentDetailsBackToMyIncidents;

  /// No description provided for @incidentDetailsBackToIncidents.
  ///
  /// In en, this message translates to:
  /// **'Back to Incidents'**
  String get incidentDetailsBackToIncidents;

  /// No description provided for @incidentDetailsActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get incidentDetailsActions;

  /// No description provided for @incidentDetailsActionLater.
  ///
  /// In en, this message translates to:
  /// **'Available in a later release'**
  String get incidentDetailsActionLater;

  /// No description provided for @incidentDetailsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get incidentDetailsOverview;

  /// No description provided for @incidentDetailsComments.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String incidentDetailsComments(int count);

  /// No description provided for @incidentDetailsHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get incidentDetailsHistory;

  /// No description provided for @incidentDetailsInformation.
  ///
  /// In en, this message translates to:
  /// **'Incident Information'**
  String get incidentDetailsInformation;

  /// No description provided for @incidentDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get incidentDetailsTitle;

  /// No description provided for @incidentDetailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get incidentDetailsDescription;

  /// No description provided for @incidentDetailsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get incidentDetailsCategory;

  /// No description provided for @incidentDetailsPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get incidentDetailsPriority;

  /// No description provided for @incidentDetailsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get incidentDetailsStatus;

  /// No description provided for @incidentDetailsCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get incidentDetailsCreatedBy;

  /// No description provided for @incidentDetailsCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get incidentDetailsCreatedAt;

  /// No description provided for @incidentDetailsAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get incidentDetailsAssignedTo;

  /// No description provided for @incidentDetailsNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get incidentDetailsNotAssigned;

  /// No description provided for @incidentDetailsInactiveAssignee.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get incidentDetailsInactiveAssignee;

  /// No description provided for @incidentDetailsDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get incidentDetailsDepartment;

  /// No description provided for @incidentDetailsResolutionNotes.
  ///
  /// In en, this message translates to:
  /// **'Resolution notes'**
  String get incidentDetailsResolutionNotes;

  /// No description provided for @incidentDetailsNone.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get incidentDetailsNone;

  /// No description provided for @incidentDetailsCommentsLater.
  ///
  /// In en, this message translates to:
  /// **'Comments arrive in a later release.'**
  String get incidentDetailsCommentsLater;

  /// No description provided for @incidentDetailsHistoryLater.
  ///
  /// In en, this message translates to:
  /// **'The history arrives in a later release.'**
  String get incidentDetailsHistoryLater;

  /// No description provided for @incidentActionAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get incidentActionAssign;

  /// No description provided for @incidentActionReassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get incidentActionReassign;

  /// No description provided for @incidentActionStart.
  ///
  /// In en, this message translates to:
  /// **'Start work'**
  String get incidentActionStart;

  /// No description provided for @incidentActionResolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get incidentActionResolve;

  /// No description provided for @incidentActionReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get incidentActionReopen;

  /// No description provided for @incidentActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get incidentActionClose;

  /// No description provided for @incidentActionChangePriority.
  ///
  /// In en, this message translates to:
  /// **'Change priority'**
  String get incidentActionChangePriority;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
