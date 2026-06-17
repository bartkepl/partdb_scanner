# Inwentaryzacja

Ekran **Inwentaryzacja** (`StockTakingPage`) umożliwia systematyczne przeliczanie stanów magazynowych przez skanowanie kodów IPN i wpisywanie aktualnych ilości.

Dostęp: ekran Wyszukiwanie → menu `⋮` → **Inwentaryzacja**.

---

## Cel

- Szybkie zliczanie fizycznych stanów bez otwierania każdej części osobno.
- Wykrywanie rozbieżności między bazą a stanem rzeczywistym.
- Zbiorczy zapis poprawek na koniec sesji.

---

## Przebieg inwentaryzacji

### 1. Skanowanie lub wpisanie IPN

Pole IPN na górze ekranu + przycisk aparatu. Po zeskanowaniu/wpisaniu:
- Aplikacja szuka części po tym IPN.
- Jeśli znaleziona – dodaje pozycję do listy sesji.
- Jeśli nie znaleziona – komunikat błędu.

### 2. Wpisanie aktualnej ilości

Dla każdej pozycji na liście:
```
Rezystor 10k  (IPN: 1234567)
Lokalizacja: Szuflada A3
Baza: 12 szt   Zliczone: [___]   [✓]
```

- Pole **Zliczone** – wpisz rzeczywistą ilość.
- **✓** zatwierdza wartość i oznacza pozycję jako sprawdzoną.

### 3. Rozbieżności

Pozycje, gdzie `zliczone ≠ baza`, oznaczone są ikoną ⚠ i wyróżnieniem kolorystycznym.

### 4. Zapis

Przycisk **Zapisz wszystkie korekty** wysyła `PATCH /api/part_lots/{id}` dla każdej zmodyfikowanej pozycji.

---

## Stan sesji

Sesja inwentaryzacyjna jest przechowywana tylko w pamięci (nie jest persystowana). Zamknięcie ekranu powoduje utratę niezapisanych zmian.

!!! warning
    Zawsze zapisuj korekty przed opuszczeniem ekranu.
