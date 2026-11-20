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
