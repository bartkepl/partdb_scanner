# Configuration

The configuration screen is available through the last tab in the bottom navigation bar (gear icon).

---

## Settings

### Server address

A text field with the full base URL of the Part-DB instance.

```
http://192.168.1.10:8000
```

Requirements:
- No trailing slash
- No `/api` path – it is added automatically
- HTTP or HTTPS (the certificate must be trusted by the Android system)

The value is stored in **Flutter Secure Storage** (key `partdb_base_url`).

### API token

A text field or a QR-code scan.

- The **📷** button opens the scanner, which reads the token from a QR code.
- The **Check token** button performs a `GET /api/tokens/current` request and shows the user login or an error message.

The value is stored in **Flutter Secure Storage** (key `partdb_token`).

### Camera zoom

A slider in the range **1.0× – 3.0×** (default: **2.0×**).

It controls the initial camera magnification in `BarcodeScanPage`. A higher value is useful when scanning small Data Matrix codes on SMD reels.

The value is stored in **Flutter Secure Storage** (key `camera_zoom`).

---

## App information

The section at the bottom of the screen shows:

- **App version** – fetched via `package_info_plus`
- **Flutter SDK version**

---

## Data storage

All configuration data is encrypted with a hardware key (Android Keystore) through `flutter_secure_storage`. Only this app's processes can access it.

!!! info "Uninstalling the app"
    Uninstalling the app removes all data from Secure Storage. Reinstalling requires entering the token and server address again.
