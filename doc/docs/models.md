# Data models

The app uses several Dart data classes to represent objects from Part-DB and the local configuration.

---

## Part

The main class representing an electronic component.

```dart
class Part {
  final int id;
  final String name;
  final String partNumber;   // IPN (7-digit identifier)
  final String unit;         // unit of measure (e.g. "pcs", "m")
  final double minAmount;    // minimum required stock
  final String description;
  final String comment;
  String category;           // category name (filled in separately)
  String manufacturer;       // manufacturer name (filled in separately)
  final String tags;
  List<PartLot> partLots;    // storage locations
  List<PartParameter> parameters;

  // Computed fields
  int get totalStock;        // sum of amount across all partLots
  bool get isLowStock;       // totalStock < minAmount && minAmount > 0
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int` | Identifier in Part-DB |
| `name` | `String` | Full part name |
| `partNumber` | `String` | IPN (may be empty) |
| `unit` | `String` | Unit of measure |
| `minAmount` | `double` | Minimum required stock |
| `description` | `String` | Text description |
| `comment` | `String` | Internal comment |
| `category` | `String` | Category name (mutable, filled in after fetching) |
| `manufacturer` | `String` | Manufacturer name (mutable) |
| `tags` | `String` | Comma-separated tags |
| `partLots` | `List<PartLot>` | Locations with quantities |
| `parameters` | `List<PartParameter>` | Technical parameters |
| `totalStock` | `int` | Computed: sum of quantities across all `partLots` |
| `isLowStock` | `bool` | Computed: `minAmount > 0 && totalStock < minAmount` |

---

## PartLot

Represents a storage lot – a quantity at a specific location.

```dart
class PartLot {
  final int id;
  final String locationName;
  final double amount;
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int` | Lot identifier in Part-DB |
| `locationName` | `String` | Location name (drawer, shelf…) |
| `amount` | `double` | Quantity at this location |

---

## PartParameter

A single technical parameter of a part.

```dart
class PartParameter {
  final int id;
  final String name;
  final String value;
  final String unit;
}
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int` | Parameter identifier in Part-DB |
| `name` | `String` | Parameter name (e.g. "Value", "Package") |
| `value` | `String` | Text value (parsed from several possible API fields) |
| `unit` | `String` | Unit (e.g. "Ω", "F", "V") |

!!! note "Value parsing"
    The Part-DB API may return the parameter value in the `value`, `value_text` or `formatted` field. The app checks each of these fields in turn.

---

## ApiException

The exception thrown by `ApiService` on an HTTP or parsing error.

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
}
```

Used to show detailed error messages in the UI (SnackBar).

---

## LabelConfig

Configuration of the Niimbot label parameters, persisted through `SharedPreferences`.

```dart
class LabelConfig {
  List<LabelParamEntry> entries;

  // Serialization to/from JSON
  // Storage: SharedPreferences key 'niimbot_label_params'
}

class LabelParamEntry {
  final String name;   // parameter name
  bool enabled;        // whether to print this parameter
  bool bold;           // whether it is bold
}
```

| Field | Type | Description |
|-------|------|-------------|
| `name` | `String` | Parameter name (must match `PartParameter.name`) |
| `enabled` | `bool` | Whether the parameter is enabled on the label |
| `bold` | `bool` | Whether the parameter is printed in bold |

`LabelConfig` implements **merge** logic: every time the print screen is opened, the current list of part parameters is merged with the saved configuration. New parameters are appended at the end as enabled and non-bold; removed parameters are skipped.

---

## HistoryEntry

An entry in the history of recently viewed parts. Stored as JSON in `SharedPreferences`.

```dart
class HistoryEntry {
  final int id;
  final String name;
  final String ipn;
}
```

The history is limited to the **20** most recent entries. Duplicates (the same `id`) are removed when a new entry is added.
