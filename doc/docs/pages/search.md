# Search

The search screen is the app's main interface. It is available immediately after launch.

---

## Interface

```
┌─────────────────────────────────────────┐
│  [Search field]            [🔍] [📷]   │
│  [Category filter ▼]  [↕ Sorting]      │
│  [☑ Low stock only]                    │
├─────────────────────────────────────────┤
│  • Resistor 10k                 12 pcs  │
│    IPN: 1234567                 📦 A3   │
│    ──── Quick adjust: [−][10][+]────── │
│                                        │
│  • Capacitor 100nF               0 pcs  │
│    IPN: 7654321            ⚠ Low stock │
└─────────────────────────────────────────┘
```

---

## Search modes

Selected from the top menu (default: **Auto**):

| Mode | Behavior |
|------|----------|
| **Auto** | Searches by name first; if there are zero results – searches by parameters |
| **IPN** | Exact match of a 7-digit IPN code |
| **Name** | Search by part name (`/api/parts?name=`) |
| **Parameter** | Searches by parameter name (e.g. "Resistance") |
| **Value** | Searches by parameter value (e.g. "10k") |

!!! tip "IPN and the scanner"
    When the scanner returns exactly 7 digits, the app automatically sets IPN mode and opens the **quick adjust** modal instead of a results list.

---

## Filters and sorting

### Category filter

A dropdown of all categories from Part-DB. Limits results to the selected category.

### Low stock filter

The **"Low stock only"** toggle – shows only parts where `totalStock < minAmount` (and `minAmount > 0`).

### Sorting

Available options (the `↕` button):

- Name A→Z (default)
- Name Z→A
- Stock ascending
- Stock descending

---

## History

When the search field is **empty**, instead of a results list the app shows the last **20 viewed parts** (from HistoryService). An entry is added automatically every time `PartDetailPage` is opened.

---

## Quick stock adjustment

Visible on list items for parts with **exactly one** storage location:

```
[−]  [quantity field]  [+]  [💬]  [✓]
```

- **`−` / `+`** – change by 1 down / up
- **Quantity field** – type a number directly
- **`💬`** – optional comment (saved in the lot's `description` field)
- **`✓`** – confirm and send the PATCH to the server

For parts with multiple locations, a button that opens the full details is shown instead of the quick adjust.

---

## Scanning codes

The camera icon (top-right) opens [BarcodeScanPage](../architecture/index.md).

Supported formats:
- **QR Code** and **Data Matrix** – typical for SMD reels and custom labels
- **EAN-13** – manufacturer/distributor codes
- **Code 128** – text codes

After scanning:
- 7 digits → IPN mode, quick adjust
- anything else → full-text search

---

## CSV export

The `⋮` button (context menu) → **Export CSV**.

Exported columns:

| Column | Source |
|--------|--------|
| ID | `part.id` |
| IPN | `part.partNumber` |
| Name | `part.name` |
| Stock | `part.totalStock` |
| Min stock | `part.minAmount` |
| Category | `part.category` |
| Manufacturer | `part.manufacturer` |
| Description | `part.description` |

The file opens in the native Android share dialog (Share+).

---

## Stock taking

The `⋮` button → **Stock taking** opens the dedicated [StockTakingPage](stock-taking.md) screen.
