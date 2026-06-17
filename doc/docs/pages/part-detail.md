# Part details

The details screen opens after selecting an item from the search list or from the category view.

---

## Header

Displays the basic identifying data (read-only):

| Field | Description |
|-------|-------------|
| **Name** | Full part name |
| **ID** | Internal Part-DB identifier |
| **IPN** | Part identifier (7 digits), if assigned |
| **Category** | Part-DB category name |
| **Manufacturer** | Manufacturer name (if filled in) |
| **Tags** | Tags assigned in Part-DB |
| **Description** | Text description of the part |
| **Comment** | Internal comment |

---

## Stock levels

The **Locations** section shows all lots (PartLot) with their quantities and location names.

```
┌──────────────────────────────────────────┐
│  Location: Drawer A3                     │
│  [−]  [  12  ]  [+]  [💬 comment]    [✓]│
│                                          │
│  Location: Drawer B1                     │
│  [−]  [   5  ]  [+]  [💬 comment]    [✓]│
└──────────────────────────────────────────┘
```

- The `✓` button sends a `PATCH /api/part_lots/{id}` request with the new quantity and an optional comment.
- The comment is saved in the lot's `description` field.
- The total stock is shown in the header: `Stock: 17 pcs`.

!!! info "Low stock"
    If `totalStock < minAmount` (and `minAmount > 0`), a warning with a ⚠ icon and the current minimum value is shown.

---

## Parameters

A list of technical parameters with editable values.

Display order (decreasing priority):

1. Value / Resistance / Capacitance / Inductance
2. Package
3. Voltage / Operating voltage
4. Power
5. Manufacturer
6. The rest – alphabetically

Tapping a parameter value opens an inline edit field. After confirming, `PATCH /api/part_parameters/{id}` is sent.

---

## Toolbar

| Icon | Action |
|------|--------|
| 🔄 Refresh | Re-fetches the full data from the server |
| 🖨 Print | Opens the printer selection (Sunmi or [Niimbot](label-print.md)) |
| 📷 Photo | Adds a photo as an attachment to the part |

### Adding a photo

1. Tap the camera icon.
2. Choose the source: **Camera** or **Gallery**.
3. The photo is compressed and base64-encoded.
4. `POST /api/attachments` is sent with the MIME data and a reference to the part.

Supported MIME types: `image/jpeg`, `image/png`, `image/gif`, `image/webp`.

---

## Printing – Sunmi

If the app runs on a Sunmi device with a built-in thermal printer:

- The printout contains: name, IPN, parameters, locations and a QR code with the IPN.
- Formatting: bold headers, right-aligned values.
