# Category browser

The **Categories** screen lets you browse the Part-DB category hierarchy as a tree and drill down to the list of parts in a selected category.

---

## Tree interface

```
▶ Capacitors
▼ Resistors
    ▶ SMD
    ▼ THT
        ─ 1/4W
        ─ 1/2W
▶ Semiconductors
```

- **▶** – collapsed category; tap to expand
- **▼** – expanded category; tap the arrow to collapse
- **─** – category with no subcategories; tap the name to see its parts

Tapping a **category name** (not the arrow) opens the list of parts in that category.

---

## Parts list in a category

The `_CategoryPartsPage` screen shows:

- All parts assigned directly to the selected category
- Alphabetical sorting by name
- A ⚠ icon next to low-stock parts
- Tapping an item opens the [Part details](part-detail.md)

!!! note "Loading categories"
    All categories are fetched once on first entry to the tab (max 200 entries, Hydra pagination). The categories are cached in memory for the session.

---

## Technical details

Categories are fetched through:
```
GET /api/categories?itemsPerPage=200
```

The app tracks which tree nodes are expanded (`Set<int> _expandedIds`) and renders the list recursively. Each indentation level is offset by 16 px.
