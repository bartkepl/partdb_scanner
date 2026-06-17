# API REST

Aplikacja komunikuje się z serwerem Part-DB przez REST API w formacie **JSON-LD / Hydra**. Wszystkie żądania uwierzytelniane są tokenem Bearer.

---

## Uwierzytelnianie

Każde żądanie zawiera nagłówek:

```http
Authorization: Bearer <token>
```

Token pobierany jest z Flutter Secure Storage przy każdym uruchomieniu aplikacji.

---

## Wspólne parametry

| Parametr | Opis |
|----------|------|
| `itemsPerPage` | Maksymalna liczba wyników na stronę (domyślnie 30 w Part-DB) |
| `hydra:view` | Paginacja – zawiera `hydra:next` z URL do następnej strony |
| `hydra:member` | Tablica wyników w odpowiedzi kolekcji |

---

## Timeouty

| Typ żądania | Timeout |
|-------------|---------|
| Standardowe (GET/PATCH) | **10 s** |
| Upload załącznika (POST) | **30 s** |

---

## Endpointy

### Weryfikacja tokenu

```http
GET /api/tokens/current
Authorization: Bearer <token>
```

**Odpowiedź 200:**
```json
{
  "id": 5,
  "user": "/api/users/3",
  "name": "scanner",
  ...
}
```

Używane przez ekran [Konfiguracja](pages/config.md) do sprawdzenia poprawności tokenu.

---

### Wyszukiwanie po IPN

```http
GET /api/parts?ipn={ipn}
```

**Odpowiedź:**
```json
{
  "hydra:member": [
    { "id": 42, "name": "Rezystor 10k", "ipn": "1234567", ... }
  ]
}
```

Używane gdy scanned/wpisany kod to dokładnie 7 cyfr.

---

### Wyszukiwanie po nazwie

```http
GET /api/parts?name={query}&itemsPerPage=100
```

Zwraca max 100 wyników. Wyszukiwanie jest realizowane po stronie serwera (LIKE).

---

### Pobieranie wszystkich części

```http
GET /api/parts?itemsPerPage=100
```

Aplikacja podąża za `hydra:view.hydra:next` aż do zebrania wszystkich rekordów (max **2000**). Używane przez Generator IPN i Inwentaryzację.

---

### Szczegóły części

```http
GET /api/parts/{id}
```

**Odpowiedź (fragment):**
```json
{
  "id": 42,
  "name": "Rezystor 10k",
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
    { "id": 101, "name": "Wartość", "value": "10k", "unit": "Ω" }
  ]
}
```

!!! note
    Pola `category`, `manufacturer`, `storageLocation` są IRI-ami (referencjami). Aplikacja pobiera nazwy przez osobne żądania lub parsuje z osadzonych obiektów.

---

### Aktualizacja partii magazynowej

```http
PATCH /api/part_lots/{id}
Content-Type: application/merge-patch+json

{
  "amount": 15,
  "description": "Opcjonalny komentarz"
}
```

**Odpowiedź 200:** zaktualizowany obiekt `PartLot`.

---

### Aktualizacja parametru

```http
PATCH /api/part_parameters/{id}
Content-Type: application/merge-patch+json

{
  "value": "22k"
}
```

---

### Nadanie IPN

```http
PATCH /api/parts/{id}
Content-Type: application/merge-patch+json

{
  "ipn": "3847291"
}
```

---

### Pobieranie kategorii

```http
GET /api/categories?itemsPerPage=200
```

Aplikacja pobiera do **200** kategorii stronicując przez `hydra:next`. Używane przez [Przeglądarkę kategorii](pages/category-browser.md).

**Odpowiedź (fragment):**
```json
{
  "hydra:member": [
    { "id": 1, "name": "Rezystory", "parent": null },
    { "id": 2, "name": "SMD", "parent": "/api/categories/1" }
  ]
}
```

---

### Pobieranie typów załączników

```http
GET /api/attachment_types?itemsPerPage=1
```

Pobiera pierwszy dostępny typ załącznika do użycia przy uploadzie zdjęcia.

---

### Upload załącznika (zdjęcie)

```http
POST /api/attachments
Content-Type: application/ld+json
Authorization: Bearer <token>

{
  "name": "Zdjęcie - Rezystor 10k",
  "element": "/api/parts/42",
  "uploadFile": "data:image/jpeg;base64,/9j/4AAQSkZJRgAB...",
  "attachment_type": "/api/attachment_types/1"
}
```

**Odpowiedź 201:** obiekt załącznika.

Zdjęcie jest pobierane z aparatu lub galerii, kompresowane do JPEG i kodowane base64 bezpośrednio w body żądania.

---

## Obsługa błędów

Aplikacja parsuje odpowiedzi błędów w następującej kolejności:

1. Pole `hydra:description`
2. Tablica `violations[].message` (błędy walidacji)
3. Pole `detail`
4. Tekst statusu HTTP

Błędy wyświetlane są użytkownikowi przez `SnackBar`.

```dart
// Przykładowa odpowiedź błędu walidacji (422)
{
  "@type": "ConstraintViolationList",
  "violations": [
    { "propertyPath": "ipn", "message": "This value is already used." }
  ]
}
```
