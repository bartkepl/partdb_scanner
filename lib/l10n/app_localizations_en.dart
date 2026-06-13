// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navSearch => 'Search';

  @override
  String get navIpnGenerator => 'IPN Generator';

  @override
  String get navCategories => 'Categories';

  @override
  String get navReview => 'Review';

  @override
  String get navConfig => 'Configuration';

  @override
  String lowStockBanner(int count) {
    return '$count part(s) have low stock';
  }

  @override
  String get show => 'Show';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get refresh => 'Refresh';

  @override
  String get search => 'Search';

  @override
  String get scan => 'Scan';

  @override
  String get print => 'Print';

  @override
  String get connect => 'Connect';

  @override
  String get more => 'More...';

  @override
  String get reset => 'Reset';

  @override
  String get assign => 'Assign';

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get commentOptional => 'Comment (optional)';

  @override
  String get commentHint => 'e.g. TME delivery, usage for project...';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get confirmAndSave => 'Confirm & save';

  @override
  String get tryAgain => 'Try again';

  @override
  String get none => '— none —';

  @override
  String get filterAll => 'All';

  @override
  String get location => 'Location';

  @override
  String get quantity => 'Quantity';

  @override
  String get configTitle => 'Part-DB Configuration';

  @override
  String get configBaseUrlHint => 'Base URL (e.g. http://192.168.1.10:8000)';

  @override
  String get configScanToken => 'Scan token';

  @override
  String get configSaveAndVerify => 'Save & verify token';

  @override
  String configTokenOk(String user) {
    return '✅ Token OK (user: $user)';
  }

  @override
  String configTokenSavedButFailed(String error) {
    return '⚠️ Token saved, but verification failed: $error';
  }

  @override
  String get configZoomLevel => 'Zoom level';

  @override
  String get configPrinters => 'Printers';

  @override
  String get configSunmiTitle => 'Sunmi Printer';

  @override
  String get configSunmiSubtitle => 'Print receipts/labels via Sunmi';

  @override
  String get configNiimbotTitle => 'Niimbot Printer';

  @override
  String get configNiimbotSubtitle => 'Print labels via Niimbot Bluetooth';

  @override
  String configAppVersion(String version) {
    return 'App version v$version';
  }

  @override
  String get configLanguage => 'Language';

  @override
  String get searchTitle => 'Search part';

  @override
  String get searchHint => 'Enter IPN, name, parameter...';

  @override
  String get searching => '🔎 Searching...';

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String searchFound(int count) {
    return 'Found: $count';
  }

  @override
  String get searchOnlyLowStock => 'Low stock only';

  @override
  String get searchSortFilter => 'Sort / filter';

  @override
  String get searchExportCsv => 'Export CSV';

  @override
  String searchExportError(String error) {
    return 'Export error: $error';
  }

  @override
  String get searchInventory => 'Stock taking';

  @override
  String get searchOrScan => 'Search or scan a part';

  @override
  String get recentlyViewed => 'Recently viewed';

  @override
  String get sortSectionTitle => 'Sorting';

  @override
  String get sortNone => 'None';

  @override
  String get sortNameAsc => 'Name A-Z';

  @override
  String get sortNameDesc => 'Name Z-A';

  @override
  String get sortStockAsc => 'Stock ↑';

  @override
  String get sortStockDesc => 'Stock ↓';

  @override
  String get categoryLabel => 'Category';

  @override
  String get resetFilters => 'Reset filters';

  @override
  String get noLowStockParts => 'No low stock parts';

  @override
  String savedQty(String name, int qty) {
    return '✅ $name: $qty pcs.';
  }

  @override
  String errorGeneric(String error) {
    return '❌ Error: $error';
  }

  @override
  String get addPhoto => 'Add photo';

  @override
  String get cameraSource => 'Camera';

  @override
  String get gallerySource => 'Gallery';

  @override
  String get photoAdded => 'Photo added to PartDB';

  @override
  String uploadError(String error) {
    return 'Upload error: $error';
  }

  @override
  String get dataRefreshed => 'Data refreshed';

  @override
  String refreshError(String error) {
    return 'Refresh error: $error';
  }

  @override
  String get fetchParamsError => 'Could not fetch parameters';

  @override
  String savedLot(String location, int qty) {
    return 'Saved: $location = $qty';
  }

  @override
  String get printSunmi => 'Print (Sunmi)';

  @override
  String get niimbotLabels => 'Niimbot Labels';

  @override
  String get printed => 'Printed';

  @override
  String printError(String error) {
    return 'Print error: $error';
  }

  @override
  String categoryText(String category) {
    return 'Category: $category';
  }

  @override
  String manufacturerText(String manufacturer) {
    return 'Manufacturer: $manufacturer';
  }

  @override
  String tagsText(String tags) {
    return 'Tags: $tags';
  }

  @override
  String noteText(String note) {
    return 'Note: $note';
  }

  @override
  String get parametersLabel => 'Parameters:';

  @override
  String paramUpdated(String name) {
    return 'Updated: $name';
  }

  @override
  String saveError(String error) {
    return 'Save error: $error';
  }

  @override
  String labelsFor(String name) {
    return 'Labels: $name';
  }

  @override
  String get labelTypeSection => 'Label type';

  @override
  String get labelDrawer => 'Drawer 22×14mm';

  @override
  String get labelDrawerSub => 'Name + DataMatrix';

  @override
  String get labelSpoolParam => 'Spool – params 12×40mm';

  @override
  String get labelSpoolParamSub => 'Text + DataMatrix';

  @override
  String get labelSpoolBarcode => 'Spool – barcode 12×40mm';

  @override
  String get labelSpoolBarcodeSub => 'Code128 barcode';

  @override
  String get drawerLabelConfig => 'Drawer label configuration';

  @override
  String get nameFontSize => 'Name text size:';

  @override
  String get spoolLabelParams => 'Parameters on spool label';

  @override
  String get connecting => 'Connecting to printer...';

  @override
  String get connected => '✅ Connected';

  @override
  String connectionError(String error) {
    return '❌ Connection error: $error';
  }

  @override
  String get disconnected => 'Disconnected';

  @override
  String get selectLabelTypeWarning => '⚠️ Select at least one label type';

  @override
  String get printing => 'Printing...';

  @override
  String get printingDrawerLabel => 'Printing drawer label...';

  @override
  String get printingSpoolLabels => 'Printing spool labels...';

  @override
  String get printingParamLabel => 'Printing parameter label...';

  @override
  String get printingBarcodeLabel => 'Printing barcode label...';

  @override
  String get printDone => '✅ Printed';

  @override
  String get disconnectPrinter => 'Disconnect printer';

  @override
  String get connectPrinter => 'Connect to printer';

  @override
  String get stockTakingTitle => 'Stock taking';

  @override
  String get saveCorrectionsTooltip => 'Save corrections';

  @override
  String get scanNextPart => 'Scan next part';

  @override
  String get scanIpnOrName => 'Scan IPN or part name';

  @override
  String notFound(String raw) {
    return 'Not found: $raw';
  }

  @override
  String noStorageLocations(String name) {
    return '$name: no storage locations';
  }

  @override
  String alreadyOnList(String name, String location) {
    return '$name already on list ($location)';
  }

  @override
  String get noDiscrepancies => 'No discrepancies to save';

  @override
  String get saveCorrectionsTitle => 'Save corrections?';

  @override
  String willUpdatePositions(int count) {
    return 'Will update $count item(s).';
  }

  @override
  String savedWithErrors(int ok, int fail) {
    return 'Saved: $ok, errors: $fail';
  }

  @override
  String chooseLocation(String name) {
    return 'Choose location: $name';
  }

  @override
  String stockAmount(int amount) {
    return 'Stock: $amount';
  }

  @override
  String reviewTitle(int count) {
    return 'Review ($count)';
  }

  @override
  String get reviewTitleEmpty => 'Parts review';

  @override
  String get noPartsToReview => 'No parts to review';

  @override
  String get noPartsWithoutIpnSelected => 'No selected parts without IPN';

  @override
  String generatedIpnCount(int count) {
    return 'Generated IPN for $count parts';
  }

  @override
  String generateIpnError(String error) {
    return 'IPN generation error: $error';
  }

  @override
  String get selectParts => 'Select parts';

  @override
  String get assignLocationTitle => 'Assign location';

  @override
  String get noReadyParts => 'No ready parts (IPN + location required)';

  @override
  String confirmErrors(String errors) {
    return 'Errors: $errors';
  }

  @override
  String confirmedPartsCount(int count) {
    return 'Confirmed $count parts';
  }

  @override
  String get selectLabelType => 'Select label type';

  @override
  String printedLabelsCount(int count) {
    return 'Printed $count labels';
  }

  @override
  String get drawerLabel => 'Drawer';

  @override
  String get spoolLabel => 'Spool';

  @override
  String get generateIpnBtn => 'Generate IPN';

  @override
  String get locationLabel => 'Location';

  @override
  String get chooseDots => 'Choose…';

  @override
  String confirmedBanner(int count) {
    return 'Confirmed: $count parts';
  }

  @override
  String get printerConnected => 'Connected';

  @override
  String get noPrinter => 'No printer';

  @override
  String printLabelsCount(int count) {
    return 'Print $count labels';
  }

  @override
  String confirmReady(int count) {
    return 'Confirm ($count)';
  }

  @override
  String get confirmSelected => 'Confirm selected';

  @override
  String get ipnGeneratorTitle => 'IPN Generator';

  @override
  String get allPartsHaveIpn => 'All parts already have IPN.';

  @override
  String get noPartsWithoutIpn => 'No parts without IPN';

  @override
  String partsWithoutIpnCount(int count, int selected) {
    return 'Parts without IPN: $count  •  Selected: $selected';
  }

  @override
  String get refreshListTooltip => 'Refresh list';

  @override
  String get confirmIpnGenTitle => 'Confirm IPN generation';

  @override
  String get selectPartsToGenerate => 'Select parts to generate IPN';

  @override
  String generateIpnForCount(int count) {
    return 'Generate IPN for $count parts';
  }

  @override
  String savedIpnCount(int saved, int total) {
    return '✅ Saved IPN: $saved/$total';
  }

  @override
  String fetchError(String error) {
    return '❌ Fetch error: $error';
  }

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get noCategories => 'No categories';

  @override
  String get noPartsInCategory => 'No parts in this category';

  @override
  String errorText(String error) {
    return 'Error: $error';
  }

  @override
  String get scanTitle => 'Scan code';

  @override
  String get selectCodeType => 'Select code type';

  @override
  String scanMode(String mode) {
    return 'Mode: $mode';
  }
}
