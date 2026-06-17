# IPN generator

The **IPN generator** screen is used to bulk-assign IPN identifiers to parts that do not have one yet.

---

## What is an IPN?

An IPN (*Internal Part Number*) is a unique 7-digit identifier in the range `1,000,000 – 9,999,999`. It uniquely labels a component – for example with a QR or Data Matrix code on a reel label.

---

## Workflow

```mermaid
graph TD
    A[Fetch all parts\nwithout an IPN] --> B[Show a list with\ncheckboxes]
    B --> C{Select parts}
    C --> D[Generate random IPNs\nwithout collisions]
    D --> E[Preview in a\nconfirmation dialog]
    E -->|Confirm| F[PATCH /api/parts/{id}\nfor each selected part]
    F --> G[Show results\n✅/❌ per part]
    G --> A
```

---

## Interface

### List of parts without an IPN

On entering the tab the app fetches all parts (`fetchAllParts()`) and filters those with an empty IPN field.

```
☑  Select all

☐  Resistor 100Ω         ID: 42
☑  Capacitor 10µF        ID: 87
☐  Red LED               ID: 103
...

[Generate IPN for selected]
```

- The **"Select all"** checkbox selects / deselects the whole list.
- Each item shows the part name and its Part-DB ID.

### Confirmation dialog

Before sending, a dialog appears with a preview of the assignments:

```
Assign IPN:
  Capacitor 10µF  →  3 847 291
  ...

[Cancel]  [Confirm]
```

### Results screen

After confirming, each item gets a status:

- **✅** – IPN assigned successfully
- **❌** – error (e.g. a server-side collision, a network problem)

---

## IPN generation algorithm

1. The app collects the set of all **existing IPNs** from the fetched parts.
2. For each selected part it draws a random number from the range `1,000,000 – 9,999,999`.
3. It checks for collisions against both the existing IPNs and those already generated in this session.
4. It re-draws until it succeeds (with no iteration limit – collisions are extremely rare).

---

## Technical details

Assigning an IPN:
```
PATCH /api/parts/{id}
Content-Type: application/merge-patch+json

{ "ipn": "3847291" }
```

After the session finishes, the list refreshes automatically.
