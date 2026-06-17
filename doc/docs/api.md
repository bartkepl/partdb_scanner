# REST API

The app talks to the Part-DB server over a REST API in **JSON-LD / Hydra** format. Every request is authenticated with a Bearer token.

---

## Authentication

Each request includes the header:

```http
Authorization: Bearer <token>
```

The token is read from Flutter Secure Storage every time the app starts.

---

## Common parameters

| Parameter | Description |
|-----------|-------------|
| `itemsPerPage` | Maximum number of results per page (default 30 in Part-DB) |
| `hydra:view` | Pagination – contains `hydra:next` with the URL of the next page |
| `hydra:member` | Array of results in a collection response |

---

## Timeouts

| Request type | Timeout |
|--------------|---------|
| Standard (GET/PATCH) | **10 s** |
| Attachment upload (POST) | **30 s** |

---

## Endpoints

### Token verification

```http
GET /api/tokens/current
Authorization: Bearer <token>
```

**200 response:**
```json
{
  "id": 5,
  "user": "/api/users/3",
  "name": "scanner",
  ...
}
```

Used by the [Configuration](pages/config.md) screen to verify the token.

---

### Search by IPN

```http
GET /api/parts?ipn={ipn}
```

**Response:**
```json
{
  "hydra:member": [
    { "id": 42, "name": "Resistor 10k", "ipn": "1234567", ... }
  ]
}
```

Used when the scanned/typed code is exactly 7 digits.

---

### Search by name

```http
GET /api/parts?name={query}&itemsPerPage=100
```

Returns up to 100 results. The search is performed server-side (LIKE).

---

### Fetch all parts

```http
GET /api/parts?itemsPerPage=100
```

The app follows `hydra:view.hydra:next` until it has collected every record (max **2000**). Used by the IPN Generator and Stock Taking.

---

### Part details

```http
GET /api/parts/{id}
```

**Response (excerpt):**
```json
{
  "id": 42,
  "name": "Resistor 10k",
  "ipn": "1234567",
  "minamount": 10,
  "description": "...",
  "comment": "...",
  "category": "/api/categories/5",
  "manufacturer": "/api/manufacturers/3",
  "tags": "smd,resistor",
  "partLots": [
    { "id": 7, "amount": 12.0, "storageLocation": "/api/storage_locations/2" }
  ],
  "parameters": [
    { "id": 101, "name": "Value", "value": "10k", "unit": "Ω" }
  ]
}
```

!!! note
    The `category`, `manufacturer` and `storageLocation` fields are IRIs (references). The app resolves the names through separate requests or by parsing embedded objects.

---

### Update a storage lot

```http
PATCH /api/part_lots/{id}
Content-Type: application/merge-patch+json

{
  "amount": 15,
  "description": "Optional comment"
}
```

**200 response:** the updated `PartLot` object.

---

### Update a parameter

```http
PATCH /api/part_parameters/{id}
Content-Type: application/merge-patch+json

{
  "value": "22k"
}
```

---

### Assign an IPN

```http
PATCH /api/parts/{id}
Content-Type: application/merge-patch+json

{
  "ipn": "3847291"
}
```

---

### Fetch categories

```http
GET /api/categories?itemsPerPage=200
```

The app fetches up to **200** categories, paging through `hydra:next`. Used by the [Category browser](pages/category-browser.md).

**Response (excerpt):**
```json
{
  "hydra:member": [
    { "id": 1, "name": "Resistors", "parent": null },
    { "id": 2, "name": "SMD", "parent": "/api/categories/1" }
  ]
}
```

---

### Fetch attachment types

```http
GET /api/attachment_types?itemsPerPage=1
```

Fetches the first available attachment type to use when uploading a photo.

---

### Upload an attachment (photo)

```http
POST /api/attachments
Content-Type: application/ld+json
Authorization: Bearer <token>

{
  "name": "Photo - Resistor 10k",
  "element": "/api/parts/42",
  "uploadFile": "data:image/jpeg;base64,/9j/4AAQSkZJRgAB...",
  "attachment_type": "/api/attachment_types/1"
}
```

**201 response:** the attachment object.

The photo is taken from the camera or gallery, compressed to JPEG and base64-encoded directly in the request body.

---

## Error handling

The app parses error responses in the following order:

1. The `hydra:description` field
2. The `violations[].message` array (validation errors)
3. The `detail` field
4. The HTTP status text

Errors are shown to the user through a `SnackBar`.

```dart
// Example validation error response (422)
{
  "@type": "ConstraintViolationList",
  "violations": [
    { "propertyPath": "ipn", "message": "This value is already used." }
  ]
}
```
