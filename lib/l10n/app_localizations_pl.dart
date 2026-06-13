// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get navSearch => 'Wyszukaj';

  @override
  String get navIpnGenerator => 'Generator IPN';

  @override
  String get navCategories => 'Kategorie';

  @override
  String get navReview => 'Przegląd';

  @override
  String get navConfig => 'Konfiguracja';

  @override
  String lowStockBanner(int count) {
    return '$count część/i ma niski stan magazynowy';
  }

  @override
  String get show => 'Pokaż';

  @override
  String get dismiss => 'Zamknij';

  @override
  String get cancel => 'Anuluj';

  @override
  String get save => 'Zapisz';

  @override
  String get refresh => 'Odśwież';

  @override
  String get search => 'Szukaj';

  @override
  String get scan => 'Skanuj';

  @override
  String get print => 'Drukuj';

  @override
  String get connect => 'Połącz';

  @override
  String get more => 'Więcej...';

  @override
  String get reset => 'Reset';

  @override
  String get assign => 'Przypisz';

  @override
  String get selectAll => 'Zaznacz wszystkie';

  @override
  String get deselectAll => 'Odznacz wszystkie';

  @override
  String get commentOptional => 'Komentarz (opcjonalnie)';

  @override
  String get commentHint => 'np. Dostawa TME, zużycie do projektu...';

  @override
  String get saveChanges => 'Zapisz zmiany';

  @override
  String get confirmAndSave => 'Zatwierdź i zapisz';

  @override
  String get tryAgain => 'Spróbuj ponownie';

  @override
  String get none => '— brak —';

  @override
  String get filterAll => 'Wszystkie';

  @override
  String get location => 'Lokalizacja';

  @override
  String get quantity => 'Ilość';

  @override
  String get configTitle => 'Konfiguracja Part-DB';

  @override
  String get configBaseUrlHint => 'Base URL (np. http://192.168.1.10:8000)';

  @override
  String get configScanToken => 'Skanuj token';

  @override
  String get configSaveAndVerify => 'Zapisz i sprawdź token';

  @override
  String configTokenOk(String user) {
    return '✅ Token OK (user: $user)';
  }

  @override
  String configTokenSavedButFailed(String error) {
    return '⚠️ Token zapisany, ale weryfikacja nie powiodła się: $error';
  }

  @override
  String get configZoomLevel => 'Zoom level';

  @override
  String get configPrinters => 'Drukarki';

  @override
  String get configSunmiTitle => 'Drukarka Sunmi';

  @override
  String get configSunmiSubtitle => 'Drukowanie paragonów/etykiet przez Sunmi';

  @override
  String get configNiimbotTitle => 'Drukarka Niimbot';

  @override
  String get configNiimbotSubtitle =>
      'Drukowanie etykiet przez Niimbot Bluetooth';

  @override
  String configAppVersion(String version) {
    return 'Wersja aplikacji v$version';
  }

  @override
  String get configLanguage => 'Język';

  @override
  String get searchTitle => 'Wyszukaj część';

  @override
  String get searchHint => 'Wpisz fragment IPN, nazwy, parametru...';

  @override
  String get searching => '🔎 Szukam...';

  @override
  String searchNoResults(String query) {
    return 'Brak wyników dla \"$query\"';
  }

  @override
  String searchFound(int count) {
    return 'Znaleziono: $count';
  }

  @override
  String get searchOnlyLowStock => 'Tylko niski stan';

  @override
  String get searchSortFilter => 'Sortuj / filtruj';

  @override
  String get searchExportCsv => 'Eksport CSV';

  @override
  String searchExportError(String error) {
    return 'Błąd eksportu: $error';
  }

  @override
  String get searchInventory => 'Inwentaryzacja';

  @override
  String get searchOrScan => 'Wyszukaj lub zeskanuj część';

  @override
  String get recentlyViewed => 'Ostatnio oglądane';

  @override
  String get sortSectionTitle => 'Sortowanie';

  @override
  String get sortNone => 'Brak';

  @override
  String get sortNameAsc => 'Nazwa A-Z';

  @override
  String get sortNameDesc => 'Nazwa Z-A';

  @override
  String get sortStockAsc => 'Stan ↑';

  @override
  String get sortStockDesc => 'Stan ↓';

  @override
  String get categoryLabel => 'Kategoria';

  @override
  String get resetFilters => 'Resetuj filtry';

  @override
  String get noLowStockParts => 'Brak części z niskim stanem';

  @override
  String savedQty(String name, int qty) {
    return '✅ $name: $qty szt.';
  }

  @override
  String errorGeneric(String error) {
    return '❌ Błąd: $error';
  }

  @override
  String get addPhoto => 'Dodaj zdjęcie';

  @override
  String get cameraSource => 'Aparat';

  @override
  String get gallerySource => 'Galeria';

  @override
  String get photoAdded => 'Zdjęcie dodane do PartDB';

  @override
  String uploadError(String error) {
    return 'Błąd wysyłania: $error';
  }

  @override
  String get dataRefreshed => 'Dane odświeżone';

  @override
  String refreshError(String error) {
    return 'Błąd odświeżania: $error';
  }

  @override
  String get fetchParamsError => 'Nie udało się pobrać parametrów';

  @override
  String savedLot(String location, int qty) {
    return 'Zapisano: $location = $qty';
  }

  @override
  String get printSunmi => 'Drukuj (Sunmi)';

  @override
  String get niimbotLabels => 'Etykiety Niimbot';

  @override
  String get printed => 'Wydrukowano';

  @override
  String printError(String error) {
    return 'Błąd drukowania: $error';
  }

  @override
  String categoryText(String category) {
    return 'Kategoria: $category';
  }

  @override
  String manufacturerText(String manufacturer) {
    return 'Producent: $manufacturer';
  }

  @override
  String tagsText(String tags) {
    return 'Tagi: $tags';
  }

  @override
  String noteText(String note) {
    return 'Notatka: $note';
  }

  @override
  String get parametersLabel => 'Parametry:';

  @override
  String paramUpdated(String name) {
    return 'Zaktualizowano: $name';
  }

  @override
  String saveError(String error) {
    return 'Błąd zapisu: $error';
  }

  @override
  String labelsFor(String name) {
    return 'Etykiety: $name';
  }

  @override
  String get labelTypeSection => 'Typ etykiety';

  @override
  String get labelDrawer => 'Szufladkowa 22×14mm';

  @override
  String get labelDrawerSub => 'Nazwa + DataMatrix';

  @override
  String get labelSpoolParam => 'Szpulka – parametry 12×40mm';

  @override
  String get labelSpoolParamSub => 'Tekst + DataMatrix';

  @override
  String get labelSpoolBarcode => 'Szpulka – kod 1D 12×40mm';

  @override
  String get labelSpoolBarcodeSub => 'Kod kreskowy Code128';

  @override
  String get drawerLabelConfig => 'Konfiguracja etykiety szufladkowej';

  @override
  String get nameFontSize => 'Rozmiar tekstu nazwy:';

  @override
  String get spoolLabelParams => 'Parametry na etykiecie szpulki';

  @override
  String get connecting => 'Łączenie z drukarką...';

  @override
  String get connected => '✅ Połączono';

  @override
  String connectionError(String error) {
    return '❌ Błąd połączenia: $error';
  }

  @override
  String get disconnected => 'Rozłączono';

  @override
  String get selectLabelTypeWarning =>
      '⚠️ Wybierz co najmniej jeden typ etykiety';

  @override
  String get printing => 'Drukuję...';

  @override
  String get printingDrawerLabel => 'Drukuję etykietę szufladkową...';

  @override
  String get printingSpoolLabels => 'Drukuję etykiety szpulki...';

  @override
  String get printingParamLabel => 'Drukuję etykietę parametrów...';

  @override
  String get printingBarcodeLabel => 'Drukuję etykietę z kodem 1D...';

  @override
  String get printDone => '✅ Wydrukowano';

  @override
  String get disconnectPrinter => 'Rozłącz drukarkę';

  @override
  String get connectPrinter => 'Połącz z drukarką';

  @override
  String get stockTakingTitle => 'Inwentaryzacja';

  @override
  String get saveCorrectionsTooltip => 'Zapisz korekty';

  @override
  String get scanNextPart => 'Skanuj następną część';

  @override
  String get scanIpnOrName => 'Zeskanuj IPN lub nazwę części';

  @override
  String notFound(String raw) {
    return 'Nie znaleziono: $raw';
  }

  @override
  String noStorageLocations(String name) {
    return '$name: brak lokalizacji magazynowych';
  }

  @override
  String alreadyOnList(String name, String location) {
    return '$name już na liście ($location)';
  }

  @override
  String get noDiscrepancies => 'Brak rozbieżności do zapisania';

  @override
  String get saveCorrectionsTitle => 'Zapisz korekty?';

  @override
  String willUpdatePositions(int count) {
    return 'Zostanie zaktualizowanych $count pozycji.';
  }

  @override
  String savedWithErrors(int ok, int fail) {
    return 'Zapisano: $ok, błędy: $fail';
  }

  @override
  String chooseLocation(String name) {
    return 'Wybierz lokalizację: $name';
  }

  @override
  String stockAmount(int amount) {
    return 'Stan: $amount';
  }

  @override
  String reviewTitle(int count) {
    return 'Przegląd ($count)';
  }

  @override
  String get reviewTitleEmpty => 'Przegląd części';

  @override
  String get noPartsToReview => 'Brak części do przeglądu';

  @override
  String get noPartsWithoutIpnSelected => 'Brak zaznaczonych części bez IPN';

  @override
  String generatedIpnCount(int count) {
    return 'Wygenerowano IPN dla $count części';
  }

  @override
  String generateIpnError(String error) {
    return 'Błąd generowania IPN: $error';
  }

  @override
  String get selectParts => 'Zaznacz części';

  @override
  String get assignLocationTitle => 'Przypisz lokalizację';

  @override
  String get noReadyParts =>
      'Brak gotowych części (wymagane IPN + lokalizacja)';

  @override
  String confirmErrors(String errors) {
    return 'Błędy: $errors';
  }

  @override
  String confirmedPartsCount(int count) {
    return 'Zatwierdzono $count części';
  }

  @override
  String get selectLabelType => 'Wybierz typ etykiety';

  @override
  String printedLabelsCount(int count) {
    return 'Wydrukowano $count etykiet';
  }

  @override
  String get drawerLabel => 'Szufladkowa';

  @override
  String get spoolLabel => 'Szpulkowa';

  @override
  String get generateIpnBtn => 'Generuj IPN';

  @override
  String get locationLabel => 'Lokalizacja';

  @override
  String get chooseDots => 'Wybierz…';

  @override
  String confirmedBanner(int count) {
    return 'Zatwierdzone: $count części';
  }

  @override
  String get printerConnected => 'Podłączono';

  @override
  String get noPrinter => 'Brak drukarki';

  @override
  String printLabelsCount(int count) {
    return 'Drukuj $count etykiet';
  }

  @override
  String confirmReady(int count) {
    return 'Zatwierdź ($count)';
  }

  @override
  String get confirmSelected => 'Zatwierdź zaznaczone';

  @override
  String get ipnGeneratorTitle => 'Generator IPN';

  @override
  String get allPartsHaveIpn => 'Wszystkie części mają już IPN.';

  @override
  String get noPartsWithoutIpn => 'Brak części bez IPN';

  @override
  String partsWithoutIpnCount(int count, int selected) {
    return 'Części bez IPN: $count  •  Zaznaczono: $selected';
  }

  @override
  String get refreshListTooltip => 'Odśwież listę';

  @override
  String get confirmIpnGenTitle => 'Potwierdź generowanie IPN';

  @override
  String get selectPartsToGenerate => 'Zaznacz części aby generować IPN';

  @override
  String generateIpnForCount(int count) {
    return 'Generuj IPN dla $count części';
  }

  @override
  String savedIpnCount(int saved, int total) {
    return '✅ Zapisano IPN: $saved/$total';
  }

  @override
  String fetchError(String error) {
    return '❌ Błąd pobierania: $error';
  }

  @override
  String get categoriesTitle => 'Kategorie';

  @override
  String get noCategories => 'Brak kategorii';

  @override
  String get noPartsInCategory => 'Brak części w tej kategorii';

  @override
  String errorText(String error) {
    return 'Błąd: $error';
  }

  @override
  String get scanTitle => 'Skanuj kod';

  @override
  String get selectCodeType => 'Wybierz typ kodu';

  @override
  String scanMode(String mode) {
    return 'Tryb: $mode';
  }
}
