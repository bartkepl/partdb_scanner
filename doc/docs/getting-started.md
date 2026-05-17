# Pierwsze kroki

## Wymagania wstępne

### Serwer Part-DB

Aplikacja wymaga działającej instancji **Part-DB** dostępnej w tej samej sieci co urządzenie mobilne.

- Dokumentacja Part-DB: [https://docs.part-db.de](https://docs.part-db.de)
- Minimalna wersja Part-DB: z aktywnym REST API (Hydra/JSON-LD)
- Serwer musi być dostępny pod stałym adresem IP lub nazwą hosta

!!! tip "Lokalna sieć domowa"
    Wystarczy serwer działający na domowym NAS lub komputerze (np. przez Docker).
    Telefon i serwer muszą być w tej samej sieci Wi-Fi.

---

## Generowanie tokenu API

1. Zaloguj się do panelu Part-DB w przeglądarce.
2. Przejdź do **Ustawienia użytkownika → Tokeny API**.
3. Kliknij **Utwórz nowy token**, nadaj mu nazwę (np. `scanner`).
4. Skopiuj wygenerowany token – będzie potrzebny w kroku konfiguracji.

!!! warning "Uprawnienia tokenu"
    Token musi mieć uprawnienia do odczytu i zapisu części, partii, parametrów oraz załączników.
    Jeśli chcesz tylko przeglądać – wystarczy uprawnienie tylko do odczytu.

---

## Konfiguracja aplikacji

Po uruchomieniu aplikacji przejdź na ostatnią zakładkę (ikona koła zębatego) – **Konfiguracja**.

### 1. Adres serwera

Wpisz pełny adres bazowy serwera Part-DB, np.:

```
http://192.168.1.10:8000
```

lub przez HTTPS:

```
https://partdb.moja-domena.local
```

!!! note
    Nie dodawaj `/api` na końcu – aplikacja sama dopisuje ścieżki API.

### 2. Token API

Wklej token skopiowany z Part-DB lub skorzystaj z przycisku skanowania, aby zeskanować token QR kodem kreskowym.

Po wpisaniu tokenu kliknij **Sprawdź token** – aplikacja połączy się z serwerem i wyświetli informację o zalogowanym użytkowniku.

### 3. Powiększenie kamery

Suwak **Zoom kamery** (1.0× – 3.0×, domyślnie 2.0×) steruje powiększeniem podglądu podczas skanowania kodów kreskowych. Ustaw większą wartość dla małych kodów Data Matrix na szpulach SMD.

---

## Uprawnienia Android

Przy pierwszym uruchomieniu aplikacja poprosi o następujące uprawnienia:

| Uprawnienie | Do czego |
|-------------|----------|
| **Kamera** | Skanowanie kodów kreskowych i fotografowanie części |
| **Bluetooth** | Drukowanie na Niimbot D101 |
| **Pamięć** | Tymczasowy zapis pliku CSV przy eksporcie |

!!! info
    Na Androidzie 12+ Bluetooth wymaga uprawnień `BLUETOOTH_CONNECT` i `BLUETOOTH_SCAN`. Jeśli drukarka nie pojawia się na liście, sprawdź czy Bluetooth jest włączony i czy aplikacja ma wymagane uprawnienia w ustawieniach systemowych.

---

## Weryfikacja połączenia

Po konfiguracji:

1. Przejdź na zakładkę **Wyszukiwanie**.
2. Wpisz dowolną nazwę komponentu lub zeskanuj kod kreskowy.
3. Jeśli pojawią się wyniki – aplikacja jest poprawnie skonfigurowana.

Jeśli pojawi się błąd:

| Komunikat | Przyczyna | Rozwiązanie |
|-----------|-----------|-------------|
| `Connection refused` | Serwer niedostępny lub zły port | Sprawdź adres i port, ping z sieci Wi-Fi |
| `401 Unauthorized` | Zły lub wygasły token | Wygeneruj nowy token w Part-DB |
| `Timeout` | Serwer zbyt wolny lub brak zasięgu sieci | Sprawdź Wi-Fi, zwiększ limit czasu po stronie serwera |
| `SSL handshake failed` | Certyfikat HTTPS niezaufany | Użyj HTTP lub zainstaluj certyfikat CA |

---

## Pierwsze użycie

### Skanowanie komponentu

1. Kliknij ikonę skanera (prawy górny róg ekranu Wyszukiwanie).
2. Skieruj kamerę na kod Data Matrix lub QR na szpuli lub opakowaniu.
3. Jeśli kod zawiera 7-cyfrowy IPN – aplikacja otworzy bezpośrednio szczegóły części.
4. Dla innych kodów – aplikacja wykona wyszukiwanie pełnotekstowe.

### Szybka korekta stanu

Dla części z jedną lokalizacją magazynową przy wyniku wyszukiwania pojawi się przycisk szybkiej korekty (+/−). Nie ma potrzeby otwierać szczegółów.

### Drukowanie etykiety

1. Otwórz szczegóły części.
2. Kliknij ikonę drukarki.
3. Wybierz typ etykiety (szufladkowa lub szpulowa).
4. Sparuj drukarkę Niimbot D101 przez Bluetooth, jeśli nie jest jeszcze sparowana.
5. Wyślij wydruk.
