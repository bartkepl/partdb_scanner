# Part-DB Scanner

Mobilna aplikacja Android do zarządzania magazynem elektroniki, zbudowana we Flutterze. Łączy się z serwerem [Part-DB](https://github.com/Part-DB/Part-DB-server) przez REST API i rozszerza go o obsługę skanerów kodów kreskowych, drukarek etykiet Niimbot oraz drukarek paragonów Sunmi.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Android](https://img.shields.io/badge/Android-6.0%2B-3DDC84?logo=android&logoColor=white)
![License](https://img.shields.io/github/license/bartkepl/partdb_scanner)
![Version](https://img.shields.io/badge/wersja-0.2.17-orange)

---

## Funkcje

| Moduł | Opis |
|---|---|
| **Wyszukiwarka** | Szukaj części po nazwie, IPN lub skanując kod QR/kreskowy |
| **Szczegóły części** | Podgląd i edycja stanów magazynowych, parametrów, zdjęć |
| **Generator IPN** | Automatyczne generowanie numerów wewnętrznych |
| **Przeglądarka kategorii** | Hierarchiczne przeglądanie drzewa kategorii Part-DB |
| **Inwentaryzacja** | Tryb masowej aktualizacji stanów magazynowych |
| **Drukowanie Niimbot** | Etykiety BLE: szufladkowe 22×14 mm, szpulowe 12×40 mm |
| **Drukowanie Sunmi** | Wydruk informacji o części na wbudowanej drukarce termicznej |
| **Alerty niskiego stanu** | Powiadomienie przy starcie aplikacji o częściach poniżej minimum |
| **Historia przeglądanych** | Szybki dostęp do ostatnio otwieranych części |
| **Eksport danych** | Eksport wyników wyszukiwania |

---

## Wymagania

### Serwer
- [Part-DB](https://github.com/Part-DB/Part-DB-server) w wersji obsługującej REST API
- Token API użytkownika z uprawnieniami do odczytu i zapisu

### Urządzenie
- Android 6.0 (API 23) lub nowszy
- Bluetooth Low Energy — wymagany do drukarek Niimbot
- Kamera — wymagana do skanowania kodów

### Opcjonalny sprzęt
- Drukarka etykiet **Niimbot** (D11, B21, B3, D101 i 70+ innych modeli) — połączenie Bluetooth
- Urządzenie **Sunmi** z wbudowaną drukarką termiczną (V2, V2s, T2 i inne)

---

## Instalacja

### Gotowy APK (zalecane)

Pobierz najnowszy plik `.apk` z sekcji [**Releases**](../../releases) i zainstaluj go na urządzeniu. Wymagane włączenie opcji „Instalacja z nieznanych źródeł" w ustawieniach systemu Android.

### Budowanie ze źródeł

1. Zainstaluj [Flutter SDK](https://docs.flutter.dev/get-started/install) (wymagana wersja `^3.9.2`)
2. Sklonuj repozytorium:
   ```bash
   git clone https://github.com/bartkepl/partdb_scanner.git
   cd partdb_scanner
   ```
3. Pobierz zależności:
   ```bash
   flutter pub get
   ```
4. Podłącz urządzenie Android lub uruchom emulator, następnie zbuduj i zainstaluj:
   ```bash
   flutter run --release
   ```
   Lub zbuduj sam plik APK:
   ```bash
   flutter build apk --release
   # Wynikowy plik: build/app/outputs/flutter-apk/app-release.apk
   ```

---

## Konfiguracja

Przy pierwszym uruchomieniu przejdź do zakładki **Konfiguracja** i uzupełnij:

| Pole | Opis |
|---|---|
| **Base URL** | Adres serwera Part-DB, np. `http://192.168.1.10:8000` |
| **API Token** | Token wygenerowany w Part-DB (`Ustawienia → API Tokens`). Można zeskanować jako kod QR. |
| **Zoom kamery** | Poziom przybliżenia przy skanowaniu kodów (1,0× – 3,0×) |
| **Drukarka Sunmi** | Włącz/wyłącz opcję drukowania przez Sunmi |
| **Drukarka Niimbot** | Włącz/wyłącz opcję drukowania etykiet przez Niimbot |

Przełączniki drukarek pozwalają ukryć opcje sprzętowe, z których dane urządzenie nie korzysta.

---

## Drukowanie etykiet Niimbot

Aplikacja obsługuje trzy typy etykiet konfigurowanych w zakładce drukowania:

| Typ etykiety | Rozmiar | Zawartość |
|---|---|---|
| Etykieta szufladki | 22 × 14 mm (poziomo) | Nazwa, IPN, kategoria |
| Etykieta szpuli — parametry | 12 × 40 mm (pionowo) | Nazwa, wartość, obudowa |
| Etykieta szpuli — kod kreskowy | 12 × 40 mm (poziomo) | Kod Code128 z IPN |

Obsługiwane modele drukarek: D11, D101, B21, B3, A8, K3 i ponad 70 innych modeli Niimbot.

---

## Struktura projektu

```
lib/
├── main.dart                   # Punkt wejścia, nawigacja
├── pages/
│   ├── search_page.dart        # Wyszukiwarka części
│   ├── part_detail_page.dart   # Szczegóły i edycja części
│   ├── category_browser_page.dart
│   ├── ipn_generator_page.dart
│   ├── label_print_page.dart   # Drukowanie Niimbot
│   ├── stock_taking_page.dart  # Inwentaryzacja
│   ├── config_page.dart        # Ustawienia aplikacji
│   └── barcode_scan_page.dart
├── services/
│   ├── api_service.dart        # Klient REST Part-DB + przechowywanie konfiguracji
│   ├── niimbot_service.dart    # Obsługa drukarki Niimbot (BLE)
│   ├── printer_service.dart    # Obsługa drukarki Sunmi
│   ├── export_service.dart
│   └── history_service.dart
└── models/
    ├── part.dart
    ├── label_config.dart
    └── api_exception.dart

packages/
└── niim_blue_flutter/          # Lokalny pakiet: protokół Niimbot przez BLE
```

---

## Zależności

| Pakiet | Wersja | Zastosowanie |
|---|---|---|
| `camera` | ^0.11 | Podgląd kamery do skanowania |
| `google_mlkit_barcode_scanning` | ^0.14 | Rozpoznawanie kodów QR i kreskowych |
| `sunmi_printer_plus` | ^4.1 | Drukarka termiczna Sunmi |
| `niim_blue_flutter` | ^1.0 (lokalny) | Protokół Niimbot BLE |
| `flutter_secure_storage` | ^10.0 | Bezpieczne przechowywanie tokenu i konfiguracji |
| `shared_preferences` | ^2.2 | Konfiguracja etykiet |
| `provider` | ^6.0 | Zarządzanie stanem aplikacji |
| `http` | ^1.2 | Komunikacja z API Part-DB |
| `permission_handler` | ^11.3 | Uprawnienia Bluetooth i kamery |
| `image_picker` | ^1.1 | Dodawanie zdjęć do części |
| `barcode` | 2.2.9 | Generowanie obrazów kodów kreskowych |

---

## Licencja

Projekt jest dostępny na licencji [MIT](LICENSE).
