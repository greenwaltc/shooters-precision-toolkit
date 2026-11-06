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
/// import 'generated/app_localizations.dart';
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

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contactDentonBramwell.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactDentonBramwell;

  /// No description provided for @contactUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The contact form is unavailable in this build.'**
  String get contactUnavailable;

  /// No description provided for @contactDeliveryNotice.
  ///
  /// In en, this message translates to:
  /// **'Send a question or share feedback. Your message will be emailed to the site owner.'**
  String get contactDeliveryNotice;

  /// No description provided for @contactName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactName;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @contactMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get contactMessage;

  /// No description provided for @contactNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a name within the character limit.'**
  String get contactNameInvalid;

  /// No description provided for @contactEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get contactEmailInvalid;

  /// No description provided for @contactMessageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a message within the character limit.'**
  String get contactMessageInvalid;

  /// No description provided for @contactSend.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get contactSend;

  /// No description provided for @contactSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get contactSending;

  /// No description provided for @contactSent.
  ///
  /// In en, this message translates to:
  /// **'Your message was sent.'**
  String get contactSent;

  /// No description provided for @contactSendFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t confirm delivery. Your message is still here if you want to try again.'**
  String get contactSendFailed;

  /// No description provided for @bramwellSPrecisionTestKit.
  ///
  /// In en, this message translates to:
  /// **'Bramwell\'\'s Precision Test Kit'**
  String get bramwellSPrecisionTestKit;

  /// No description provided for @theModernToolForComparingProjectileConsistency.
  ///
  /// In en, this message translates to:
  /// **'The modern tool for comparing projectile consistency'**
  String get theModernToolForComparingProjectileConsistency;

  /// No description provided for @createANewProject.
  ///
  /// In en, this message translates to:
  /// **'Create a New Project'**
  String get createANewProject;

  /// No description provided for @enterYourEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get enterYourEmailAddress;

  /// No description provided for @unableToCompleteThatActionPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete that action. Please try again.'**
  String get unableToCompleteThatActionPleaseTryAgain;

  /// No description provided for @enterYourEmailAddressFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address first.'**
  String get enterYourEmailAddressFirst;

  /// No description provided for @ifThatAddressHasAnAccountAReset.
  ///
  /// In en, this message translates to:
  /// **'If that address has an account, a reset email has been sent.'**
  String get ifThatAddressHasAnAccountAReset;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyYourEmail;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @verificationEmailRequested.
  ///
  /// In en, this message translates to:
  /// **'Verification email requested.'**
  String get verificationEmailRequested;

  /// No description provided for @sendingVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Sending verification email…'**
  String get sendingVerificationEmail;

  /// No description provided for @emulatorModeWarning.
  ///
  /// In en, this message translates to:
  /// **'Running in emulator mode. Do not use with production credentials.'**
  String get emulatorModeWarning;

  /// No description provided for @sendVerificationEmail.
  ///
  /// In en, this message translates to:
  /// **'Send verification email'**
  String get sendVerificationEmail;

  /// No description provided for @notVerifiedYetOpenTheEmailLinkAnd.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet. Open the email link and try again.'**
  String get notVerifiedYetOpenTheEmailLinkAnd;

  /// No description provided for @iHaveVerifiedMyEmail.
  ///
  /// In en, this message translates to:
  /// **'I have verified my email'**
  String get iHaveVerifiedMyEmail;

  /// No description provided for @useADifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get useADifferentAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get enterYourPassword;

  /// No description provided for @passwordRequirementsMustBeAtLeast10Characters.
  ///
  /// In en, this message translates to:
  /// **'Password requirements: Must be at least 10 characters'**
  String get passwordRequirementsMustBeAtLeast10Characters;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @thePasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get thePasswordsDoNotMatch;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAnAccountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAnAccountSignIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @enterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get enterAValidEmailAddress;

  /// No description provided for @chooseAPasswordThatMeetsThePasswordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Choose a password that meets the password requirements.'**
  String get chooseAPasswordThatMeetsThePasswordRequirements;

  /// No description provided for @unableToCreateThisAccountTrySigningIn.
  ///
  /// In en, this message translates to:
  /// **'Unable to create this account. Try signing in or resetting your password.'**
  String get unableToCreateThisAccountTrySigningIn;

  /// No description provided for @unableToSignInWithThoseDetails.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in with those details.'**
  String get unableToSignInWithThoseDetails;

  /// No description provided for @tooManyAttemptsWaitAWhileBeforeTrying.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a while before trying again.'**
  String get tooManyAttemptsWaitAWhileBeforeTrying;

  /// No description provided for @checkYourConnectionAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkYourConnectionAndTryAgain;

  /// No description provided for @savingAndSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Saving and signing out…'**
  String get savingAndSigningOut;

  /// No description provided for @unableToSignOutPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign out. Please try again.'**
  String get unableToSignOutPleaseTryAgain;

  /// No description provided for @yourChangesCouldNotBeSavedYouAre.
  ///
  /// In en, this message translates to:
  /// **'Your changes could not be saved. You are still signed in. Please try again.'**
  String get yourChangesCouldNotBeSavedYouAre;

  /// No description provided for @unableToRestoreYourSession.
  ///
  /// In en, this message translates to:
  /// **'Unable to restore your session.'**
  String get unableToRestoreYourSession;

  /// No description provided for @unableToConfirmYourSession.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm your session.'**
  String get unableToConfirmYourSession;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @unableToStartTheAppCheckYourConnection.
  ///
  /// In en, this message translates to:
  /// **'Unable to start the app. Check your connection and restart the app. If this continues, contact support.'**
  String get unableToStartTheAppCheckYourConnection;

  /// No description provided for @untitledProject.
  ///
  /// In en, this message translates to:
  /// **'Untitled Project'**
  String get untitledProject;

  /// No description provided for @testHowOneFactorTwoStatesInfluencesPrecision.
  ///
  /// In en, this message translates to:
  /// **'Test how one factor (two states) influences precision'**
  String get testHowOneFactorTwoStatesInfluencesPrecision;

  /// No description provided for @testHowTwoFactorsInfluencePrecision.
  ///
  /// In en, this message translates to:
  /// **'Test how two factors influence precision'**
  String get testHowTwoFactorsInfluencePrecision;

  /// No description provided for @testHowThreeFactorsInfluencePrecision.
  ///
  /// In en, this message translates to:
  /// **'Test how three factors influence precision'**
  String get testHowThreeFactorsInfluencePrecision;

  /// No description provided for @testHowFourFactorsInfluencePrecision.
  ///
  /// In en, this message translates to:
  /// **'Test how four factors influence precision'**
  String get testHowFourFactorsInfluencePrecision;

  /// No description provided for @unableToSaveTheLocalDraftKeepThis.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the local draft. Keep this window open.'**
  String get unableToSaveTheLocalDraftKeepThis;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveConflictYourDraftIsKept.
  ///
  /// In en, this message translates to:
  /// **'Save conflict. Your draft is kept.'**
  String get saveConflictYourDraftIsKept;

  /// No description provided for @projectEditingElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Editing is active in another session. Save any changes there before editing here.'**
  String get projectEditingElsewhere;

  /// No description provided for @projectEditingReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This project is open for viewing.'**
  String get projectEditingReadOnly;

  /// No description provided for @projectEditingStarting.
  ///
  /// In en, this message translates to:
  /// **'Opening for editing…'**
  String get projectEditingStarting;

  /// No description provided for @projectEditingHandoffFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start editing. Check your connection and try again.'**
  String get projectEditingHandoffFailed;

  /// No description provided for @projectEditingDraftKept.
  ///
  /// In en, this message translates to:
  /// **'Editing moved to another session. Review your unsaved draft in the banner.'**
  String get projectEditingDraftKept;

  /// No description provided for @unableToSaveYourChangesAreKept.
  ///
  /// In en, this message translates to:
  /// **'Unable to save. Your changes are kept.'**
  String get unableToSaveYourChangesAreKept;

  /// No description provided for @retrySave.
  ///
  /// In en, this message translates to:
  /// **'Retry save'**
  String get retrySave;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @reviewConflict.
  ///
  /// In en, this message translates to:
  /// **'Review conflict'**
  String get reviewConflict;

  /// No description provided for @resolveSaveConflict.
  ///
  /// In en, this message translates to:
  /// **'Resolve save conflict'**
  String get resolveSaveConflict;

  /// No description provided for @anotherSessionChangedOrDeletedThisProjectKeep.
  ///
  /// In en, this message translates to:
  /// **'Another session changed or deleted this project. Keep editing your draft, save it as a new project, or discard it and load the latest received cloud version. Loading the cloud version discards your local edits.'**
  String get anotherSessionChangedOrDeletedThisProjectKeep;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @saveAsANewProject.
  ///
  /// In en, this message translates to:
  /// **'Save as a new project'**
  String get saveAsANewProject;

  /// No description provided for @discardDraftAndReload.
  ///
  /// In en, this message translates to:
  /// **'Discard draft and reload'**
  String get discardDraftAndReload;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @testDesign.
  ///
  /// In en, this message translates to:
  /// **'Test Design'**
  String get testDesign;

  /// No description provided for @runOrder.
  ///
  /// In en, this message translates to:
  /// **'Run Order'**
  String get runOrder;

  /// No description provided for @replicate.
  ///
  /// In en, this message translates to:
  /// **'Replicate'**
  String get replicate;

  /// No description provided for @groupSize.
  ///
  /// In en, this message translates to:
  /// **'Group Size'**
  String get groupSize;

  /// No description provided for @groupSizeValuesMustBeNumbersPleaseCorrect.
  ///
  /// In en, this message translates to:
  /// **'Group size values must be numbers. Please correct any invalid cells.'**
  String get groupSizeValuesMustBeNumbersPleaseCorrect;

  /// No description provided for @pasteIsOnlyPermittedToTheGroupSize.
  ///
  /// In en, this message translates to:
  /// **'Paste is only permitted to the Group Size column.'**
  String get pasteIsOnlyPermittedToTheGroupSize;

  /// No description provided for @chooseTheStructureOfYourExperiment.
  ///
  /// In en, this message translates to:
  /// **'Choose the Structure of Your Experiment'**
  String get chooseTheStructureOfYourExperiment;

  /// No description provided for @chooseYourRiskLevelChanceOfBeingWrong.
  ///
  /// In en, this message translates to:
  /// **'Choose your risk level (chance of being wrong if test indicates a real difference in factor states)'**
  String get chooseYourRiskLevelChanceOfBeingWrong;

  /// No description provided for @chooseYourSampleSize.
  ///
  /// In en, this message translates to:
  /// **'Choose your sample size'**
  String get chooseYourSampleSize;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectName;

  /// No description provided for @projectNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Project name is required.'**
  String get projectNameIsRequired;

  /// No description provided for @nameFactor.
  ///
  /// In en, this message translates to:
  /// **'Name Factor'**
  String get nameFactor;

  /// No description provided for @nameOneStateOfThatFactor.
  ///
  /// In en, this message translates to:
  /// **'Name one state of that factor'**
  String get nameOneStateOfThatFactor;

  /// No description provided for @nameTheOtherStateOfThatFactor.
  ///
  /// In en, this message translates to:
  /// **'Name the other state of that factor'**
  String get nameTheOtherStateOfThatFactor;

  /// No description provided for @imputeMissingDataWithTheGrandMean.
  ///
  /// In en, this message translates to:
  /// **'Impute missing data with the grand mean'**
  String get imputeMissingDataWithTheGrandMean;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @detectableDifference.
  ///
  /// In en, this message translates to:
  /// **'Detectable difference'**
  String get detectableDifference;

  /// No description provided for @noDetectableDifference.
  ///
  /// In en, this message translates to:
  /// **'No detectable difference'**
  String get noDetectableDifference;

  /// No description provided for @marginal.
  ///
  /// In en, this message translates to:
  /// **'Marginal'**
  String get marginal;

  /// No description provided for @insufficientData.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data'**
  String get insufficientData;

  /// No description provided for @pNGImage.
  ///
  /// In en, this message translates to:
  /// **'PNG image'**
  String get pNGImage;

  /// No description provided for @jPEGImage.
  ///
  /// In en, this message translates to:
  /// **'JPEG image'**
  String get jPEGImage;

  /// No description provided for @pDFDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF document'**
  String get pDFDocument;

  /// No description provided for @projectParameters.
  ///
  /// In en, this message translates to:
  /// **'Project Parameters'**
  String get projectParameters;

  /// No description provided for @grandMean.
  ///
  /// In en, this message translates to:
  /// **'Grand Mean'**
  String get grandMean;

  /// No description provided for @riskLevel.
  ///
  /// In en, this message translates to:
  /// **'Risk Level'**
  String get riskLevel;

  /// No description provided for @detectableDifferenceMessage.
  ///
  /// In en, this message translates to:
  /// **'Detectable Difference'**
  String get detectableDifferenceMessage;

  /// No description provided for @dataMatrix.
  ///
  /// In en, this message translates to:
  /// **'Data Matrix'**
  String get dataMatrix;

  /// No description provided for @couldNotRenderChartForExport.
  ///
  /// In en, this message translates to:
  /// **'Could not render chart for export.'**
  String get couldNotRenderChartForExport;

  /// No description provided for @exportResults.
  ///
  /// In en, this message translates to:
  /// **'Export Results'**
  String get exportResults;

  /// No description provided for @averageGroupSize.
  ///
  /// In en, this message translates to:
  /// **'Average group size'**
  String get averageGroupSize;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @includeDataMatrix.
  ///
  /// In en, this message translates to:
  /// **'Include data matrix'**
  String get includeDataMatrix;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @matrixWillBePlacedBeforeTheGraph.
  ///
  /// In en, this message translates to:
  /// **'Matrix will be placed before the graph.'**
  String get matrixWillBePlacedBeforeTheGraph;

  /// No description provided for @onlyAvailableWhenExportingToPDF.
  ///
  /// In en, this message translates to:
  /// **'Only available when exporting to PDF.'**
  String get onlyAvailableWhenExportingToPDF;

  /// No description provided for @aVG2SHOTGROUPSIZE.
  ///
  /// In en, this message translates to:
  /// **'AVG. 2-SHOT GROUP SIZE'**
  String get aVG2SHOTGROUPSIZE;

  /// No description provided for @aVERAGETWOSHOTGROUPSIZE.
  ///
  /// In en, this message translates to:
  /// **'AVERAGE TWO SHOT GROUP SIZE'**
  String get aVERAGETWOSHOTGROUPSIZE;

  /// No description provided for @noGroupSizeDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No group size data available'**
  String get noGroupSizeDataAvailable;

  /// No description provided for @enterAtLeastOneGroupSizeInThe.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one group size in the data matrix to see results.'**
  String get enterAtLeastOneGroupSizeInThe;

  /// No description provided for @grandMeanMessage.
  ///
  /// In en, this message translates to:
  /// **'Grand mean'**
  String get grandMeanMessage;

  /// No description provided for @riskBounds.
  ///
  /// In en, this message translates to:
  /// **'Risk bounds'**
  String get riskBounds;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get exporting;

  /// No description provided for @riskLevelMessage.
  ///
  /// In en, this message translates to:
  /// **'Risk level'**
  String get riskLevelMessage;

  /// No description provided for @meanGroupSizesPerFactorStateVsGrand.
  ///
  /// In en, this message translates to:
  /// **'Mean group sizes per factor state vs. grand mean'**
  String get meanGroupSizesPerFactorStateVsGrand;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @donations.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get donations;

  /// No description provided for @unableToOpenPayPalPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to open PayPal. Please try again.'**
  String get unableToOpenPayPalPleaseTryAgain;

  /// No description provided for @deleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete project?'**
  String get deleteProject;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @unableToLoadYourProjects.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your projects.'**
  String get unableToLoadYourProjects;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjectsYet;

  /// No description provided for @createYourFirstProjectToStartMeasuringHow.
  ///
  /// In en, this message translates to:
  /// **'Create your first project to start measuring how your chosen factors influence precision.'**
  String get createYourFirstProjectToStartMeasuringHow;

  /// No description provided for @unableToLoadOlderProjectsPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Unable to load older projects. Please try again.'**
  String get unableToLoadOlderProjectsPleaseTryAgain;

  /// No description provided for @loadingOlderProjects.
  ///
  /// In en, this message translates to:
  /// **'Loading older projects…'**
  String get loadingOlderProjects;

  /// No description provided for @retryLoadingOlderProjects.
  ///
  /// In en, this message translates to:
  /// **'Retry loading older projects'**
  String get retryLoadingOlderProjects;

  /// No description provided for @loadOlderProjects.
  ///
  /// In en, this message translates to:
  /// **'Load older projects'**
  String get loadOlderProjects;

  /// No description provided for @deleteProjectMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove \"{project}\" from your cloud account.'**
  String deleteProjectMessage(String project);

  /// No description provided for @switchToLightMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get switchToLightMode;

  /// No description provided for @switchToDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get switchToDarkMode;

  /// No description provided for @factorNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Factor name is required.'**
  String get factorNameIsRequired;

  /// No description provided for @eachFactorNameMustBeUnique.
  ///
  /// In en, this message translates to:
  /// **'Each factor name must be unique.'**
  String get eachFactorNameMustBeUnique;

  /// No description provided for @factorStateIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Factor state is required.'**
  String get factorStateIsRequired;

  /// No description provided for @factorStatesMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'Factor states must be different.'**
  String get factorStatesMustBeDifferent;

  /// No description provided for @dataMatrixMessage.
  ///
  /// In en, this message translates to:
  /// **'Data matrix'**
  String get dataMatrixMessage;

  /// No description provided for @factors.
  ///
  /// In en, this message translates to:
  /// **'Factors'**
  String get factors;

  /// No description provided for @groupSizeColumnDataIsIncompletePleaseFill.
  ///
  /// In en, this message translates to:
  /// **'Group Size column data is incomplete. Please fill out all cells to continue.'**
  String get groupSizeColumnDataIsIncompletePleaseFill;

  /// No description provided for @clearGroupSizes.
  ///
  /// In en, this message translates to:
  /// **'Clear Group Sizes?'**
  String get clearGroupSizes;

  /// No description provided for @areYouSureYouWantToClearAll.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all entered group size values? This action cannot be undone.'**
  String get areYouSureYouWantToClearAll;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @randomizeOrder.
  ///
  /// In en, this message translates to:
  /// **'Randomize order?'**
  String get randomizeOrder;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @errorLoadingMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Error loading markdown'**
  String get errorLoadingMarkdown;

  /// No description provided for @unableToOpenThisLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this link.'**
  String get unableToOpenThisLink;

  /// No description provided for @verifyAddress.
  ///
  /// In en, this message translates to:
  /// **'Verify {email} before opening your workspace.'**
  String verifyAddress(String email);

  /// No description provided for @sendAgainSeconds.
  ///
  /// In en, this message translates to:
  /// **'Send again in {seconds}s'**
  String sendAgainSeconds(int seconds);

  /// No description provided for @requestAnotherEmailSeconds.
  ///
  /// In en, this message translates to:
  /// **'Request another email in {seconds}s'**
  String requestAnotherEmailSeconds(int seconds);

  /// No description provided for @factorNumber.
  ///
  /// In en, this message translates to:
  /// **'Factor {number}'**
  String factorNumber(int number);

  /// No description provided for @detectsDifference.
  ///
  /// In en, this message translates to:
  /// **'Detects a difference of {difference}'**
  String detectsDifference(String difference);

  /// No description provided for @factorRunCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 factor} other{{count} factors}} · {runs} runs'**
  String factorRunCount(int count, int runs);

  /// No description provided for @projectResults.
  ///
  /// In en, this message translates to:
  /// **'{project} — Results'**
  String projectResults(String project);

  /// No description provided for @exportedTo.
  ///
  /// In en, this message translates to:
  /// **'Exported to {path}'**
  String exportedTo(String path);

  /// No description provided for @stateMean.
  ///
  /// In en, this message translates to:
  /// **'{state}: {value}'**
  String stateMean(String state, String value);

  /// No description provided for @perFactorRisk.
  ///
  /// In en, this message translates to:
  /// **'Per-factor results at risk level {risk}'**
  String perFactorRisk(String risk);

  /// No description provided for @factorLegend.
  ///
  /// In en, this message translates to:
  /// **'F{number}: {name}'**
  String factorLegend(int number, String name);

  /// No description provided for @chartTooltip.
  ///
  /// In en, this message translates to:
  /// **'{factor}\n{state}: {value}'**
  String chartTooltip(String factor, String state, String value);

  /// No description provided for @meanRiskLabel.
  ///
  /// In en, this message translates to:
  /// **'Mean / ±{percent}%'**
  String meanRiskLabel(String percent);

  /// No description provided for @createdModified.
  ///
  /// In en, this message translates to:
  /// **'Created {created}  ·  Modified {modified}'**
  String createdModified(String created, String modified);

  /// No description provided for @createdModifiedLines.
  ///
  /// In en, this message translates to:
  /// **'Created {created}\nModified {modified}'**
  String createdModifiedLines(String created, String modified);

  /// No description provided for @groupSamples.
  ///
  /// In en, this message translates to:
  /// **'{total} total group sizes in {replicates} groups of {ranges} group sizes each'**
  String groupSamples(String total, String replicates, String ranges);

  /// No description provided for @replicateSamples.
  ///
  /// In en, this message translates to:
  /// **'{total} total group sizes in {replicates} replicates of {ranges} group sizes each'**
  String replicateSamples(String total, String replicates, String ranges);

  /// No description provided for @shortGroupSamples.
  ///
  /// In en, this message translates to:
  /// **'{total} total group sizes in {replicates} groups of {ranges}'**
  String shortGroupSamples(String total, String replicates, String ranges);

  /// No description provided for @sampleCount.
  ///
  /// In en, this message translates to:
  /// **'{total} total group sizes'**
  String sampleCount(String total);

  /// No description provided for @saveConflictHint.
  ///
  /// In en, this message translates to:
  /// **'{status} Review conflict'**
  String saveConflictHint(String status);

  /// No description provided for @saveActionHint.
  ///
  /// In en, this message translates to:
  /// **'{status} {action}'**
  String saveActionHint(String status, String action);

  /// No description provided for @emailAddressFallback.
  ///
  /// In en, this message translates to:
  /// **'your email address'**
  String get emailAddressFallback;

  /// No description provided for @exportFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to export results. Try again.'**
  String get exportFailure;

  /// No description provided for @percentBand.
  ///
  /// In en, this message translates to:
  /// **'±{percent}%'**
  String percentBand(String percent);

  /// No description provided for @copyrightCredit.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Denton M. Bramwell. All rights reserved. Engineered by Cameron Greenwalt'**
  String get copyrightCredit;

  /// No description provided for @cloneProjectAction.
  ///
  /// In en, this message translates to:
  /// **'Clone project'**
  String get cloneProjectAction;

  /// No description provided for @importProjectAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importProjectAction;

  /// No description provided for @importingProject.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importingProject;

  /// No description provided for @importProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Import project from JSON'**
  String get importProjectTitle;

  /// No description provided for @exportProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Export project to JSON'**
  String get exportProjectTitle;

  /// No description provided for @projectImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Project imported.'**
  String get projectImportSuccess;

  /// No description provided for @projectFileInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file is not a valid project JSON file or exceeds the {limitKiB} KiB limit.'**
  String projectFileInvalid(int limitKiB);

  /// No description provided for @projectFileVersionMismatch.
  ///
  /// In en, this message translates to:
  /// **'This file uses project format {version}. This app supports version {supported}.'**
  String projectFileVersionMismatch(int version, int supported);

  /// No description provided for @projectImportFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not import the project. Check your connection and project list before trying again.'**
  String get projectImportFailure;

  /// No description provided for @projectFileReadFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file. Choose it again and retry.'**
  String get projectFileReadFailure;

  /// No description provided for @projectExportFailure.
  ///
  /// In en, this message translates to:
  /// **'Could not export this project. Try again.'**
  String get projectExportFailure;

  /// No description provided for @projectExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Project file ready.'**
  String get projectExportSuccess;

  /// No description provided for @cloneOfProject.
  ///
  /// In en, this message translates to:
  /// **'Clone of {projectName}'**
  String cloneOfProject(String projectName);

  /// No description provided for @unableToCloneProject.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm the copy. Check the project list before trying again.'**
  String get unableToCloneProject;

  /// No description provided for @deleteProjectAction.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProjectAction;

  /// No description provided for @chartDescription.
  ///
  /// In en, this message translates to:
  /// **'Results chart. Grand mean {mean}. Risk interval {lower} to {upper}. Numerical results for every factor state follow the chart.'**
  String chartDescription(String mean, String lower, String upper);

  /// No description provided for @cachedData.
  ///
  /// In en, this message translates to:
  /// **'Cached data · reconnecting'**
  String get cachedData;

  /// No description provided for @unexpectedAppError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Restart the app and try again.'**
  String get unexpectedAppError;
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
