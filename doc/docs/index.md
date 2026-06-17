# PartDB Scanner

**PartDB Scanner** is a Flutter mobile app for managing an electronic component inventory, working together with a [Part-DB](https://github.com/Part-DB/Part-DB-server) server. It lets you search, scan barcodes, adjust stock levels and print labels – straight from an Android phone or tablet.

---

## System overview

```
┌─────────────────────────────────────────────┐
│            Android mobile app                │
│                                             │
│  ┌──────────┐   ┌──────────┐  ┌──────────┐ │
│  │  Search  │   │Categories│  │   IPN    │ │
│  │          │   │          │  │Generator │ │
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

  Camera ──► ML Kit ──► QR / DataMatrix / EAN / Code128 codes

  Bluetooth ──► Niimbot D101  (roll labels)
  USB/WiFi  ──► Sunmi Printer (thermal receipts)
```

---

## Features

| Feature | Description |
|---------|-------------|
| **Search** | Fast lookup by IPN, name, parameter or value; history of the last 20 items |
| **Scanning** | QR Code, Data Matrix, EAN-13, Code 128 – camera with ML Kit, configurable zoom |
| **Stock levels** | Browse and edit quantities per location with an optional comment |
| **Parameters** | Inline editing of parameter values (resistance, capacitance, package…) |
| **Categories** | Category tree you can browse and drill down into to reach the part list |
| **IPN generator** | Bulk-assign 7-digit identifiers to parts that have no IPN |
| **Stock taking** | Scan and count with discrepancy detection |
| **Printing** | Niimbot D101 (roll/drawer labels) and Sunmi (thermal receipts) |
| **CSV export** | Export search results through the native share dialog |
| **Photos** | Add photos / attachments to a part straight from the camera or gallery |

---

## Requirements

| Item | Requirement |
|------|-------------|
| System | Android 6.0+ (API 23+) |
| Server | Part-DB with the API enabled (Bearer token) |
| Network | Wi-Fi or LAN connecting the phone to the Part-DB server |
| Optional | Niimbot D101 printer (Bluetooth) or Sunmi (built-in) |

---

## Quick start

1. Open the **Configuration** screen (the last tab).
2. Enter the server base address, e.g. `http://192.168.1.10:8000`.
3. Paste or scan the Part-DB API token.
4. Switch to the **Search** tab and type a component name.

---

## Documentation structure

| Section | Contents |
|---------|----------|
| **[Getting started](getting-started.md)** | Server, API token and permission setup |
| **[Architecture](architecture/index.md)** | Code structure, providers, navigation, services |
| **[Screens](pages/index.md)** | Detailed description of every app screen |
| **[REST API](api.md)** | Part-DB endpoints used by the app |
| **[Data models](models.md)** | Data classes: Part, PartLot, PartParameter… |

---

## Version and license

- **App version**: 0.2.11+1
- **Flutter SDK**: ≥ 3.9.2
- **License**: MIT
