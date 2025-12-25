// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NXN Warehouses';

  @override
  String get serviceOverviewTitle => 'Service Overview';

  @override
  String get serviceOverviewBullet1 =>
      '“Khazn & Wasel” is a digital logistics service by NXN that enables individuals and SMEs to manage storage and delivery through the NXN platform or the Waslah app.';

  @override
  String get serviceOverviewBullet2 =>
      'Choose the number of shelves you need at a central branch (Abu Dhabi, Al Ain, Al Karama, or Sharjah) at a fixed rate of AED 100 per shelf per month.';

  @override
  String get serviceOverviewBullet3 =>
      'Users can register securely using UAE PASS or email, then select the branch and number of shelves, upload the required documents, and complete payment online.';

  @override
  String get serviceOverviewBullet4 =>
      'A transparent, simple, and secure end-to-end experience with no hidden fees.';

  @override
  String get soHeroTitle => 'Smart Logistics for\nModern Business';

  @override
  String get soHeroSubtitle =>
      'Flexible warehousing and logistics services by NXN. Rent by the shelf, pay as you go.';

  @override
  String get soStatLocations => 'Prime\nLocations';

  @override
  String get soStatSecure => 'Secure\nStorage';

  @override
  String get soStatAccess => 'Access\nControl';

  @override
  String get soAvailableHubs => 'Available in Our Hubs';

  @override
  String get soSimplePricing => 'Simple Pricing';

  @override
  String get soPerShelf => '/shelf';

  @override
  String get soFlatRate => 'Monthly flat rate. No hidden fees.';

  @override
  String get soGetStarted => 'Get Started';

  @override
  String get soPoweredBy => 'Powered by NXN Digital Logistics';

  @override
  String get continueButton => 'Continue';

  @override
  String get supportText => 'Support: support@nxn.ae | 600-599999';

  @override
  String get termsPageTitle => 'Khazn & Wasel — Terms';

  @override
  String get termsSummaryTitle => 'Terms & Conditions';

  @override
  String get termsPoint1 =>
      'Pricing is based on the number of selected shelves × AED 100 per shelf per month, according to the chosen subscription duration (1–12 months).';

  @override
  String get termsPoint2 =>
      'VAT and any applicable platform or service fees may apply in accordance with UAE regulations.';

  @override
  String get termsPoint3 =>
      'To use the service, the customer must register through the NXN platform using UAE PASS or email, complete the required information, and submit valid documents for verification.';

  @override
  String get termsPoint4 =>
      'Storage of prohibited, hazardous, or illegal items is strictly forbidden under UAE law.';

  @override
  String get termsPoint5 =>
      'Access times and handling procedures are subject to the operating rules of the selected branch.';

  @override
  String get termsPoint6 =>
      'All payments are processed electronically; digital invoices and receipts are provided within the app.';

  @override
  String get termsPoint7 =>
      'Use of the service is subject to NXN policies and all applicable laws and regulations of the United Arab Emirates. If the customer stops or terminates the service, NXN will return the stored goods within 24 to 48 business hours, following the approved handover process and subject to customer availability for collection.';

  @override
  String get termsAgreement =>
      'I have read and agree to the Terms & Conditions and Privacy Policy.';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get registerText => 'Don\'t have an account? Register';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get quickRegistration => 'Quick Registration';

  @override
  String get uaePassContinue => 'Continue with UAE PASS';

  @override
  String get registerWithEmail => 'Register with Email';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get agreeTerms => 'I agree to the Terms & Privacy Policy';

  @override
  String get createAccount => 'Create Account';

  @override
  String get loginLink => 'Already have an account? Log in';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get minSixChars => 'Minimum 6 characters';

  @override
  String get agreeTermsError => 'Please agree to the terms first';

  @override
  String get accountCreated => 'Account created! Logging in...';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get guestMessage => 'Continuing as guest';

  @override
  String get uaePassSoon => 'UAE PASS flow coming soon…';

  @override
  String helloUser(String userName) {
    return 'Hi $userName! 👋';
  }

  @override
  String get findWarehouseSubtitle => 'Find a warehouse to rent today.';

  @override
  String get searchHint => 'Search warehouses (emirate, shelf, amenity)';

  @override
  String get welcomeBannerText =>
      'Welcome! Let\'s schedule your storage easily across the UAE.';

  @override
  String get step1Title => 'Step 1 – Choose emirate(s)';

  @override
  String get step2Title => 'Step 2 – Choose quoting mode';

  @override
  String get chooseBillingPeriod => 'Choose billing period';

  @override
  String get billingPeriodMonthly => 'Monthly';

  @override
  String get billingPeriod3Months => '3 months';

  @override
  String get billingPeriod1Year => '1 year';

  @override
  String get billingPeriodSubtitleMonthly => 'Pay per month';

  @override
  String get billingPeriodSubtitle3Months => 'Quarterly billing';

  @override
  String get billingPeriodSubtitle1Year => 'Yearly billing';

  @override
  String get billingExplanation =>
      'Prices are calculated per month. Choose how long you want to bill for.';

  @override
  String get singleWarehouse => 'Single warehouse';

  @override
  String get multiWarehouse => 'Multi warehouse';

  @override
  String get noEmirateSelected => 'No emirate selected';

  @override
  String get noEmirateSelectedMessage =>
      'Select at least one emirate to see available warehouses.';

  @override
  String get noWarehousesFound => 'No warehouses shown';

  @override
  String get noWarehousesFoundMessage =>
      'No warehouses in the selected emirate(s).';

  @override
  String get selectAtLeastOne => 'Select at least one warehouse in multi mode.';

  @override
  String get countEmirates => 'emirate(s)';

  @override
  String get countWarehouses => 'warehouse(s)';

  @override
  String get pricePerShelfMonth => 'AED / shelf / month';

  @override
  String get getQuote => 'Get quote';

  @override
  String get include => 'Include';

  @override
  String get quoteSummaryTitle => 'Quote Summary';

  @override
  String get combinedQuoteSummaryTitle => 'Combined Quote Summary';

  @override
  String get warehouseLabel => 'Warehouse';

  @override
  String get shelvesLabel => 'Shelves';

  @override
  String get subtotalMonth => 'Subtotal (per month)';

  @override
  String get platformFeeMonth => 'Platform fee (per month)';

  @override
  String get vatMonth => 'VAT 5% (per month)';

  @override
  String get totalMonth => 'Total (per month)';

  @override
  String get billingPeriodLabel => 'Billing period';

  @override
  String get totalPeriod => 'Total for period';

  @override
  String get grandSubtotalMonth => 'Grand Subtotal (per month)';

  @override
  String get grandPlatformFeeMonth => 'Grand Platform fee (per month)';

  @override
  String get grandVatMonth => 'Grand VAT (per month)';

  @override
  String get grandTotalMonth => 'Grand Total (per month)';

  @override
  String get close => 'Close';

  @override
  String get continuePayment => 'Continue to payment';

  @override
  String get combinedLabel => 'Combined';

  @override
  String get profileTitle => 'Profile';

  @override
  String get tenantOwnerLabel => 'Tenant / Owner';

  @override
  String get bookingsLabel => 'Bookings';

  @override
  String get savedLabel => 'Saved';

  @override
  String get rentedShelvesLabel => 'Rented Shelves';

  @override
  String get kycDocsTitle => 'KYC & Documents';

  @override
  String get kycDocsSubtitle => 'Emirates ID, trade license';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get languageTitle => 'Language (English / العربية)';

  @override
  String get marketplaceTitle => 'My Marketplace Store';

  @override
  String get marketplaceSubtitle => 'Manage SME / home seller shop';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchFieldHint => 'Search warehouses, e.g. Al Quoz';

  @override
  String get emirateLabel => 'Emirate';

  @override
  String get minShelvesLabel => 'Min Shelves';

  @override
  String get resultsLabel => 'Results';

  @override
  String shelvesAvailable(Object count) {
    return '$count Shelves Available';
  }

  @override
  String pricePerShelf(Object price) {
    return 'AED $price/Shelf';
  }

  @override
  String get access247 => '24/7 Access';

  @override
  String get businessHours => 'Business Hours';

  @override
  String get getInstantQuote => 'Get Instant Quote';

  @override
  String emirateAndShelves(Object count, Object emirate) {
    return '$emirate • $count Shelves';
  }

  @override
  String get selectWarehouseTitle => 'Select a warehouse';

  @override
  String get noWarehousesAvailable => 'No warehouses available.';

  @override
  String get chooseWarehouseHint => 'Choose a warehouse';

  @override
  String get openButton => 'Open';

  @override
  String get navHome => 'Home';

  @override
  String get navStore => 'Store';

  @override
  String get navSearch => 'Search';

  @override
  String get navPayments => 'Payments';

  @override
  String get navProfile => 'Profile';

  @override
  String get orDivider => 'OR';

  @override
  String get paymentsTitle => 'Payments';

  @override
  String get filterByStatus => 'Filter by status';

  @override
  String get noInvoicesTitle => 'No invoices yet';

  @override
  String get noInvoicesSubtitle =>
      'Your booking invoices and VAT receipts will appear here.';

  @override
  String get choosePaymentMethod => 'Choose payment method';

  @override
  String get payByCard => 'Pay by Card';

  @override
  String get payByCardSubtitle => 'Visa / Mastercard / AMEX';

  @override
  String get applePay => 'Apple Pay';

  @override
  String get applePaySubtitle => 'Fast checkout with Apple Wallet';

  @override
  String get applePayNotAvailable => 'Available on iOS';

  @override
  String get processingPayment => 'Processing card payment…';

  @override
  String get paymentSuccessful => 'Payment successful. Thank you!';

  @override
  String get paymentFailed => 'Something went wrong.';

  @override
  String get viewReceipt => 'View Receipt';

  @override
  String get payNow => 'Pay Now';

  @override
  String invoiceTitle(Object number) {
    return 'Invoice $number';
  }

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get vatLabel => 'VAT (5%)';

  @override
  String get totalLabel => 'Total';

  @override
  String get paidTag => 'Paid';

  @override
  String get pendingTag => 'Pending';

  @override
  String get deliveryRequestTitle => 'Delivery Request';

  @override
  String get deliveryRequestSubtitle =>
      'Fill in the details below to arrange your delivery.';

  @override
  String get shippingOptionsTitle => 'Shipping Options';

  @override
  String get shippingCompanyLabel => 'Shipping Company';

  @override
  String get deliveryTypeLabel => 'Delivery Type';

  @override
  String get deliveryModeLabel => 'Delivery Mode';

  @override
  String get domesticLabel => 'Domestic';

  @override
  String get internationalLabel => 'International';

  @override
  String get deliveryLocationTitle => 'Delivery Location';

  @override
  String get cityEmirateLabel => 'City (Emirate)';

  @override
  String get countryLabel => 'Country';

  @override
  String get cityLabel => 'City';

  @override
  String get recipientDetailsTitle => 'Recipient Details';

  @override
  String get recipientNameLabel => 'Recipient Name';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get fullAddressLabel => 'Full Address';

  @override
  String get notesLabel => 'Notes';

  @override
  String get submitRequestButton => 'Submit Delivery Request';

  @override
  String requestSubmittedMessage(Object location) {
    return 'Delivery request submitted for $location';
  }

  @override
  String get requestFailedMessage => 'Failed to submit request';

  @override
  String get selectShippingCompanyError => 'Please select a shipping company';

  @override
  String get selectCityError => 'Please select a city (emirate)';

  @override
  String get selectCountryCityError => 'Please select country and city';

  @override
  String get enterRecipientNameError => 'Enter recipient name';

  @override
  String get enterPhoneNumberError => 'Enter phone number';

  @override
  String get enterAddressError => 'Enter full address';

  @override
  String get myStoreTitle => 'My Store';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardSubtitle => 'Manage your inventory and orders.';

  @override
  String get shelvesStat => 'Shelves';

  @override
  String get shelvesSubtitle => '100 AED/mo each';

  @override
  String get itemsStat => 'Items';

  @override
  String get inStockSubtitle => 'In Stock';

  @override
  String get pendingOrdersStat => 'Pending Orders';

  @override
  String get requiresActionSubtitle => 'Requires Action';

  @override
  String get quickActionsTitle => 'Quick Actions';

  @override
  String get bookDropoffAction => 'Book Drop-off';

  @override
  String get myInventoryAction => 'My Inventory';

  @override
  String get productCatalogAction => 'Product Catalog';

  @override
  String get requestDeliveryAction => 'Request Delivery';

  @override
  String get myInventoryTitle => 'My Inventory';

  @override
  String get noInventory => 'No inventory items found.';

  @override
  String qtyLabel(Object count) {
    return 'Qty: $count';
  }

  @override
  String shelfLabel(Object id) {
    return 'Shelf: $id';
  }

  @override
  String statusLabel(Object status) {
    return 'Status: $status';
  }

  @override
  String get itemInStock => 'In Stock';

  @override
  String get itemOutOfStock => 'Out of Stock';

  @override
  String get unknownProduct => 'Unknown Product';

  @override
  String get productCatalogTitle => 'Product Catalog';

  @override
  String get noProductsFound => 'No products found. Add your first item!';

  @override
  String productPrice(Object price) {
    return '$price AED';
  }

  @override
  String get addProductTitle => 'Add Product';

  @override
  String get productNameLabel => 'Product Name';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get priceLabel => 'Price (AED)';

  @override
  String get saveProductButton => 'Save Product';

  @override
  String get requiredError => 'Required';

  @override
  String get invalidNumberError => 'Invalid number';

  @override
  String get bookDropoffTitle => 'Book Drop-off';

  @override
  String get expectedDateLabel => 'Expected Date';

  @override
  String get approxItemCountLabel => 'Approx. Item Count';

  @override
  String get notesFragileLabel => 'Notes (e.g. Fragile items)';

  @override
  String get submitDropoffButton => 'Book Drop-off';

  @override
  String get dropoffSubmittedMessage => 'Drop-off request submitted!';

  @override
  String get mpRequestDeliveryTitle => 'Request Delivery';

  @override
  String get customerNameLabel => 'Customer Name';

  @override
  String get deliveryAddressLabel => 'Delivery Address';

  @override
  String get methodLabel => 'Method';

  @override
  String get standardDeliveryOption => 'Standard Delivery';

  @override
  String get customerPickupOption => 'Customer Pickup';

  @override
  String get mpSubmitRequestButton => 'Submit Request';

  @override
  String get deliveryRequestSubmitted => 'Delivery request submitted!';

  @override
  String get warehouseProductLabel => 'Warehouse / Product';

  @override
  String get dateLabel => 'Date';

  @override
  String get closeButton => 'Close';

  @override
  String get receiveGoodsTitle => 'Receive Goods – Drop-off';

  @override
  String get processInfo =>
      'Process: Schedule → Prepare bay & workers → Receive & inspect → Update system.';

  @override
  String get scheduleStep => 'Schedule';

  @override
  String get preparationStep => 'Preparation';

  @override
  String get updateStep => 'Update';

  @override
  String get scheduleDropoffTitle => 'Schedule Drop-off';

  @override
  String get scheduleDropoffSubtitle =>
      'Drop-off only: book a time for the seller to bring goods to the warehouse.';

  @override
  String scheduleDropoffSubtitleScheduled(Object date) {
    return 'Scheduled: $date';
  }

  @override
  String get nowPlus2h => 'Now +2h';

  @override
  String get tomorrow10am => 'Tomorrow 10:00';

  @override
  String get nextMon10am => 'Next Mon 10:00';

  @override
  String get chooseDateTime => 'Choose date & time';

  @override
  String get prepareBayTitle => 'Prepare bay & workers';

  @override
  String get prepareBaySubtitle =>
      'Assign a bay for the shelves and choose the number of workers for receiving.';

  @override
  String prepareBaySubtitlePrepared(Object bay, Object storageMode) {
    return '$storageMode • Bay $bay';
  }

  @override
  String get storageModelLabel => 'Storage model';

  @override
  String get storageModelValue => 'Home seller shelves (per approved quote)';

  @override
  String get assignBayLabel => 'Assign bay';

  @override
  String bayLabel(Object bay) {
    return 'Bay $bay';
  }

  @override
  String get workersRequiredLabel => 'Workers required (50 AED each)';

  @override
  String labourCostEst(Object cost) {
    return 'Receiving is based on count. Estimated labour cost: AED $cost';
  }

  @override
  String get preparedButton => 'Prepared';

  @override
  String get confirmPreparationButton => 'Confirm preparation';

  @override
  String get inspectionPhotosTitle => 'Inspection & photos';

  @override
  String get inspectionPhotosSubtitle =>
      'Drop-off only. Receiving is based on count. If damaged items are found, warehouse admin can document them with photos. Listing photos are a separate value-added service.';

  @override
  String get adminDocumentPhotos =>
      'Admin to document damaged items with photos';

  @override
  String get adminDocumentPhotosSubtitle =>
      'Used only if damages are found during receiving';

  @override
  String get listingPhotosService =>
      'Photos for online listing (value-added service)';

  @override
  String get listingPhotosSubtitle =>
      'Optimised product photos for marketplace / SMEs / home sellers';

  @override
  String get notesAdminLabel => 'Notes for warehouse admin (optional)';

  @override
  String get instantUpdateTitle => 'Instant Update';

  @override
  String get instantUpdateSubtitle =>
      'Push storage No. and stock status to seller dashboard / marketplace.';

  @override
  String instantUpdateSubtitleUpdated(Object status, Object storageNo) {
    return 'Storage #: $storageNo • Status: $status';
  }

  @override
  String get updateNowButton => 'Update now';

  @override
  String get updatedButton => 'Updated';

  @override
  String get copyStorageNo => 'Copy storage #';

  @override
  String get stockStatusReceived => 'Received & Stored';

  @override
  String get stockStatusPending => 'Pending';

  @override
  String get lastInboundTitle => 'Last inbound from receiving';

  @override
  String get smartStorageNo => 'Storage #';

  @override
  String get smartBay => 'Bay';

  @override
  String get smartScheduledAt => 'Scheduled at';

  @override
  String get smartStorageModel => 'Storage model';

  @override
  String get smartWorkers => 'Workers';

  @override
  String get damagePhotosByAdminLabel => 'Damage photos by admin';

  @override
  String get yesLabel => 'Yes';

  @override
  String get noLabel => 'No';

  @override
  String get listingPhotosServiceLabel => 'Listing photos service';

  @override
  String get inStockSmart => 'In Stock';

  @override
  String get lowStockSmart => 'Low Stock';

  @override
  String get outOfStockSmart => 'Out of Stock';

  @override
  String get warehouseStockOverview => 'Warehouse Stock Overview';

  @override
  String get noChartData => 'No chart data';

  @override
  String get visualAnalyticsText =>
      'Visual analytics of quantities by category. Auto-updates on refresh.';

  @override
  String get requestDeliveryBtn => 'Request Delivery';

  @override
  String get restockBtn => 'Restock';

  @override
  String get viewReportsBtn => 'View Reports';

  @override
  String get restockCreated => 'Restock created';

  @override
  String get restockFailed => 'Restock failed';

  @override
  String get openingReports => 'Opening reports…';

  @override
  String get noReportsAvailable => 'No reports available';

  @override
  String get instantQuoteTitle => 'Instant Quote';

  @override
  String get instantQuoteMultiTitle => 'Instant Quote (Multiple Warehouses)';

  @override
  String get numberOfShelvesHelper => 'Number of shelves';

  @override
  String get rateLabel => 'Rate';

  @override
  String get perShelfSuffix => '/ shelf';

  @override
  String get shelvesForWarehouseLabel => 'Shelves for this warehouse';

  @override
  String get shelvesForSiteHelper => 'Number of shelves for this site';

  @override
  String get grandSubtotal => 'Grand Subtotal';

  @override
  String get grandPlatformFee => 'Grand Platform fee';

  @override
  String get grandVat => 'Grand VAT';

  @override
  String get totalThisWarehouse => 'Total (this warehouse)';

  @override
  String get calculateButton => 'Calculate';

  @override
  String get totalAedLabel => 'Total (AED)';

  @override
  String get estimatedTotalTitle => 'Estimated Total (per month)';

  @override
  String platformFeeRateLabel(Object rate) {
    return 'Platform fee ($rate%)';
  }

  @override
  String vatRateLabel(Object rate) {
    return 'VAT $rate%';
  }

  @override
  String get closeTooltip => 'Close';

  @override
  String get receiptPageTitle => 'Receipt';

  @override
  String get taxInvoiceLabel => 'Tax Invoice';

  @override
  String get trnLabel => 'TRN';

  @override
  String get vendorName => 'NXN Logistics LLC';

  @override
  String get vendorAddress => 'Abu Dhabi, UAE';

  @override
  String get billToLabel => 'Bill To';

  @override
  String get paymentMethodLabel => 'Payment Method';

  @override
  String get transactionIdLabel => 'Transaction ID';

  @override
  String get itemDescription => 'Description';

  @override
  String get amountLabel => 'Amount';

  @override
  String get totalPaid => 'Total Paid';

  @override
  String get notificationSettingsTitle => 'Notification Settings';

  @override
  String get pushNotificationsLabel => 'Push Notifications';

  @override
  String get emailNotificationsLabel => 'Email Notifications';

  @override
  String get smsNotificationsLabel => 'SMS Notifications';

  @override
  String get marketingUpdatesLabel => 'Marketing Updates';

  @override
  String get kycPageTitle => 'KYC Verification';

  @override
  String get uploadIdLabel => 'Upload Emirates ID';

  @override
  String get uploadTradeLicenseLabel => 'Upload Trade License';

  @override
  String get sellerSettingsTitle => 'Store Settings';

  @override
  String get autoAcceptOrdersLabel => 'Auto-accept Orders';

  @override
  String get vacationModeLabel => 'Vacation Mode';

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get uploadPhotoLabel => 'Tap to upload photo';

  @override
  String get smartWarehouse => 'Smart Warehouse';

  @override
  String get gatePassTitle => 'Gate Pass';

  @override
  String get gatePassSubtitle =>
      'Show this QR code at the warehouse gate for entry.';

  @override
  String get scanForEntry => 'Scan for Entry';

  @override
  String get bookingRef => 'Booking Ref';

  @override
  String get warehouseLocation => 'Warehouse Location';

  @override
  String get getDirections => 'Get Directions';

  @override
  String get trackingTitle => 'Shipment Tracking';

  @override
  String get trackingNumber => 'Tracking Number';

  @override
  String get estimatedDelivery => 'Est. Delivery';

  @override
  String get statusInTransit => 'In Transit';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusPending => 'Pending';

  @override
  String get trackShipment => 'Track Shipment';

  @override
  String get totalShelves => 'Total Shelves';

  @override
  String get stockValue => 'Stock Value';

  @override
  String lowStockCount(Object count) {
    return 'Low Stock: $count';
  }

  @override
  String outOfStockCount(Object count) {
    return 'Out of Stock: $count';
  }

  @override
  String get activeRentals => 'Active Rentals';

  @override
  String get managingLabel => 'Managing';

  @override
  String get bookSpace => 'Book Space';

  @override
  String get findNewShelves => 'Find new shelves';

  @override
  String get shipToCustomers => 'Ship to customers';

  @override
  String get manageStock => 'Manage stock';

  @override
  String get viewInvoices => 'View invoices';

  @override
  String get warehousePrep => 'Warehouse Preparation';

  @override
  String get scheduleDropoffShort => 'Schedule drop-off';

  @override
  String get recentActivity => 'Recent Activity';
}
