# Modele danych

Aplikacja używa kilku klas danych Dart do reprezentowania obiektów z Part-DB i lokalnej konfiguracji.

---

## Part

Główna klasa reprezentująca komponent elektroniczny.

```dart
class Part {
  final int id;
  final String name;
  final String partNumber;   // IPN (7-cyfrowy identyfikator)
  final String unit;         // jednostka miary (np. "pcs", "m")
  final double minAmount;    // minimalny wymagany stan
  final String description;
  final String comment;
  String category;           // nazwa kategorii (uzupełniana osobno)
  String manufacturer;       // nazwa producenta (uzupełniana osobno)
  final String tags;
  List<PartLot> partLots;    // lokalizacje magazynowe
  List<PartParameter> parameters;

  // Pola obliczane
  int get totalStock;        // suma amount ze wszystkich partLots
  bool get isLowStock;       // totalStock < minAmount && minAmount > 0
}
```

| Pole | Typ | Opis |
|------|-----|------|
| `id` | `int` | Identyfikator w Part-DB |
| `name` | `String` | Pełna nazwa części |
| `partNumber` | `String` | IPN (może być pusty) |
| `unit` | `String` | Jednostka miary |
| `minAmount` | `double` | Minimalny wymagany stan |
| `description` | `String` | Opis tekstowy |
| `comment` | `String` | Komentarz wewnętrzny |
| `category` | `String` | Nazwa kategorii (mutowalny, wypełniany po pobraniu) |
| `manufacturer` | `String` | Nazwa producenta (mutowalny) |
| `tags` | `String` | Tagi rozdzielone przecinkami |
| `partLots` | `List<PartLot>` | Lokalizacje z ilościami |
| `parameters` | `List<PartParameter>` | Parametry techniczne |
| `totalStock` | `int` | Obliczony: suma ilości ze wszystkich `partLots` |
| `isLowStock` | `bool` | Obliczony: `minAmount > 0 && totalStock < minAmount` |

---

## PartLot

Reprezentuje partię magazynową – ilość w konkretnej lokalizacji.

```dart
class PartLot {
  final int id;
  final String locationName;
  final double amount;
}
```

| Pole | Typ | Opis |
|------|-----|------|
| `id` | `int` | Identyfikator partii w Part-DB |
| `locationName` | `String` | Nazwa lokalizacji (szuflada, regał...) |
| `amount` | `double` | Ilość w tej lokalizacji |

---

## PartParameter

Pojedynczy parametr techniczny części.

```dart
class PartParameter {
  final int id;
  final String name;
  final String value;
  final String unit;
}
```

| Pole | Typ | Opis |
|------|-----|------|
| `id` | `int` | Identyfikator parametru w Part-DB |
| `name` | `String` | Nazwa parametru (np. „Wartość", „Obudowa") |
| `value` | `String` | Wartość tekstowa (parsowana z kilku możliwych pól API) |
| `unit` | `String` | Jednostka (np. „Ω", „F", „V") |

!!! note "Parsowanie wartości"
    API Part-DB może zwrócić wartość parametru w polu `value`, `value_text` lub `formatted`. Aplikacja sprawdza kolejno każde z tych pól.

---

## ApiException

Wyjątek rzucany przez `ApiService` przy błędzie HTTP lub parsowania.

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
}
```

Używany do wyświetlania szczegółowych komunikatów błędów w UI (SnackBar).

---

## LabelConfig

Konfiguracja parametrów etykiety Niimbot, persystowana przez `SharedPreferences`.

```dart
class LabelConfig {
  List<LabelParamEntry> entries;

  // Serializacja do/z JSON
  // Zapis: SharedPreferences klucz 'niimbot_label_params'
}

class LabelParamEntry {
  final String name;   // nazwa parametru
  bool enabled;        // czy drukować ten parametr
  bool bold;           // czy pogrubiony
}
```

| Pole | Typ | Opis |
|------|-----|------|
| `name` | `String` | Nazwa parametru (musi pasować do `PartParameter.name`) |
| `enabled` | `bool` | Czy parametr jest włączony na etykiecie |
| `bold` | `bool` | Czy parametr drukowany jest pogrubioną czcionką |

`LabelConfig` implementuje logikę **scalania**: przy każdym otwarciu ekranu drukowania aktualna lista parametrów części jest łączona z zapisaną konfiguracją. Nowe parametry dodawane są na koniec jako włączone i niepogrubione; usunięte parametry są pomijane.

---

## HistoryEntry

Wpis historii ostatnio oglądanych części. Przechowywany jako JSON w `SharedPreferences`.

```dart
class HistoryEntry {
  final int id;
  final String name;
  final String ipn;
}
```

Historia ograniczona jest do **20** ostatnich wpisów. Duplikaty (ten sam `id`) są usuwane przy dodawaniu nowego wpisu.
