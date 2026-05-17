# Szczegóły części

Ekran szczegółów otwierany jest po wybraniu pozycji z listy wyszukiwania lub z widoku kategorii.

---

## Nagłówek

Wyświetla podstawowe dane identyfikacyjne (tylko do odczytu):

| Pole | Opis |
|------|------|
| **Nazwa** | Pełna nazwa części |
| **ID** | Wewnętrzny identyfikator Part-DB |
| **IPN** | Identyfikator części (7 cyfr), jeśli nadany |
| **Kategoria** | Nazwa kategorii Part-DB |
| **Producent** | Nazwa producenta (jeśli wypełniona) |
| **Tagi** | Tagi przypisane w Part-DB |
| **Opis** | Opis tekstowy części |
| **Komentarz** | Komentarz wewnętrzny |

---

## Stany magazynowe

Sekcja **Lokalizacje** pokazuje wszystkie partie (PartLot) z ich ilościami i nazwami lokalizacji.

```
┌──────────────────────────────────────────┐
│  Lokalizacja: Szuflada A3                │
│  [−]  [  12  ]  [+]  [💬 komentarz]  [✓]│
│                                          │
│  Lokalizacja: Szuflada B1                │
│  [−]  [   5  ]  [+]  [💬 komentarz]  [✓]│
└──────────────────────────────────────────┘
```

- Przycisk `✓` wysyła żądanie `PATCH /api/part_lots/{id}` z nową ilością i opcjonalnym komentarzem.
- Komentarz zapisywany jest w polu `description` partii magazynowej.
- Całkowity stan wyświetlany jest w nagłówku: `Stan: 17 szt`.

!!! info "Niski stan"
    Jeśli `totalStock < minAmount` (i `minAmount > 0`), wyświetlane jest ostrzeżenie z ikoną ⚠ i aktualną wartością minimalną.

---

## Parametry

Lista parametrów technicznych z możliwością edycji wartości.

Kolejność wyświetlania (priorytet malejący):

1. Wartość / Rezystancja / Pojemność / Indukcyjność
2. Obudowa
3. Napięcie / Napięcie pracy
4. Moc
5. Producent
6. Pozostałe – alfabetycznie

Kliknięcie wartości parametru otwiera inline pole edycji. Po zatwierdzeniu wysyłane jest `PATCH /api/part_parameters/{id}`.

---

## Pasek narzędzi

| Ikona | Akcja |
|-------|-------|
| 🔄 Odśwież | Pobiera ponownie pełne dane z serwera |
| 🖨 Drukuj | Otwiera wybór drukarki (Sunmi lub [Niimbot](label-print.md)) |
| 📷 Zdjęcie | Dodaje zdjęcie jako załącznik do części |

### Dodawanie zdjęcia

1. Kliknij ikonę aparatu.
2. Wybierz źródło: **Aparat** lub **Galeria**.
3. Zdjęcie jest kompresowane i kodowane base64.
4. Wysyłane jest `POST /api/attachments` z danymi MIME i odniesieniem do części.

Obsługiwane typy MIME: `image/jpeg`, `image/png`, `image/gif`, `image/webp`.

---

## Drukowanie – Sunmi

Jeśli aplikacja działa na urządzeniu Sunmi z wbudowaną drukarką termiczną:

- Wydruk zawiera: nazwę, IPN, parametry, lokalizacje oraz kod QR z IPN.
- Formatowanie: pogrubienie nagłówków, wyrównanie do prawej dla wartości.
