# Wyszukiwanie

Ekran wyszukiwania to główny interfejs aplikacji. Dostępny jest natychmiast po uruchomieniu.

---

## Interfejs

```
┌─────────────────────────────────────────┐
│  [Pole wyszukiwania]        [🔍] [📷]  │
│  [Filtr kategorii ▼]  [↕ Sortowanie]   │
│  [☑ Tylko niski stan]                  │
├─────────────────────────────────────────┤
│  • Rezystor 10k                 12 szt  │
│    IPN: 1234567                 📦 A3   │
│    ──── Szybka korekta: [−][10][+]──── │
│                                        │
│  • Kondensator 100nF             0 szt  │
│    IPN: 7654321          ⚠ Niski stan  │
└─────────────────────────────────────────┘
```

---

## Tryby wyszukiwania

Wybierany z górnego menu (domyślnie: **Auto**):

| Tryb | Zachowanie |
|------|------------|
| **Auto** | Najpierw szuka po nazwie; jeśli zero wyników – szuka po parametrach |
| **IPN** | Dokładne dopasowanie 7-cyfrowego kodu IPN |
| **Nazwa** | Wyszukiwanie po nazwie części (`/api/parts?name=`) |
| **Parametr** | Szuka po nazwie parametru (np. „Rezystancja") |
| **Wartość** | Szuka po wartości parametru (np. „10k") |

!!! tip "IPN a skaner"
    Kiedy z skanera wraca dokładnie 7 cyfr, aplikacja automatycznie ustawia tryb IPN i otwiera modal **szybkiej korekty** zamiast listy wyników.

---

## Filtry i sortowanie

### Filtr kategorii

Rozwijana lista wszystkich kategorii z Part-DB. Ogranicza wyniki do wybranej kategorii.

### Filtr niskiego stanu

Przełącznik **„Tylko niski stan"** – pokazuje tylko części, gdzie `totalStock < minAmount` (i `minAmount > 0`).

### Sortowanie

Dostępne opcje (przycisk `↕`):

- Nazwa A→Z (domyślne)
- Nazwa Z→A
- Stan rosnąco
- Stan malejąco

---

## Historia

Gdy pole wyszukiwania jest **puste**, zamiast listy wyników wyświetlane są ostatnie **20 przeglądanych części** (z HistoryService). Wpis dodawany jest automatycznie przy każdym otwarciu `PartDetailPage`.

---

## Szybka korekta stanu

Widoczna przy pozycjach listy dla części z **dokładnie jedną lokalizacją** magazynową:

```
[−]  [pole ilości]  [+]  [💬]  [✓]
```

- **`−` / `+`** – zmiana o 1 w dół / górę
- **Pole ilości** – bezpośrednie wpisanie liczby
- **`💬`** – opcjonalny komentarz (zapisywany w polu `description` partii)
- **`✓`** – zatwierdzenie i wysłanie PATCH do serwera

Dla części z wieloma lokalizacjami zamiast szybkiej korekty widoczny jest przycisk przechodzący do pełnych szczegółów.

---

## Skanowanie kodów

Ikona aparatu (prawy górny róg) otwiera [BarcodeScanPage](../architecture/index.md).

Obsługiwane formaty:
- **QR Code** i **Data Matrix** – typowe dla szpul SMD i własnych etykiet
- **EAN-13** – kody producentów/dystrybutorów
- **Code 128** – kody tekstowe

Po zeskanowaniu:
- 7 cyfr → tryb IPN, szybka korekta
- pozostałe → wyszukiwanie pełnotekstowe

---

## Eksport CSV

Przycisk `⋮` (menu kontekstowe) → **Eksportuj CSV**.

Eksportowane kolumny:

| Kolumna | Źródło |
|---------|--------|
| ID | `part.id` |
| IPN | `part.partNumber` |
| Nazwa | `part.name` |
| Stan | `part.totalStock` |
| Min stan | `part.minAmount` |
| Kategoria | `part.category` |
| Producent | `part.manufacturer` |
| Opis | `part.description` |

Plik otwierany jest w natywnym dialogu udostępniania Androida (Share+).

---

## Inwentaryzacja

Przycisk `⋮` → **Inwentaryzacja** otwiera dedykowany ekran [StockTakingPage](stock-taking.md).
