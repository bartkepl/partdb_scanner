import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

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
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navIpnGenerator.
  ///
  /// In en, this message translates to:
  /// **'IPN Generator'**
  String get navIpnGenerator;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// No description provided for @navConfig.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get navConfig;

  /// No description provided for @lowStockBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} part(s) have low stock'**
  String lowStockBanner(int count);

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More...'**
  String get more;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @commentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentOptional;

  /// No description provided for @commentHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. TME delivery, usage for project...'**
  String get commentHint;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @confirmAndSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm & save'**
  String get confirmAndSave;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'— none —'**
  String get none;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @configTitle.
  ///
  /// In en, this message translates to:
  /// **'Part-DB Configuration'**
  String get configTitle;

  /// No description provided for @configBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Base URL (e.g. http://192.168.1.10:8000)'**
  String get configBaseUrlHint;

  /// No description provided for @configScanToken.
  ///
  /// In en, this message translates to:
  /// **'Scan token'**
  String get configScanToken;

  /// No description provided for @configSaveAndVerify.
  ///
  /// In en, this message translates to:
  /// **'Save & verify token'**
  String get configSaveAndVerify;

  /// No description provided for @configTokenOk.
  ///
  /// In en, this message translates to:
  /// **'✅ Token OK (user: {user})'**
  String configTokenOk(String user);

  /// No description provided for @configTokenSavedButFailed.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Token saved, but verification failed: {error}'**
  String configTokenSavedButFailed(String error);

  /// No description provided for @configZoomLevel.
  ///
  /// In en, this message translates to:
  /// **'Zoom level'**
  String get configZoomLevel;

  /// No description provided for @configPrinters.
  ///
  /// In en, this message translates to:
  /// **'Printers'**
  String get configPrinters;

  /// No description provided for @configSunmiTitle.
  ///
  /// In en, this message translates to:
  /// **'Sunmi Printer'**
  String get configSunmiTitle;

  /// No description provided for @configSunmiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print receipts/labels via Sunmi'**
  String get configSunmiSubtitle;

  /// No description provided for @configNiimbotTitle.
  ///
  /// In en, this message translates to:
  /// **'Niimbot Printer'**
  String get configNiimbotTitle;

  /// No description provided for @configNiimbotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Print labels via Niimbot Bluetooth'**
  String get configNiimbotSubtitle;

  /// No description provided for @configAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version v{version}'**
  String configAppVersion(String version);

  /// No description provided for @configLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get configLanguage;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search part'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Enter IPN, name, parameter...'**
  String get searchHint;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'🔎 Searching...'**
  String get searching;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResults(String query);

  /// No description provided for @searchFound.
  ///
  /// In en, this message translates to:
  /// **'Found: {count}'**
  String searchFound(int count);

  /// No description provided for @searchOnlyLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock only'**
  String get searchOnlyLowStock;

  /// No description provided for @searchSortFilter.
  ///
  /// In en, this message translates to:
  /// **'Sort / filter'**
  String get searchSortFilter;

  /// No description provided for @searchExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get searchExportCsv;

  /// No description provided for @searchExportError.
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String searchExportError(String error);

  /// No description provided for @searchInventory.
  ///
  /// In en, this message translates to:
  /// **'Stock taking'**
  String get searchInventory;

  /// No description provided for @searchOrScan.
  ///
  /// In en, this message translates to:
  /// **'Search or scan a part'**
  String get searchOrScan;

  /// No description provided for @recentlyViewed.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get recentlyViewed;

  /// No description provided for @sortSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sorting'**
  String get sortSectionTitle;

  /// No description provided for @sortNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get sortNone;

  /// No description provided for @sortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name A-Z'**
  String get sortNameAsc;

  /// No description provided for @sortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name Z-A'**
  String get sortNameDesc;

  /// No description provided for @sortStockAsc.
  ///
  /// In en, this message translates to:
  /// **'Stock ↑'**
  String get sortStockAsc;

  /// No description provided for @sortStockDesc.
  ///
  /// In en, this message translates to:
  /// **'Stock ↓'**
  String get sortStockDesc;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get resetFilters;

  /// No description provided for @noLowStockParts.
  ///
  /// In en, this message translates to:
  /// **'No low stock parts'**
  String get noLowStockParts;

  /// No description provided for @savedQty.
  ///
  /// In en, this message translates to:
  /// **'✅ {name}: {qty} pcs.'**
  String savedQty(String name, int qty);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String errorGeneric(String error);

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @cameraSource.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraSource;

  /// No description provided for @gallerySource.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallerySource;

  /// No description provided for @photoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added to PartDB'**
  String get photoAdded;

  /// No description provided for @uploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload error: {error}'**
  String uploadError(String error);

  /// No description provided for @dataRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Data refreshed'**
  String get dataRefreshed;

  /// No description provided for @refreshError.
  ///
  /// In en, this message translates to:
  /// **'Refresh error: {error}'**
  String refreshError(String error);

  /// No description provided for @fetchParamsError.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch parameters'**
  String get fetchParamsError;

  /// No description provided for @savedLot.
  ///
  /// In en, this message translates to:
  /// **'Saved: {location} = {qty}'**
  String savedLot(String location, int qty);

  /// No description provided for @printSunmi.
  ///
  /// In en, this message translates to:
  /// **'Print (Sunmi)'**
  String get printSunmi;

  /// No description provided for @niimbotLabels.
  ///
  /// In en, this message translates to:
  /// **'Niimbot Labels'**
  String get niimbotLabels;

  /// No description provided for @printed.
  ///
  /// In en, this message translates to:
  /// **'Printed'**
  String get printed;

  /// No description provided for @printError.
  ///
  /// In en, this message translates to:
  /// **'Print error: {error}'**
  String printError(String error);

  /// No description provided for @categoryText.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String categoryText(String category);

  /// No description provided for @manufacturerText.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer: {manufacturer}'**
  String manufacturerText(String manufacturer);

  /// No description provided for @tagsText.
  ///
  /// In en, this message translates to:
  /// **'Tags: {tags}'**
  String tagsText(String tags);

  /// No description provided for @noteText.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String noteText(String note);

  /// No description provided for @parametersLabel.
  ///
  /// In en, this message translates to:
  /// **'Parameters:'**
  String get parametersLabel;

  /// No description provided for @paramUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated: {name}'**
  String paramUpdated(String name);

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Save error: {error}'**
  String saveError(String error);

  /// No description provided for @labelsFor.
  ///
  /// In en, this message translates to:
  /// **'Labels: {name}'**
  String labelsFor(String name);

  /// No description provided for @labelTypeSection.
  ///
  /// In en, this message translates to:
  /// **'Label type'**
  String get labelTypeSection;

  /// No description provided for @labelDrawer.
  ///
  /// In en, this message translates to:
  /// **'Drawer 22×14mm'**
  String get labelDrawer;

  /// No description provided for @labelDrawerSub.
  ///
  /// In en, this message translates to:
  /// **'Name + DataMatrix'**
  String get labelDrawerSub;

  /// No description provided for @labelSpoolParam.
  ///
  /// In en, this message translates to:
  /// **'Spool – params 12×40mm'**
  String get labelSpoolParam;

  /// No description provided for @labelSpoolParamSub.
  ///
  /// In en, this message translates to:
  /// **'Text + DataMatrix'**
  String get labelSpoolParamSub;

  /// No description provided for @labelSpoolBarcode.
  ///
  /// In en, this message translates to:
  /// **'Spool – barcode 12×40mm'**
  String get labelSpoolBarcode;

  /// No description provided for @labelSpoolBarcodeSub.
  ///
  /// In en, this message translates to:
  /// **'Code128 barcode'**
  String get labelSpoolBarcodeSub;

  /// No description provided for @drawerLabelConfig.
  ///
  /// In en, this message translates to:
  /// **'Drawer label configuration'**
  String get drawerLabelConfig;

  /// No description provided for @nameFontSize.
  ///
  /// In en, this message translates to:
  /// **'Name text size:'**
  String get nameFontSize;

  /// No description provided for @spoolLabelParams.
  ///
  /// In en, this message translates to:
  /// **'Parameters on spool label'**
  String get spoolLabelParams;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to printer...'**
  String get connecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'✅ Connected'**
  String get connected;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'❌ Connection error: {error}'**
  String connectionError(String error);

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @selectLabelTypeWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Select at least one label type'**
  String get selectLabelTypeWarning;

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printing...'**
  String get printing;

  /// No description provided for @printingDrawerLabel.
  ///
  /// In en, this message translates to:
  /// **'Printing drawer label...'**
  String get printingDrawerLabel;

  /// No description provided for @printingSpoolLabels.
  ///
  /// In en, this message translates to:
  /// **'Printing spool labels...'**
  String get printingSpoolLabels;

  /// No description provided for @printingParamLabel.
  ///
  /// In en, this message translates to:
  /// **'Printing parameter label...'**
  String get printingParamLabel;

  /// No description provided for @printingBarcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Printing barcode label...'**
  String get printingBarcodeLabel;

  /// No description provided for @printDone.
  ///
  /// In en, this message translates to:
  /// **'✅ Printed'**
  String get printDone;

  /// No description provided for @disconnectPrinter.
  ///
  /// In en, this message translates to:
  /// **'Disconnect printer'**
  String get disconnectPrinter;

  /// No description provided for @connectPrinter.
  ///
  /// In en, this message translates to:
  /// **'Connect to printer'**
  String get connectPrinter;

  /// No description provided for @stockTakingTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock taking'**
  String get stockTakingTitle;

  /// No description provided for @saveCorrectionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save corrections'**
  String get saveCorrectionsTooltip;

  /// No description provided for @scanNextPart.
  ///
  /// In en, this message translates to:
  /// **'Scan next part'**
  String get scanNextPart;

  /// No description provided for @scanIpnOrName.
  ///
  /// In en, this message translates to:
  /// **'Scan IPN or part name'**
  String get scanIpnOrName;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found: {raw}'**
  String notFound(String raw);

  /// No description provided for @noStorageLocations.
  ///
  /// In en, this message translates to:
  /// **'{name}: no storage locations'**
  String noStorageLocations(String name);

  /// No description provided for @alreadyOnList.
  ///
  /// In en, this message translates to:
  /// **'{name} already on list ({location})'**
  String alreadyOnList(String name, String location);

  /// No description provided for @noDiscrepancies.
  ///
  /// In en, this message translates to:
  /// **'No discrepancies to save'**
  String get noDiscrepancies;

  /// No description provided for @saveCorrectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Save corrections?'**
  String get saveCorrectionsTitle;

  /// No description provided for @willUpdatePositions.
  ///
  /// In en, this message translates to:
  /// **'Will update {count} item(s).'**
  String willUpdatePositions(int count);

  /// No description provided for @savedWithErrors.
  ///
  /// In en, this message translates to:
  /// **'Saved: {ok}, errors: {fail}'**
  String savedWithErrors(int ok, int fail);

  /// No description provided for @chooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose location: {name}'**
  String chooseLocation(String name);

  /// No description provided for @stockAmount.
  ///
  /// In en, this message translates to:
  /// **'Stock: {amount}'**
  String stockAmount(int amount);

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review ({count})'**
  String reviewTitle(int count);

  /// No description provided for @reviewTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Parts review'**
  String get reviewTitleEmpty;

  /// No description provided for @noPartsToReview.
  ///
  /// In en, this message translates to:
  /// **'No parts to review'**
  String get noPartsToReview;

  /// No description provided for @noPartsWithoutIpnSelected.
  ///
  /// In en, this message translates to:
  /// **'No selected parts without IPN'**
  String get noPartsWithoutIpnSelected;

  /// No description provided for @generatedIpnCount.
  ///
  /// In en, this message translates to:
  /// **'Generated IPN for {count} parts'**
  String generatedIpnCount(int count);

  /// No description provided for @generateIpnError.
  ///
  /// In en, this message translates to:
  /// **'IPN generation error: {error}'**
  String generateIpnError(String error);

  /// No description provided for @selectParts.
  ///
  /// In en, this message translates to:
  /// **'Select parts'**
  String get selectParts;

  /// No description provided for @assignLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign location'**
  String get assignLocationTitle;

  /// No description provided for @noReadyParts.
  ///
  /// In en, this message translates to:
  /// **'No ready parts (IPN + location required)'**
  String get noReadyParts;

  /// No description provided for @confirmErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors: {errors}'**
  String confirmErrors(String errors);

  /// No description provided for @confirmedPartsCount.
  ///
  /// In en, this message translates to:
  /// **'Confirmed {count} parts'**
  String confirmedPartsCount(int count);

  /// No description provided for @selectLabelType.
  ///
  /// In en, this message translates to:
  /// **'Select label type'**
  String get selectLabelType;

  /// No description provided for @printedLabelsCount.
  ///
  /// In en, this message translates to:
  /// **'Printed {count} labels'**
  String printedLabelsCount(int count);

  /// No description provided for @drawerLabel.
  ///
  /// In en, this message translates to:
  /// **'Drawer'**
  String get drawerLabel;

  /// No description provided for @spoolLabel.
  ///
  /// In en, this message translates to:
  /// **'Spool'**
  String get spoolLabel;

  /// No description provided for @generateIpnBtn.
  ///
  /// In en, this message translates to:
  /// **'Generate IPN'**
  String get generateIpnBtn;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @chooseDots.
  ///
  /// In en, this message translates to:
  /// **'Choose…'**
  String get chooseDots;

  /// No description provided for @confirmedBanner.
  ///
  /// In en, this message translates to:
  /// **'Confirmed: {count} parts'**
  String confirmedBanner(int count);

  /// No description provided for @printerConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get printerConnected;

  /// No description provided for @noPrinter.
  ///
  /// In en, this message translates to:
  /// **'No printer'**
  String get noPrinter;

  /// No description provided for @printLabelsCount.
  ///
  /// In en, this message translates to:
  /// **'Print {count} labels'**
  String printLabelsCount(int count);

  /// No description provided for @confirmReady.
  ///
  /// In en, this message translates to:
  /// **'Confirm ({count})'**
  String confirmReady(int count);

  /// No description provided for @confirmSelected.
  ///
  /// In en, this message translates to:
  /// **'Confirm selected'**
  String get confirmSelected;

  /// No description provided for @ipnGeneratorTitle.
  ///
  /// In en, this message translates to:
  /// **'IPN Generator'**
  String get ipnGeneratorTitle;

  /// No description provided for @allPartsHaveIpn.
  ///
  /// In en, this message translates to:
  /// **'All parts already have IPN.'**
  String get allPartsHaveIpn;

  /// No description provided for @noPartsWithoutIpn.
  ///
  /// In en, this message translates to:
  /// **'No parts without IPN'**
  String get noPartsWithoutIpn;

  /// No description provided for @partsWithoutIpnCount.
  ///
  /// In en, this message translates to:
  /// **'Parts without IPN: {count}  •  Selected: {selected}'**
  String partsWithoutIpnCount(int count, int selected);

  /// No description provided for @refreshListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh list'**
  String get refreshListTooltip;

  /// No description provided for @confirmIpnGenTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm IPN generation'**
  String get confirmIpnGenTitle;

  /// No description provided for @selectPartsToGenerate.
  ///
  /// In en, this message translates to:
  /// **'Select parts to generate IPN'**
  String get selectPartsToGenerate;

  /// No description provided for @generateIpnForCount.
  ///
  /// In en, this message translates to:
  /// **'Generate IPN for {count} parts'**
  String generateIpnForCount(int count);

  /// No description provided for @savedIpnCount.
  ///
  /// In en, this message translates to:
  /// **'✅ Saved IPN: {saved}/{total}'**
  String savedIpnCount(int saved, int total);

  /// No description provided for @fetchError.
  ///
  /// In en, this message translates to:
  /// **'❌ Fetch error: {error}'**
  String fetchError(String error);

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get noCategories;

  /// No description provided for @noPartsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No parts in this category'**
  String get noPartsInCategory;

  /// No description provided for @errorText.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorText(String error);

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan code'**
  String get scanTitle;

  /// No description provided for @selectCodeType.
  ///
  /// In en, this message translates to:
  /// **'Select code type'**
  String get selectCodeType;

  /// No description provided for @scanMode.
  ///
  /// In en, this message translates to:
  /// **'Mode: {mode}'**
  String scanMode(String mode);
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
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
