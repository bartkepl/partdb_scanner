# Przeglądarka kategorii

Ekran **Kategorie** pozwala przeglądać hierarchię kategorii Part-DB w formie drzewa i przechodzić do listy części należących do wybranej kategorii.

---

## Interfejs drzewa

```
▶ Kondensatory
▼ Rezystory
    ▶ SMD
    ▼ THT
        ─ 1/4W
        ─ 1/2W
▶ Półprzewodniki
```

- **▶** – kategoria zwinięta; kliknij, aby rozwinąć
- **▼** – kategoria rozwinięta; kliknij strzałkę, aby zwinąć
- **─** – kategoria bez podkategorii; kliknij nazwę, aby zobaczyć części

Kliknięcie **nazwy kategorii** (nie strzałki) przechodzi do listy części w tej kategorii.

---

## Lista części w kategorii

Ekran `_CategoryPartsPage` wyświetla:

- Wszystkie części przypisane bezpośrednio do wybranej kategorii
- Sortowanie alfabetyczne po nazwie
- Ikona ⚠ przy częściach z niskim stanem
- Kliknięcie pozycji otwiera [Szczegóły części](part-detail.md)

!!! note "Ładowanie kategorii"
    Wszystkie kategorie pobierane są jednorazowo przy pierwszym wejściu na zakładkę (max 200 wpisów, paginacja Hydra). Kategorie są cache'owane w pamięci na czas sesji.

---

## Szczegóły techniczne

Kategorie pobierane są przez:
```
GET /api/categories?itemsPerPage=200
```

Aplikacja śledzi, które węzły drzewa są rozwinięte (`Set<int> _expandedIds`) i renderuje listę rekurencyjnie. Każdy poziom wcięcia o 16 px w lewo.
