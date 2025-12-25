import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NXN Warehouses'**
  String get appTitle;

  /// No description provided for @serviceOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Service Overview'**
  String get serviceOverviewTitle;

  /// No description provided for @serviceOverviewBullet1.
  ///
  /// In en, this message translates to:
  /// **'“Khazn & Wasel” is a digital logistics service by NXN that enables individuals and SMEs to manage storage and delivery through the NXN platform or the Waslah app.'**
  String get serviceOverviewBullet1;

  /// No description provided for @serviceOverviewBullet2.
  ///
  /// In en, this message translates to:
  /// **'Choose the number of shelves you need at a central branch (Abu Dhabi, Al Ain, Al Karama, or Sharjah) at a fixed rate of AED 100 per shelf per month.'**
  String get serviceOverviewBullet2;

  /// No description provided for @serviceOverviewBullet3.
  ///
  /// In en, this message translates to:
  /// **'Users can register securely using UAE PASS or email, then select the branch and number of shelves, upload the required documents, and complete payment online.'**
  String get serviceOverviewBullet3;

  /// No description provided for @serviceOverviewBullet4.
  ///
  /// In en, this message translates to:
  /// **'A transparent, simple, and secure end-to-end experience with no hidden fees.'**
  String get serviceOverviewBullet4;

  /// No description provided for @soHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Logistics for\nModern Business'**
  String get soHeroTitle;

  /// No description provided for @soHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Flexible warehousing and logistics services by NXN. Rent by the shelf, pay as you go.'**
  String get soHeroSubtitle;

  /// No description provided for @soStatLocations.
  ///
  /// In en, this message translates to:
  /// **'Prime\nLocations'**
  String get soStatLocations;

  /// No description provided for @soStatSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure\nStorage'**
  String get soStatSecure;

  /// No description provided for @soStatAccess.
  ///
  /// In en, this message translates to:
  /// **'Access\nControl'**
  String get soStatAccess;

  /// No description provided for @soAvailableHubs.
  ///
  /// In en, this message translates to:
  /// **'Available in Our Hubs'**
  String get soAvailableHubs;

  /// No description provided for @soSimplePricing.
  ///
  /// In en, this message translates to:
  /// **'Simple Pricing'**
  String get soSimplePricing;

  /// No description provided for @soPerShelf.
  ///
  /// In en, this message translates to:
  /// **'/shelf'**
  String get soPerShelf;

  /// No description provided for @soFlatRate.
  ///
  /// In en, this message translates to:
  /// **'Monthly flat rate. No hidden fees.'**
  String get soFlatRate;

  /// No description provided for @soGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get soGetStarted;

  /// No description provided for @soPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'Powered by NXN Digital Logistics'**
  String get soPoweredBy;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @supportText.
  ///
  /// In en, this message translates to:
  /// **'Support: support@nxn.ae | 600-599999'**
  String get supportText;

  /// No description provided for @termsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Khazn & Wasel — Terms'**
  String get termsPageTitle;

  /// No description provided for @termsSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsSummaryTitle;

  /// No description provided for @termsPoint1.
  ///
  /// In en, this message translates to:
  /// **'Pricing is based on the number of selected shelves × AED 100 per shelf per month, according to the chosen subscription duration (1–12 months).'**
  String get termsPoint1;

  /// No description provided for @termsPoint2.
  ///
  /// In en, this message translates to:
  /// **'VAT and any applicable platform or service fees may apply in accordance with UAE regulations.'**
  String get termsPoint2;

  /// No description provided for @termsPoint3.
  ///
  /// In en, this message translates to:
  /// **'To use the service, the customer must register through the NXN platform using UAE PASS or email, complete the required information, and submit valid documents for verification.'**
  String get termsPoint3;

  /// No description provided for @termsPoint4.
  ///
  /// In en, this message translates to:
  /// **'Storage of prohibited, hazardous, or illegal items is strictly forbidden under UAE law.'**
  String get termsPoint4;

  /// No description provided for @termsPoint5.
  ///
  /// In en, this message translates to:
  /// **'Access times and handling procedures are subject to the operating rules of the selected branch.'**
  String get termsPoint5;

  /// No description provided for @termsPoint6.
  ///
  /// In en, this message translates to:
  /// **'All payments are processed electronically; digital invoices and receipts are provided within the app.'**
  String get termsPoint6;

  /// No description provided for @termsPoint7.
  ///
  /// In en, this message translates to:
  /// **'Use of the service is subject to NXN policies and all applicable laws and regulations of the United Arab Emirates. If the customer stops or terminates the service, NXN will return the stored goods within 24 to 48 business hours, following the approved handover process and subject to customer availability for collection.'**
  String get termsPoint7;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Terms & Conditions and Privacy Policy.'**
  String get termsAgreement;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @registerText.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get registerText;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @quickRegistration.
  ///
  /// In en, this message translates to:
  /// **'Quick Registration'**
  String get quickRegistration;

  /// No description provided for @uaePassContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue with UAE PASS'**
  String get uaePassContinue;

  /// No description provided for @registerWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Register with Email'**
  String get registerWithEmail;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms & Privacy Policy'**
  String get agreeTerms;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get loginLink;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @minSixChars.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get minSixChars;

  /// No description provided for @agreeTermsError.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the terms first'**
  String get agreeTermsError;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created! Logging in...'**
  String get accountCreated;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @guestMessage.
  ///
  /// In en, this message translates to:
  /// **'Continuing as guest'**
  String get guestMessage;

  /// No description provided for @uaePassSoon.
  ///
  /// In en, this message translates to:
  /// **'UAE PASS flow coming soon…'**
  String get uaePassSoon;

  /// Welcome greeting
  ///
  /// In en, this message translates to:
  /// **'Hi {userName}! 👋'**
  String helloUser(String userName);

  /// No description provided for @findWarehouseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find a warehouse to rent today.'**
  String get findWarehouseSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search warehouses (emirate, shelf, amenity)'**
  String get searchHint;

  /// No description provided for @welcomeBannerText.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Let\'s schedule your storage easily across the UAE.'**
  String get welcomeBannerText;

  /// No description provided for @step1Title.
  ///
  /// In en, this message translates to:
  /// **'Step 1 – Choose emirate(s)'**
  String get step1Title;

  /// No description provided for @step2Title.
  ///
  /// In en, this message translates to:
  /// **'Step 2 – Choose quoting mode'**
  String get step2Title;

  /// No description provided for @chooseBillingPeriod.
  ///
  /// In en, this message translates to:
  /// **'Choose billing period'**
  String get chooseBillingPeriod;

  /// No description provided for @billingPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get billingPeriodMonthly;

  /// No description provided for @billingPeriod3Months.
  ///
  /// In en, this message translates to:
  /// **'3 months'**
  String get billingPeriod3Months;

  /// No description provided for @billingPeriod1Year.
  ///
  /// In en, this message translates to:
  /// **'1 year'**
  String get billingPeriod1Year;

  /// No description provided for @billingPeriodSubtitleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Pay per month'**
  String get billingPeriodSubtitleMonthly;

  /// No description provided for @billingPeriodSubtitle3Months.
  ///
  /// In en, this message translates to:
  /// **'Quarterly billing'**
  String get billingPeriodSubtitle3Months;

  /// No description provided for @billingPeriodSubtitle1Year.
  ///
  /// In en, this message translates to:
  /// **'Yearly billing'**
  String get billingPeriodSubtitle1Year;

  /// No description provided for @billingExplanation.
  ///
  /// In en, this message translates to:
  /// **'Prices are calculated per month. Choose how long you want to bill for.'**
  String get billingExplanation;

  /// No description provided for @singleWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Single warehouse'**
  String get singleWarehouse;

  /// No description provided for @multiWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Multi warehouse'**
  String get multiWarehouse;

  /// No description provided for @noEmirateSelected.
  ///
  /// In en, this message translates to:
  /// **'No emirate selected'**
  String get noEmirateSelected;

  /// No description provided for @noEmirateSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Select at least one emirate to see available warehouses.'**
  String get noEmirateSelectedMessage;

  /// No description provided for @noWarehousesFound.
  ///
  /// In en, this message translates to:
  /// **'No warehouses shown'**
  String get noWarehousesFound;

  /// No description provided for @noWarehousesFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No warehouses in the selected emirate(s).'**
  String get noWarehousesFoundMessage;

  /// No description provided for @selectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one warehouse in multi mode.'**
  String get selectAtLeastOne;

  /// No description provided for @countEmirates.
  ///
  /// In en, this message translates to:
  /// **'emirate(s)'**
  String get countEmirates;

  /// No description provided for @countWarehouses.
  ///
  /// In en, this message translates to:
  /// **'warehouse(s)'**
  String get countWarehouses;

  /// No description provided for @pricePerShelfMonth.
  ///
  /// In en, this message translates to:
  /// **'AED / shelf / month'**
  String get pricePerShelfMonth;

  /// No description provided for @getQuote.
  ///
  /// In en, this message translates to:
  /// **'Get quote'**
  String get getQuote;

  /// No description provided for @include.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get include;

  /// No description provided for @quoteSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote Summary'**
  String get quoteSummaryTitle;

  /// No description provided for @combinedQuoteSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Combined Quote Summary'**
  String get combinedQuoteSummaryTitle;

  /// No description provided for @warehouseLabel.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get warehouseLabel;

  /// No description provided for @shelvesLabel.
  ///
  /// In en, this message translates to:
  /// **'Shelves'**
  String get shelvesLabel;

  /// No description provided for @subtotalMonth.
  ///
  /// In en, this message translates to:
  /// **'Subtotal (per month)'**
  String get subtotalMonth;

  /// No description provided for @platformFeeMonth.
  ///
  /// In en, this message translates to:
  /// **'Platform fee (per month)'**
  String get platformFeeMonth;

  /// No description provided for @vatMonth.
  ///
  /// In en, this message translates to:
  /// **'VAT 5% (per month)'**
  String get vatMonth;

  /// No description provided for @totalMonth.
  ///
  /// In en, this message translates to:
  /// **'Total (per month)'**
  String get totalMonth;

  /// No description provided for @billingPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing period'**
  String get billingPeriodLabel;

  /// No description provided for @totalPeriod.
  ///
  /// In en, this message translates to:
  /// **'Total for period'**
  String get totalPeriod;

  /// No description provided for @grandSubtotalMonth.
  ///
  /// In en, this message translates to:
  /// **'Grand Subtotal (per month)'**
  String get grandSubtotalMonth;

  /// No description provided for @grandPlatformFeeMonth.
  ///
  /// In en, this message translates to:
  /// **'Grand Platform fee (per month)'**
  String get grandPlatformFeeMonth;

  /// No description provided for @grandVatMonth.
  ///
  /// In en, this message translates to:
  /// **'Grand VAT (per month)'**
  String get grandVatMonth;

  /// No description provided for @grandTotalMonth.
  ///
  /// In en, this message translates to:
  /// **'Grand Total (per month)'**
  String get grandTotalMonth;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @continuePayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to payment'**
  String get continuePayment;

  /// No description provided for @combinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Combined'**
  String get combinedLabel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @tenantOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Tenant / Owner'**
  String get tenantOwnerLabel;

  /// No description provided for @bookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookingsLabel;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabel;

  /// No description provided for @rentedShelvesLabel.
  ///
  /// In en, this message translates to:
  /// **'Rented Shelves'**
  String get rentedShelvesLabel;

  /// No description provided for @kycDocsTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC & Documents'**
  String get kycDocsTitle;

  /// No description provided for @kycDocsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emirates ID, trade license'**
  String get kycDocsSubtitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language (English / العربية)'**
  String get languageTitle;

  /// No description provided for @marketplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'My Marketplace Store'**
  String get marketplaceTitle;

  /// No description provided for @marketplaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage SME / home seller shop'**
  String get marketplaceSubtitle;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Search warehouses, e.g. Al Quoz'**
  String get searchFieldHint;

  /// No description provided for @emirateLabel.
  ///
  /// In en, this message translates to:
  /// **'Emirate'**
  String get emirateLabel;

  /// No description provided for @minShelvesLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Shelves'**
  String get minShelvesLabel;

  /// No description provided for @resultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultsLabel;

  /// No description provided for @shelvesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} Shelves Available'**
  String shelvesAvailable(Object count);

  /// No description provided for @pricePerShelf.
  ///
  /// In en, this message translates to:
  /// **'AED {price}/Shelf'**
  String pricePerShelf(Object price);

  /// No description provided for @access247.
  ///
  /// In en, this message translates to:
  /// **'24/7 Access'**
  String get access247;

  /// No description provided for @businessHours.
  ///
  /// In en, this message translates to:
  /// **'Business Hours'**
  String get businessHours;

  /// No description provided for @getInstantQuote.
  ///
  /// In en, this message translates to:
  /// **'Get Instant Quote'**
  String get getInstantQuote;

  /// No description provided for @emirateAndShelves.
  ///
  /// In en, this message translates to:
  /// **'{emirate} • {count} Shelves'**
  String emirateAndShelves(Object count, Object emirate);

  /// No description provided for @selectWarehouseTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a warehouse'**
  String get selectWarehouseTitle;

  /// No description provided for @noWarehousesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No warehouses available.'**
  String get noWarehousesAvailable;

  /// No description provided for @chooseWarehouseHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a warehouse'**
  String get chooseWarehouseHint;

  /// No description provided for @openButton.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openButton;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get navStore;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get navPayments;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @paymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get paymentsTitle;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get filterByStatus;

  /// No description provided for @noInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No invoices yet'**
  String get noInvoicesTitle;

  /// No description provided for @noInvoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your booking invoices and VAT receipts will appear here.'**
  String get noInvoicesSubtitle;

  /// No description provided for @choosePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose payment method'**
  String get choosePaymentMethod;

  /// No description provided for @payByCard.
  ///
  /// In en, this message translates to:
  /// **'Pay by Card'**
  String get payByCard;

  /// No description provided for @payByCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visa / Mastercard / AMEX'**
  String get payByCardSubtitle;

  /// No description provided for @applePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get applePay;

  /// No description provided for @applePaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fast checkout with Apple Wallet'**
  String get applePaySubtitle;

  /// No description provided for @applePayNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available on iOS'**
  String get applePayNotAvailable;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing card payment…'**
  String get processingPayment;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful. Thank you!'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get paymentFailed;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get viewReceipt;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @invoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice {number}'**
  String invoiceTitle(Object number);

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @vatLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT (5%)'**
  String get vatLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @paidTag.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidTag;

  /// No description provided for @pendingTag.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTag;

  /// No description provided for @deliveryRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery Request'**
  String get deliveryRequestTitle;

  /// No description provided for @deliveryRequestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details below to arrange your delivery.'**
  String get deliveryRequestSubtitle;

  /// No description provided for @shippingOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipping Options'**
  String get shippingOptionsTitle;

  /// No description provided for @shippingCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping Company'**
  String get shippingCompanyLabel;

  /// No description provided for @deliveryTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Type'**
  String get deliveryTypeLabel;

  /// No description provided for @deliveryModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Mode'**
  String get deliveryModeLabel;

  /// No description provided for @domesticLabel.
  ///
  /// In en, this message translates to:
  /// **'Domestic'**
  String get domesticLabel;

  /// No description provided for @internationalLabel.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get internationalLabel;

  /// No description provided for @deliveryLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocationTitle;

  /// No description provided for @cityEmirateLabel.
  ///
  /// In en, this message translates to:
  /// **'City (Emirate)'**
  String get cityEmirateLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @recipientDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipient Details'**
  String get recipientDetailsTitle;

  /// No description provided for @recipientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient Name'**
  String get recipientNameLabel;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @fullAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddressLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @submitRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Delivery Request'**
  String get submitRequestButton;

  /// No description provided for @requestSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Delivery request submitted for {location}'**
  String requestSubmittedMessage(Object location);

  /// No description provided for @requestFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request'**
  String get requestFailedMessage;

  /// No description provided for @selectShippingCompanyError.
  ///
  /// In en, this message translates to:
  /// **'Please select a shipping company'**
  String get selectShippingCompanyError;

  /// No description provided for @selectCityError.
  ///
  /// In en, this message translates to:
  /// **'Please select a city (emirate)'**
  String get selectCityError;

  /// No description provided for @selectCountryCityError.
  ///
  /// In en, this message translates to:
  /// **'Please select country and city'**
  String get selectCountryCityError;

  /// No description provided for @enterRecipientNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter recipient name'**
  String get enterRecipientNameError;

  /// No description provided for @enterPhoneNumberError.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumberError;

  /// No description provided for @enterAddressError.
  ///
  /// In en, this message translates to:
  /// **'Enter full address'**
  String get enterAddressError;

  /// No description provided for @myStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'My Store'**
  String get myStoreTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your inventory and orders.'**
  String get dashboardSubtitle;

  /// No description provided for @shelvesStat.
  ///
  /// In en, this message translates to:
  /// **'Shelves'**
  String get shelvesStat;

  /// No description provided for @shelvesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'100 AED/mo each'**
  String get shelvesSubtitle;

  /// No description provided for @itemsStat.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsStat;

  /// No description provided for @inStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStockSubtitle;

  /// No description provided for @pendingOrdersStat.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrdersStat;

  /// No description provided for @requiresActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requires Action'**
  String get requiresActionSubtitle;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActionsTitle;

  /// No description provided for @bookDropoffAction.
  ///
  /// In en, this message translates to:
  /// **'Book Drop-off'**
  String get bookDropoffAction;

  /// No description provided for @myInventoryAction.
  ///
  /// In en, this message translates to:
  /// **'My Inventory'**
  String get myInventoryAction;

  /// No description provided for @productCatalogAction.
  ///
  /// In en, this message translates to:
  /// **'Product Catalog'**
  String get productCatalogAction;

  /// No description provided for @requestDeliveryAction.
  ///
  /// In en, this message translates to:
  /// **'Request Delivery'**
  String get requestDeliveryAction;

  /// No description provided for @myInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'My Inventory'**
  String get myInventoryTitle;

  /// No description provided for @noInventory.
  ///
  /// In en, this message translates to:
  /// **'No inventory items found.'**
  String get noInventory;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty: {count}'**
  String qtyLabel(Object count);

  /// No description provided for @shelfLabel.
  ///
  /// In en, this message translates to:
  /// **'Shelf: {id}'**
  String shelfLabel(Object id);

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(Object status);

  /// No description provided for @itemInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get itemInStock;

  /// No description provided for @itemOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get itemOutOfStock;

  /// No description provided for @unknownProduct.
  ///
  /// In en, this message translates to:
  /// **'Unknown Product'**
  String get unknownProduct;

  /// No description provided for @productCatalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Catalog'**
  String get productCatalogTitle;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found. Add your first item!'**
  String get noProductsFound;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} AED'**
  String productPrice(Object price);

  /// No description provided for @addProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductTitle;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productNameLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (AED)'**
  String get priceLabel;

  /// No description provided for @saveProductButton.
  ///
  /// In en, this message translates to:
  /// **'Save Product'**
  String get saveProductButton;

  /// No description provided for @requiredError.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredError;

  /// No description provided for @invalidNumberError.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumberError;

  /// No description provided for @bookDropoffTitle.
  ///
  /// In en, this message translates to:
  /// **'Book Drop-off'**
  String get bookDropoffTitle;

  /// No description provided for @expectedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Date'**
  String get expectedDateLabel;

  /// No description provided for @approxItemCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Approx. Item Count'**
  String get approxItemCountLabel;

  /// No description provided for @notesFragileLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (e.g. Fragile items)'**
  String get notesFragileLabel;

  /// No description provided for @submitDropoffButton.
  ///
  /// In en, this message translates to:
  /// **'Book Drop-off'**
  String get submitDropoffButton;

  /// No description provided for @dropoffSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Drop-off request submitted!'**
  String get dropoffSubmittedMessage;

  /// No description provided for @mpRequestDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Delivery'**
  String get mpRequestDeliveryTitle;

  /// No description provided for @customerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerNameLabel;

  /// No description provided for @deliveryAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddressLabel;

  /// No description provided for @methodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get methodLabel;

  /// No description provided for @standardDeliveryOption.
  ///
  /// In en, this message translates to:
  /// **'Standard Delivery'**
  String get standardDeliveryOption;

  /// No description provided for @customerPickupOption.
  ///
  /// In en, this message translates to:
  /// **'Customer Pickup'**
  String get customerPickupOption;

  /// No description provided for @mpSubmitRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get mpSubmitRequestButton;

  /// No description provided for @deliveryRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Delivery request submitted!'**
  String get deliveryRequestSubmitted;

  /// No description provided for @warehouseProductLabel.
  ///
  /// In en, this message translates to:
  /// **'Warehouse / Product'**
  String get warehouseProductLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @receiveGoodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive Goods – Drop-off'**
  String get receiveGoodsTitle;

  /// No description provided for @processInfo.
  ///
  /// In en, this message translates to:
  /// **'Process: Schedule → Prepare bay & workers → Receive & inspect → Update system.'**
  String get processInfo;

  /// No description provided for @scheduleStep.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleStep;

  /// No description provided for @preparationStep.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get preparationStep;

  /// No description provided for @updateStep.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateStep;

  /// No description provided for @scheduleDropoffTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Drop-off'**
  String get scheduleDropoffTitle;

  /// No description provided for @scheduleDropoffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drop-off only: book a time for the seller to bring goods to the warehouse.'**
  String get scheduleDropoffSubtitle;

  /// No description provided for @scheduleDropoffSubtitleScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled: {date}'**
  String scheduleDropoffSubtitleScheduled(Object date);

  /// No description provided for @nowPlus2h.
  ///
  /// In en, this message translates to:
  /// **'Now +2h'**
  String get nowPlus2h;

  /// No description provided for @tomorrow10am.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow 10:00'**
  String get tomorrow10am;

  /// No description provided for @nextMon10am.
  ///
  /// In en, this message translates to:
  /// **'Next Mon 10:00'**
  String get nextMon10am;

  /// No description provided for @chooseDateTime.
  ///
  /// In en, this message translates to:
  /// **'Choose date & time'**
  String get chooseDateTime;

  /// No description provided for @prepareBayTitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare bay & workers'**
  String get prepareBayTitle;

  /// No description provided for @prepareBaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign a bay for the shelves and choose the number of workers for receiving.'**
  String get prepareBaySubtitle;

  /// No description provided for @prepareBaySubtitlePrepared.
  ///
  /// In en, this message translates to:
  /// **'{storageMode} • Bay {bay}'**
  String prepareBaySubtitlePrepared(Object bay, Object storageMode);

  /// No description provided for @storageModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage model'**
  String get storageModelLabel;

  /// No description provided for @storageModelValue.
  ///
  /// In en, this message translates to:
  /// **'Home seller shelves (per approved quote)'**
  String get storageModelValue;

  /// No description provided for @assignBayLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign bay'**
  String get assignBayLabel;

  /// No description provided for @bayLabel.
  ///
  /// In en, this message translates to:
  /// **'Bay {bay}'**
  String bayLabel(Object bay);

  /// No description provided for @workersRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Workers required (50 AED each)'**
  String get workersRequiredLabel;

  /// No description provided for @labourCostEst.
  ///
  /// In en, this message translates to:
  /// **'Receiving is based on count. Estimated labour cost: AED {cost}'**
  String labourCostEst(Object cost);

  /// No description provided for @preparedButton.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get preparedButton;

  /// No description provided for @confirmPreparationButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm preparation'**
  String get confirmPreparationButton;

  /// No description provided for @inspectionPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Inspection & photos'**
  String get inspectionPhotosTitle;

  /// No description provided for @inspectionPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drop-off only. Receiving is based on count. If damaged items are found, warehouse admin can document them with photos. Listing photos are a separate value-added service.'**
  String get inspectionPhotosSubtitle;

  /// No description provided for @adminDocumentPhotos.
  ///
  /// In en, this message translates to:
  /// **'Admin to document damaged items with photos'**
  String get adminDocumentPhotos;

  /// No description provided for @adminDocumentPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used only if damages are found during receiving'**
  String get adminDocumentPhotosSubtitle;

  /// No description provided for @listingPhotosService.
  ///
  /// In en, this message translates to:
  /// **'Photos for online listing (value-added service)'**
  String get listingPhotosService;

  /// No description provided for @listingPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optimised product photos for marketplace / SMEs / home sellers'**
  String get listingPhotosSubtitle;

  /// No description provided for @notesAdminLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes for warehouse admin (optional)'**
  String get notesAdminLabel;

  /// No description provided for @instantUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Update'**
  String get instantUpdateTitle;

  /// No description provided for @instantUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push storage No. and stock status to seller dashboard / marketplace.'**
  String get instantUpdateSubtitle;

  /// No description provided for @instantUpdateSubtitleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Storage #: {storageNo} • Status: {status}'**
  String instantUpdateSubtitleUpdated(Object status, Object storageNo);

  /// No description provided for @updateNowButton.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNowButton;

  /// No description provided for @updatedButton.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updatedButton;

  /// No description provided for @copyStorageNo.
  ///
  /// In en, this message translates to:
  /// **'Copy storage #'**
  String get copyStorageNo;

  /// No description provided for @stockStatusReceived.
  ///
  /// In en, this message translates to:
  /// **'Received & Stored'**
  String get stockStatusReceived;

  /// No description provided for @stockStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get stockStatusPending;

  /// No description provided for @lastInboundTitle.
  ///
  /// In en, this message translates to:
  /// **'Last inbound from receiving'**
  String get lastInboundTitle;

  /// No description provided for @smartStorageNo.
  ///
  /// In en, this message translates to:
  /// **'Storage #'**
  String get smartStorageNo;

  /// No description provided for @smartBay.
  ///
  /// In en, this message translates to:
  /// **'Bay'**
  String get smartBay;

  /// No description provided for @smartScheduledAt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled at'**
  String get smartScheduledAt;

  /// No description provided for @smartStorageModel.
  ///
  /// In en, this message translates to:
  /// **'Storage model'**
  String get smartStorageModel;

  /// No description provided for @smartWorkers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get smartWorkers;

  /// No description provided for @damagePhotosByAdminLabel.
  ///
  /// In en, this message translates to:
  /// **'Damage photos by admin'**
  String get damagePhotosByAdminLabel;

  /// No description provided for @yesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noLabel;

  /// No description provided for @listingPhotosServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Listing photos service'**
  String get listingPhotosServiceLabel;

  /// No description provided for @inStockSmart.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStockSmart;

  /// No description provided for @lowStockSmart.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStockSmart;

  /// No description provided for @outOfStockSmart.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStockSmart;

  /// No description provided for @warehouseStockOverview.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Stock Overview'**
  String get warehouseStockOverview;

  /// No description provided for @noChartData.
  ///
  /// In en, this message translates to:
  /// **'No chart data'**
  String get noChartData;

  /// No description provided for @visualAnalyticsText.
  ///
  /// In en, this message translates to:
  /// **'Visual analytics of quantities by category. Auto-updates on refresh.'**
  String get visualAnalyticsText;

  /// No description provided for @requestDeliveryBtn.
  ///
  /// In en, this message translates to:
  /// **'Request Delivery'**
  String get requestDeliveryBtn;

  /// No description provided for @restockBtn.
  ///
  /// In en, this message translates to:
  /// **'Restock'**
  String get restockBtn;

  /// No description provided for @viewReportsBtn.
  ///
  /// In en, this message translates to:
  /// **'View Reports'**
  String get viewReportsBtn;

  /// No description provided for @restockCreated.
  ///
  /// In en, this message translates to:
  /// **'Restock created'**
  String get restockCreated;

  /// No description provided for @restockFailed.
  ///
  /// In en, this message translates to:
  /// **'Restock failed'**
  String get restockFailed;

  /// No description provided for @openingReports.
  ///
  /// In en, this message translates to:
  /// **'Opening reports…'**
  String get openingReports;

  /// No description provided for @noReportsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No reports available'**
  String get noReportsAvailable;

  /// No description provided for @instantQuoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Quote'**
  String get instantQuoteTitle;

  /// No description provided for @instantQuoteMultiTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Quote (Multiple Warehouses)'**
  String get instantQuoteMultiTitle;

  /// No description provided for @numberOfShelvesHelper.
  ///
  /// In en, this message translates to:
  /// **'Number of shelves'**
  String get numberOfShelvesHelper;

  /// No description provided for @rateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rateLabel;

  /// No description provided for @perShelfSuffix.
  ///
  /// In en, this message translates to:
  /// **'/ shelf'**
  String get perShelfSuffix;

  /// No description provided for @shelvesForWarehouseLabel.
  ///
  /// In en, this message translates to:
  /// **'Shelves for this warehouse'**
  String get shelvesForWarehouseLabel;

  /// No description provided for @shelvesForSiteHelper.
  ///
  /// In en, this message translates to:
  /// **'Number of shelves for this site'**
  String get shelvesForSiteHelper;

  /// No description provided for @grandSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Subtotal'**
  String get grandSubtotal;

  /// No description provided for @grandPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Grand Platform fee'**
  String get grandPlatformFee;

  /// No description provided for @grandVat.
  ///
  /// In en, this message translates to:
  /// **'Grand VAT'**
  String get grandVat;

  /// No description provided for @totalThisWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Total (this warehouse)'**
  String get totalThisWarehouse;

  /// No description provided for @calculateButton.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculateButton;

  /// No description provided for @totalAedLabel.
  ///
  /// In en, this message translates to:
  /// **'Total (AED)'**
  String get totalAedLabel;

  /// No description provided for @estimatedTotalTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated Total (per month)'**
  String get estimatedTotalTitle;

  /// No description provided for @platformFeeRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform fee ({rate}%)'**
  String platformFeeRateLabel(Object rate);

  /// No description provided for @vatRateLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT {rate}%'**
  String vatRateLabel(Object rate);

  /// No description provided for @closeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  /// No description provided for @receiptPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptPageTitle;

  /// No description provided for @taxInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Invoice'**
  String get taxInvoiceLabel;

  /// No description provided for @trnLabel.
  ///
  /// In en, this message translates to:
  /// **'TRN'**
  String get trnLabel;

  /// No description provided for @vendorName.
  ///
  /// In en, this message translates to:
  /// **'NXN Logistics LLC'**
  String get vendorName;

  /// No description provided for @vendorAddress.
  ///
  /// In en, this message translates to:
  /// **'Abu Dhabi, UAE'**
  String get vendorAddress;

  /// No description provided for @billToLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill To'**
  String get billToLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodLabel;

  /// No description provided for @transactionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionIdLabel;

  /// No description provided for @itemDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get itemDescription;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsTitle;

  /// No description provided for @pushNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsLabel;

  /// No description provided for @emailNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotificationsLabel;

  /// No description provided for @smsNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS Notifications'**
  String get smsNotificationsLabel;

  /// No description provided for @marketingUpdatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Marketing Updates'**
  String get marketingUpdatesLabel;

  /// No description provided for @kycPageTitle.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification'**
  String get kycPageTitle;

  /// No description provided for @uploadIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload Emirates ID'**
  String get uploadIdLabel;

  /// No description provided for @uploadTradeLicenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload Trade License'**
  String get uploadTradeLicenseLabel;

  /// No description provided for @sellerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Settings'**
  String get sellerSettingsTitle;

  /// No description provided for @autoAcceptOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-accept Orders'**
  String get autoAcceptOrdersLabel;

  /// No description provided for @vacationModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Vacation Mode'**
  String get vacationModeLabel;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// No description provided for @uploadPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload photo'**
  String get uploadPhotoLabel;

  /// No description provided for @smartWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Smart Warehouse'**
  String get smartWarehouse;

  /// No description provided for @gatePassTitle.
  ///
  /// In en, this message translates to:
  /// **'Gate Pass'**
  String get gatePassTitle;

  /// No description provided for @gatePassSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show this QR code at the warehouse gate for entry.'**
  String get gatePassSubtitle;

  /// No description provided for @scanForEntry.
  ///
  /// In en, this message translates to:
  /// **'Scan for Entry'**
  String get scanForEntry;

  /// No description provided for @bookingRef.
  ///
  /// In en, this message translates to:
  /// **'Booking Ref'**
  String get bookingRef;

  /// No description provided for @warehouseLocation.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Location'**
  String get warehouseLocation;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @trackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Shipment Tracking'**
  String get trackingTitle;

  /// No description provided for @trackingNumber.
  ///
  /// In en, this message translates to:
  /// **'Tracking Number'**
  String get trackingNumber;

  /// No description provided for @estimatedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Est. Delivery'**
  String get estimatedDelivery;

  /// No description provided for @statusInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get statusInTransit;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @trackShipment.
  ///
  /// In en, this message translates to:
  /// **'Track Shipment'**
  String get trackShipment;

  /// No description provided for @totalShelves.
  ///
  /// In en, this message translates to:
  /// **'Total Shelves'**
  String get totalShelves;

  /// No description provided for @stockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get stockValue;

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'Low Stock: {count}'**
  String lowStockCount(Object count);

  /// No description provided for @outOfStockCount.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock: {count}'**
  String outOfStockCount(Object count);

  /// No description provided for @activeRentals.
  ///
  /// In en, this message translates to:
  /// **'Active Rentals'**
  String get activeRentals;

  /// No description provided for @managingLabel.
  ///
  /// In en, this message translates to:
  /// **'Managing'**
  String get managingLabel;

  /// No description provided for @bookSpace.
  ///
  /// In en, this message translates to:
  /// **'Book Space'**
  String get bookSpace;

  /// No description provided for @findNewShelves.
  ///
  /// In en, this message translates to:
  /// **'Find new shelves'**
  String get findNewShelves;

  /// No description provided for @shipToCustomers.
  ///
  /// In en, this message translates to:
  /// **'Ship to customers'**
  String get shipToCustomers;

  /// No description provided for @manageStock.
  ///
  /// In en, this message translates to:
  /// **'Manage stock'**
  String get manageStock;

  /// No description provided for @viewInvoices.
  ///
  /// In en, this message translates to:
  /// **'View invoices'**
  String get viewInvoices;

  /// No description provided for @warehousePrep.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Preparation'**
  String get warehousePrep;

  /// No description provided for @scheduleDropoffShort.
  ///
  /// In en, this message translates to:
  /// **'Schedule drop-off'**
  String get scheduleDropoffShort;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
