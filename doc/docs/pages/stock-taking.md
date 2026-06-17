# Stock taking

The **Stock taking** screen (`StockTakingPage`) lets you systematically recount stock levels by scanning IPN codes and entering the current quantities.

Access: Search screen → `⋮` menu → **Stock taking**.

---

## Purpose

- Quickly count physical stock without opening each part individually.
- Detect discrepancies between the database and the actual stock.
- Save all corrections in bulk at the end of the session.

---

## Stock-taking flow

### 1. Scan or type an IPN

The IPN field at the top of the screen plus a camera button. After scanning/typing:
- The app searches for the part by that IPN.
- If found – it adds the item to the session list.
- If not found – an error message is shown.

### 2. Enter the current quantity

For each item on the list:
```
Resistor 10k  (IPN: 1234567)
Location: Drawer A3
Database: 12 pcs   Counted: [___]   [✓]
```

- The **Counted** field – type the actual quantity.
- **✓** confirms the value and marks the item as checked.

### 3. Discrepancies

Items where `counted ≠ database` are marked with a ⚠ icon and color highlighting.

### 4. Saving

The **Save all corrections** button sends `PATCH /api/part_lots/{id}` for each modified item.

---

## Session state

The stock-taking session is held only in memory (it is not persisted). Closing the screen discards any unsaved changes.

!!! warning
    Always save your corrections before leaving the screen.
