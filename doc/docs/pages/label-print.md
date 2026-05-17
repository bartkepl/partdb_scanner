# Drukowanie etykiet

Aplikacja obsługuje dwa systemy drukowania: **Niimbot D101** (Bluetooth, etykiety adhezyjne) oraz **Sunmi** (termiczny wydruk paragonów na urządzeniach Sunmi).

---

## Niimbot D101

### Typy etykiet

#### Etykieta szufladkowa (22 × 14 mm)

Przeznaczona do naklejania na szufladki/pojemniki z komponentami.

```
┌──────────────────────────────┐
│                    ┌───────┐ │
│  Rezystor 10kΩ     │  QR   │ │
│  SMD 0402          │ Data  │ │
│                    │Matrix │ │
│                    └───────┘ │
└──────────────────────────────┘
       22 mm × 14 mm (landscape)
```

- Nazwa części (konfigurowalna wielkość czcionki: 10–26 pt)
- Kod **Data Matrix** z IPN na prawej krawędzi
- Orientacja pozioma → tekst obrócony 90° w lewo dla czytelności po naklejeniu

#### Etykieta szpulowa – parametry (12 × 40 mm)

Przeznaczona do naklejania na szpule z komponentami SMD.

```
┌─────────────┐
│ 10kΩ        │  ← parametr 1 (bold)
│ 0402        │  ← parametr 2
│ ±1%         │  ← parametr 3
│ 100mW       │  ← parametr 4
│             │
│  [DataMx]   │  ← kod Data Matrix z IPN
└─────────────┘
   12 × 40 mm (portrait)
```

- Lista wybranych parametrów (konfigurowalna kolejność i pogrubienie)
- Rozmiar czcionki: 22 pt dla ≤ 5 parametrów, 18 pt dla > 5
- Kod Data Matrix z IPN na dole

#### Etykieta szpulowa – kod kreskowy (12 × 40 mm)

Wariant z kodem liniowym zamiast parametrów.

```
┌─────────────────────────────────┐
│                                 │
│  ║║║│║║│║│║║║║│║││║│║║│║│║║║│  │
│           1234567               │
│                                 │
└─────────────────────────────────┘
       12 × 40 mm (landscape)
```

- Kod **Code 128** rozciągnięty na całą długość 40 mm
- Orientacja pozioma

---

### Konfiguracja etykiety szpulowej (parametry)

Ekran `LabelPrintPage` pozwala skonfigurować zawartość etykiety:

1. **Lista parametrów** – checkbox przy każdym parametrze (włącz/wyłącz)
2. **Kolejność** – przeciąganie (drag & drop) pozycji na liście
3. **Pogrubienie** – przełącznik **B** przy każdym parametrze
4. **Podgląd** – aktualizuje się na żywo po każdej zmianie

Konfiguracja zapisywana jest automatycznie w `SharedPreferences` (klucz `niimbot_label_params`) i odtwarzana przy kolejnym użyciu dla tej samej części.

---

### Parowanie z drukarką

Drukarka Niimbot D101 łączy się przez **Bluetooth Classic**. Przed pierwszym wydrukiem:

1. Włącz drukarkę i aktywuj Bluetooth na telefonie.
2. Sparuj drukarkę w ustawieniach Bluetooth Androida.
3. W aplikacji wybierz drukarkę z listy urządzeń.

!!! warning "Uprawnienia Bluetooth"
    Na Androidzie 12+ wymagane są uprawnienia `BLUETOOTH_CONNECT` i `BLUETOOTH_SCAN`. Sprawdź je w Ustawieniach → Aplikacje → PartDB Scanner → Uprawnienia.

---

### Specyfikacja techniczna etykiet

| Parametr | Szufladkowa | Szpulowa parametry | Szpulowa barcode |
|----------|-------------|-------------------|-----------------|
| Rozmiar | 22 × 14 mm | 12 × 40 mm | 12 × 40 mm |
| Orientacja | Landscape | Portrait | Landscape |
| Rozdzielczość | 203 DPI | 203 DPI | 203 DPI |
| Piksel/mm | ~8 px | ~8 px | ~8 px |
| Kod 2D | Data Matrix | Data Matrix | – |
| Kod 1D | – | – | Code 128 |
| Zawartość kodu | IPN (7 cyfr) | IPN (7 cyfr) | IPN (7 cyfr) |

---

## Sunmi (wydruk termiczny)

Na urządzeniach Sunmi z wbudowaną drukarką termiczną dostępny jest wydruk **paragonu** zawierającego:

- Nazwę części i IPN
- Parametry techniczne (priorytetowa kolejność jak w widoku szczegółów)
- Lokalizacje magazynowe z ilościami
- Kod QR z IPN

Wydruk inicjowany jest z ekranu [Szczegóły części](part-detail.md) przez ikonę drukarki → **Sunmi**.
