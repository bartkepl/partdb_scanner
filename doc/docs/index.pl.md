# PartDB Scanner

**PartDB Scanner** to mobilna aplikacja Flutter do zarządzania magazynem komponentów elektronicznych, współpracująca z serwerem [Part-DB](https://github.com/Part-DB/Part-DB-server). Umożliwia wyszukiwanie, skanowanie kodów kreskowych, korektę stanów magazynowych i drukowanie etykiet – bezpośrednio z telefonu lub tabletu Android.

---

## Schemat systemu

```
┌─────────────────────────────────────────────┐
│           Aplikacja mobilna Android          │
│                                             │
│  ┌──────────┐   ┌──────────┐  ┌──────────┐ │
│  │ Wyszuki- │   │ Kategorie│  │Generator │ │
│  │  wanie   │   │          │  │   IPN    │ │
│  └────┬─────┘   └────┬─────┘  └────┬─────┘ │
│       │              │             │        │
│       └──────────────┴─────────────┘        │
│                      │                      │
│              ┌───────▼────────┐             │
│              │   ApiService   │             │
│              │  (REST client) │             │
│              └───────┬────────┘             │
└──────────────────────┼──────────────────────┘
                       │ HTTP/HTTPS
                       │ Bearer token
              ┌────────▼────────┐
              │   Part-DB       │
              │   Server        │
              │  (self-hosted)  │
              └─────────────────┘

  Kamera ──► ML Kit ──► kody QR / DataMatrix / EAN / Code128

  Bluetooth ──► Niimbot D101  (etykiety na szpule)
  USB/WiFi  ──► Sunmi Printer (paragony termiczne)
```

---

## Funkcje

| Funkcja | Opis |
|---------|------|
| **Wyszukiwanie** | Szybkie szukanie po IPN, nazwie, parametrach lub wartości; historia ostatnich 20 pozycji |
| **Skanowanie** | QR Code, Data Matrix, EAN-13, Code 128 – kamera z ML Kit, konfigurowalne powiększenie |
| **Stany magazynowe** | Przeglądanie i edycja ilości per lokalizacja z opcjonalnym komentarzem |
| **Parametry** | Edycja wartości parametrów (rezystancja, pojemność, obudowa...) inline |
| **Kategorie** | Drzewo kategorii z możliwością przeglądania i drążenia do listy części |
| **Generator IPN** | Masowe nadawanie 7-cyfrowych identyfikatorów częściom bez IPN |
| **Inwentaryzacja** | Skanowanie + zliczanie z wykrywaniem rozbieżności |
| **Drukowanie** | Niimbot D101 (etykiety szpulowe, szufladkowe) i Sunmi (paragony termiczne) |
| **Eksport CSV** | Eksport wyników wyszukiwania przez natywny dialog udostępniania |
| **Zdjęcia** | Dodawanie zdjęć / załączników do części bezpośrednio z aparatu lub galerii |

---

## Wymagania

| Element | Wymaganie |
|---------|-----------|
| System | Android 6.0+ (API 23+) |
| Serwer | Part-DB z aktywnym API (Bearer token) |
| Sieć | Wi-Fi lub LAN łączący telefon z serwerem Part-DB |
| Opcjonalnie | Drukarka Niimbot D101 (Bluetooth) lub Sunmi (wbudowana) |

---

## Szybki start

1. Otwórz ekran **Konfiguracja** (ostatnia zakładka).
2. Wpisz adres bazowy serwera, np. `http://192.168.1.10:8000`.
3. Wklej lub zeskanuj token API Part-DB.
4. Przejdź na zakładkę **Wyszukiwanie** i wpisz nazwę komponentu.

---

## Struktura dokumentacji

| Sekcja | Zawartość |
|--------|-----------|
| **[Pierwsze kroki](getting-started.md)** | Konfiguracja serwera, tokenu API, uprawnień |
| **[Architektura](architecture/index.md)** | Struktura kodu, provider, nawigacja, serwisy |
| **[Ekrany](pages/index.md)** | Szczegółowy opis każdego ekranu aplikacji |
| **[API REST](api.md)** | Endpointy Part-DB używane przez aplikację |
| **[Modele danych](models.md)** | Klasy danych: Part, PartLot, PartParameter… |

---

## Wersja i licencja

- **Wersja aplikacji**: 0.2.11+1
- **Flutter SDK**: ≥ 3.9.2
- **Licencja**: MIT
