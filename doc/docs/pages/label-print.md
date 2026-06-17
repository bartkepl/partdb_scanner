# Label printing

The app supports two printing systems: the **Niimbot D101** (Bluetooth, adhesive labels) and **Sunmi** (thermal receipt printing on Sunmi devices).

---

## Niimbot D101

### Label types

#### Drawer label (22 × 14 mm)

Meant to be stuck on drawers/bins holding components.

```
┌──────────────────────────────┐
│                    ┌───────┐ │
│  Resistor 10kΩ     │  QR   │ │
│  SMD 0402          │ Data  │ │
│                    │Matrix │ │
│                    └───────┘ │
└──────────────────────────────┘
       22 mm × 14 mm (landscape)
```

- Part name (configurable font size: 10–26 pt)
- A **Data Matrix** code with the IPN on the right edge
- Landscape orientation → text rotated 90° to the left for readability once applied

#### Reel label – parameters (12 × 40 mm)

Meant to be stuck on reels of SMD components.

```
┌─────────────┐
│ 10kΩ        │  ← parameter 1 (bold)
│ 0402        │  ← parameter 2
│ ±1%         │  ← parameter 3
│ 100mW       │  ← parameter 4
│             │
│  [DataMx]   │  ← Data Matrix code with the IPN
└─────────────┘
   12 × 40 mm (portrait)
```

- A list of selected parameters (configurable order and bolding)
- Font size: 22 pt for ≤ 5 parameters, 18 pt for > 5
- A Data Matrix code with the IPN at the bottom

#### Reel label – barcode (12 × 40 mm)

A variant with a linear barcode instead of parameters.

```
┌─────────────────────────────────┐
│                                 │
│  ║║║│║║│║│║║║║│║││║│║║│║│║║║│  │
│           1234567               │
│                                 │
└─────────────────────────────────┘
       12 × 40 mm (landscape)
```

- A **Code 128** barcode stretched across the full 40 mm length
- Landscape orientation

---

### Configuring the reel label (parameters)

The `LabelPrintPage` screen lets you configure the label content:

1. **Parameter list** – a checkbox next to each parameter (enable/disable)
2. **Order** – drag & drop items in the list
3. **Bolding** – a **B** toggle next to each parameter
4. **Preview** – updates live after each change

The configuration is saved automatically in `SharedPreferences` (key `niimbot_label_params`) and restored the next time it is used for the same part.

---

### Pairing the printer

The Niimbot D101 connects over **Bluetooth Classic**. Before the first print:

1. Turn on the printer and enable Bluetooth on the phone.
2. Pair the printer in the Android Bluetooth settings.
3. In the app, choose the printer from the device list.

!!! warning "Bluetooth permissions"
    On Android 12+ the `BLUETOOTH_CONNECT` and `BLUETOOTH_SCAN` permissions are required. Check them in Settings → Apps → PartDB Scanner → Permissions.

---

### Label technical specification

| Parameter | Drawer | Reel (parameters) | Reel (barcode) |
|-----------|--------|-------------------|----------------|
| Size | 22 × 14 mm | 12 × 40 mm | 12 × 40 mm |
| Orientation | Landscape | Portrait | Landscape |
| Resolution | 203 DPI | 203 DPI | 203 DPI |
| Pixels/mm | ~8 px | ~8 px | ~8 px |
| 2D code | Data Matrix | Data Matrix | – |
| 1D code | – | – | Code 128 |
| Code content | IPN (7 digits) | IPN (7 digits) | IPN (7 digits) |

---

## Sunmi (thermal printing)

On Sunmi devices with a built-in thermal printer, a **receipt** printout is available, containing:

- The part name and IPN
- Technical parameters (in the same priority order as the details view)
- Storage locations with quantities
- A QR code with the IPN

The printout is started from the [Part details](part-detail.md) screen via the printer icon → **Sunmi**.
