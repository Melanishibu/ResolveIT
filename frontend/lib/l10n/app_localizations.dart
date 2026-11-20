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
