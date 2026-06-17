# Getting started

## Prerequisites

### Part-DB server

The app requires a running **Part-DB** instance reachable on the same network as the mobile device.

- Part-DB documentation: [https://docs.part-db.de](https://docs.part-db.de)
- Minimum Part-DB version: any version with the REST API enabled (Hydra/JSON-LD)
- The server must be reachable at a fixed IP address or hostname

!!! tip "Local home network"
    A server running on a home NAS or computer (e.g. via Docker) is enough.
    The phone and the server must be on the same Wi-Fi network.

---

## Generating an API token

1. Sign in to the Part-DB panel in your browser.
2. Go to **User settings → API tokens**.
3. Click **Create new token** and give it a name (e.g. `scanner`).
4. Copy the generated token – you will need it during configuration.

!!! warning "Token permissions"
    The token needs read and write permissions for parts, lots, parameters and attachments.
    If you only want to browse, read-only permission is enough.

---

## Configuring the app

After launching the app, open the last tab (gear icon) – **Configuration**.

### 1. Server address

Enter the full base address of the Part-DB server, e.g.:

```
http://192.168.1.10:8000
```

or over HTTPS:

```
https://partdb.my-domain.local
```

!!! note
    Do not add `/api` at the end – the app appends the API paths itself.

### 2. API token

Paste the token copied from Part-DB, or use the scan button to read a token from a QR/barcode.

After entering the token tap **Check token** – the app connects to the server and shows information about the signed-in user.

### 3. Camera zoom

The **Camera zoom** slider (1.0× – 3.0×, default 2.0×) controls the preview magnification while scanning barcodes. Set a higher value for small Data Matrix codes on SMD reels.

---

## Android permissions

On first launch the app asks for the following permissions:

| Permission | Used for |
|------------|----------|
| **Camera** | Scanning barcodes and photographing parts |
| **Bluetooth** | Printing on the Niimbot D101 |
| **Storage** | Temporary CSV file storage during export |

!!! info
    On Android 12+ Bluetooth requires the `BLUETOOTH_CONNECT` and `BLUETOOTH_SCAN` permissions. If the printer does not appear in the list, check that Bluetooth is enabled and that the app has the required permissions in system settings.

---

## Verifying the connection

After configuration:

1. Switch to the **Search** tab.
2. Type any component name or scan a barcode.
3. If results appear – the app is configured correctly.

If an error appears:

| Message | Cause | Solution |
|---------|-------|----------|
| `Connection refused` | Server unreachable or wrong port | Check the address and port, ping it from the Wi-Fi network |
| `401 Unauthorized` | Wrong or expired token | Generate a new token in Part-DB |
| `Timeout` | Server too slow or no network coverage | Check Wi-Fi, raise the server-side time limit |
| `SSL handshake failed` | Untrusted HTTPS certificate | Use HTTP or install the CA certificate |

---

## First use

### Scanning a component

1. Tap the scanner icon (top-right of the Search screen).
2. Point the camera at the Data Matrix or QR code on the reel or package.
3. If the code contains a 7-digit IPN – the app opens the part details directly.
4. For other codes – the app runs a full-text search.

### Quick stock adjustment

For parts with a single storage location, a quick-adjust button (+/−) appears next to the search result. There is no need to open the details.

### Printing a label

1. Open the part details.
2. Tap the printer icon.
3. Choose the label type (drawer or reel).
4. Pair the Niimbot D101 printer over Bluetooth if it is not paired yet.
5. Send the print job.
