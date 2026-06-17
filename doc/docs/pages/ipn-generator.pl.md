# Generator IPN

Ekran **Generator IPN** służy do masowego nadawania identyfikatorów IPN częściom, które ich jeszcze nie posiadają.

---

## Czym jest IPN?

IPN (*Internal Part Number*) to unikalny 7-cyfrowy identyfikator w zakresie `1 000 000 – 9 999 999`. Służy do jednoznacznego oznaczenia komponentu – np. kodem QR lub Data Matrix na etykiecie szpuli.

---

## Przepływ pracy

```mermaid
graph TD
    A[Pobierz wszystkie części\nbez IPN] --> B[Wyświetl listę z\ncheckboxami]
    B --> C{Zaznacz części}
    C --> D[Generuj losowe IPN\nbez kolizji]
    D --> E[Podgląd w dialogu\npotwierdzenia]
    E -->|Zatwierdź| F[PATCH /api/parts/{id}\ndla każdej zaznaczonej części]
    F --> G[Wyświetl wyniki\n✅/❌ per część]
    G --> A
```

---

## Interfejs

### Lista części bez IPN

Po wejściu na zakładkę aplikacja pobiera wszystkie części (`fetchAllParts()`) i filtruje te z pustym polem IPN.

```
☑  Selekcja wszystkich

☐  Rezystor 100Ω         ID: 42
☑  Kondensator 10µF      ID: 87
☐  LED czerwona          ID: 103
...

[Generuj IPN dla zaznaczonych]
```

- Checkbox **„Selekcja wszystkich"** zaznacza / odznacza całą listę.
- Każda pozycja pokazuje nazwę i ID części w Part-DB.

### Dialog potwierdzenia

Przed wysłaniem pojawia się dialog z podglądem przypisań:

```
Nadaj IPN:
  Kondensator 10µF  →  3 847 291
  ...

[Anuluj]  [Zatwierdź]
```

### Ekran wyników

Po zatwierdzeniu każda pozycja otrzymuje status:

- **✅** – IPN nadany pomyślnie
- **❌** – błąd (np. kolizja na serwerze, problem sieciowy)

---

## Algorytm generowania IPN

1. Aplikacja zbiera zbiór wszystkich **istniejących IPN** z pobranych części.
2. Dla każdej zaznaczonej części losuje liczbę z zakresu `1 000 000 – 9 999 999`.
3. Sprawdza kolizję zarówno z istniejącymi IPN, jak i z już wygenerowanymi w tej sesji.
4. Powtarza losowanie do skutku (bez limitu iteracji – kolizje są skrajnie rzadkie).

---

## Szczegóły techniczne

Nadanie IPN:
```
PATCH /api/parts/{id}
Content-Type: application/merge-patch+json

{ "ipn": "3847291" }
```

Po zakończeniu sesji lista jest odświeżana automatycznie.
