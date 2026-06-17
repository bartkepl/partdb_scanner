# Konfiguracja

Ekran konfiguracji dostępny jest przez ostatnią zakładkę w dolnym pasku nawigacji (ikona koła zębatego).

---

## Ustawienia

### Adres serwera

Pole tekstowe z pełnym URL bazowym instancji Part-DB.

```
http://192.168.1.10:8000
```

Wymagania:
- Brak końcowego ukośnika
- Bez ścieżki `/api` – dodawana automatycznie
- HTTP lub HTTPS (certyfikat musi być zaufany przez system Android)

Wartość przechowywana w **Flutter Secure Storage** (klucz `partdb_base_url`).

### Token API

Pole tekstowe lub skan kodów QR.

- Przycisk **📷** otwiera skaner, który odczytuje token z kodu QR.
- Przycisk **Sprawdź token** wykonuje żądanie `GET /api/tokens/current` i wyświetla login użytkownika lub komunikat błędu.

Wartość przechowywana w **Flutter Secure Storage** (klucz `partdb_token`).

### Zoom kamery

Suwak w zakresie **1.0× – 3.0×** (domyślnie: **2.0×**).

Steruje wstępnym powiększeniem kamery w `BarcodeScanPage`. Wyższa wartość przydatna przy skanowaniu małych kodów Data Matrix na szpulach SMD.

Wartość przechowywana w **Flutter Secure Storage** (klucz `camera_zoom`).

---

## Informacje o aplikacji

Sekcja na dole ekranu wyświetla:

- **Wersja aplikacji** – pobierana przez `package_info_plus`
- **Wersja Flutter SDK**

---

## Przechowywanie danych

Wszystkie dane konfiguracyjne szyfrowane są kluczem sprzętowym (Android Keystore) przez `flutter_secure_storage`. Dostęp do nich mają wyłącznie procesy tej aplikacji.

!!! info "Odinstalowanie aplikacji"
    Odinstalowanie aplikacji usuwa wszystkie dane z Secure Storage. Ponowna instalacja wymaga wpisania tokenu i adresu serwera od nowa.
