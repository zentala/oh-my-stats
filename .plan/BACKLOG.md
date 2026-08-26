# Backlog

- [x] **`Show-SystemStats` kosztował 1458-1763ms na starcie profilu** —
  naprawione 2026-08-26. Zmierzone `Measure-Command { Show-SystemStats }`:
  **1458-1763ms przed, 187ms po**. Znalezione przy diagnozowaniu 4,2s startu
  PowerShella w `oh-my-pwsh` (ten moduł jest tam importowany i wołany na
  starcie profilu) — pełny kontekst:
  `C:\code\oh-my-pwsh\.plan\epics\E001-profile-startup\HANDOFF.md`.

  **Pierwotna diagnoza w tym wpisie była błędna** i zostaje tu zapisana, żeby
  nie powtórzyć pomyłki: napisałem, że problemem są „duplikaty
  `Win32_OperatingSystem`/`Win32_Processor` liczone dwa razy". Nie są — te
  pary leżą w **wykluczających się gałęziach** `if (cache hit)` / `else`,
  więc zawsze wykonuje się tylko jedna z nich. Prawdziwe źródła, zmierzone
  stoperem wewnątrz funkcji:

  | Źródło | Przed | Po |
  |---|---|---|
  | `Win32_Processor.LoadPercentage` (WMI próbkuje CPU wewnątrz providera) | ~1050ms | — |
  | `Get-CimInstance Win32_OperatingSystem` bez projekcji właściwości | ~450ms | ~33ms |
  | `Get-CimInstance Win32_Processor` bez projekcji właściwości | ~35ms | ~8ms |
  | dwie próbki `Win32_PerfRawData_PerfOS_Processor` + 100ms odstępu | — | ~155ms |

  Fix: (1) `-Property` na każdym `Get-CimInstance` — odpytanie całej klasy WMI
  kosztuje rząd wielkości więcej niż odpytanie czterech właściwości;
  (2) nowa funkcja `Get-CpuLoadPercent` liczy obciążenie z dwóch surowych
  próbek `Win32_PerfRawData_PerfOS_Processor` zamiast pytać o
  `LoadPercentage`. Wartości zgadzają się z WMI (70% vs 79% pod obciążeniem,
  31% na bezczynnej maszynie).

  **Pułapka, która kosztowała godzinę:** najpierw napisałem ten fix na
  `Get-Counter '\Processor(_Total)\% Processor Time'`, bo zmierzyłem go na
  „2ms". `Get-Counter` na tej maszynie **rzuca wyjątkiem** (`Internal
  performance counter API call failed`, błąd `c0000bb8` — zepsute liczniki
  wydajności Windows), więc mierzyłem czas cichej porażki i czytałem go jako
  szybki sukces. Każde wywołanie i tak leciało w fallback na `LoadPercentage`
  za 1050ms. Wniosek: **mierz zwracaną WARTOŚĆ, nie sam czas** —
  `-ErrorAction SilentlyContinue` zamienia awarię w ciszę nie do odróżnienia
  od wyniku.
  (Importance: Medium, Points: 3 — zrobione)

---

## Wydanie v1.1.0 (2026-08-26)

Kontekst: ostatni tag to `v1.0.0` (2025-10-06), od tego czasu **16 commitów**, w tym
dwa wydania funkcjonalne (fallback ikon Unicode, tryb bez Nerd Fontów) i dwa
wydajnościowe (`4bd372a`, `830b5e8`). `.github/workflows/release.yml` odpala się na
tagu `v*`: przechodzi testy na Windows/Linux/macOS, potem `softprops/action-gh-release`
tworzy wydanie z automatycznymi notatkami. Czyli wydanie = bump wersji + tag, reszta
dzieje się sama. Kolejność jest ważna: **testy wydajnościowe PRZED tagiem**, bo inaczej
wydajemy poprawkę, której nic nie pilnuje.

- [x] **Testy wydajnościowe zanim pójdzie tag** — dziś 68 testów Pester sprawdza, co
  moduł *wypisuje*, i ani jeden nie sprawdza, ile to *kosztuje*. Regresja z 280 ms z
  powrotem do 1,7 s przeszłaby przez CI na zielono.
  Asercja na milisekundy w CI jest krucha (runner GitHuba bywa dwa razy wolniejszy niż
  ta maszyna), więc test ma pilnować **zachowania, które gwarantuje wydajność**, a nie
  stopera. Mock `Get-CimInstance`/`Get-Process` w Pesterze i `Should -Invoke`:
  - `Show-SystemStats` **nigdy** nie pyta o `Win32_Processor` z `LoadPercentage`
    (to była ta jedna właściwość za ~1050 ms);
  - każde `Get-CimInstance` leci z `-Property` — zapytanie o całą klasę WMI kosztuje
    rząd wielkości więcej;
  - `Get-Process` wywołany **dokładnie raz**, nie dwa (`Should -Invoke -Times 1 -Exactly`);
  - `Get-PSDrive` nie wywołany w ogóle (jest `[System.IO.DriveInfo]`);
  - `Get-CpuLoadPercent` przy wyjątku z licznika zwraca `$null`, **nie `0`** — to jest
    test na „cisza nie znaczy sukces", pułapka opisana wyżej w tym pliku.
  Dodatkowo jeden test-stoper z górnym limitem (np. < 1500 ms przy trafieniu w cache)
  oznaczony `-Tag Performance` i **wyłączony z CI** — do ręcznego odpalenia na tej
  maszynie, żeby nie wywalał builda na wolnym runnerze.
  Plik: `tests/pwsh/performance.Tests.ps1`. (Importance: High, Points: 5 — zrobione
  2026-08-26, 30 testów.) Wszystkie asercje z listy powyżej są w pliku. Dodatkowo:
  prymitywy cache'u (`Test-CacheValid`, `Get-SystemInfoCache`, `Save-SystemInfoCache`)
  i cykl życia cache'u przez `Show-SystemStats`. Stoper siedzi w `Describe`
  `-Tag Performance`, wyłączonym gdy `$env:CI` jest ustawione, i **nie ma górnego
  limitu w ms** — asercja jest względna (ciepły < zimny), bo próg w milisekundach
  jest zależny od maszyny i zamienia się we flaka. Test `$HOME` jest podmieniany
  w zasięgu modułu, więc prawdziwy `~/.cache/oh-my-stats` nie jest ruszany.
  Przy pisaniu wyszło, że `Win32_PhysicalMemory` jako jedyne `Get-CimInstance` szło
  bez `-Property` — dopisane (`-Property Speed`).

- [x] **Wydać v1.1.0** — po powyższym. Wersja *minor*, nie *patch*: doszły funkcje
  (fallback ikon), nic nie zostało zepsute. Do zrobienia:
  1. `ModuleVersion` w `pwsh/oh-my-stats.psd1` → `1.1.0`;
  2. `version` w `config/default.json` → `1.1.0` (dziś oba trzymają `1.0.0` niezależnie
     od siebie — **sprawdzić, czy jakiś test pilnuje ich zgodności; jeśli nie, dopisać**,
     bo rozjazd tych dwóch liczb jest niewidoczny do momentu, aż ktoś zgłosi bug z
     „wersją 1.0.0" na kodzie 1.1.0);
  3. `CHANGELOG.md` — sekcja `[Unreleased]` mówi dziś tylko „Updated documentation",
     a naprawdę doszły: fallback ikon Unicode, tryb bez Nerd Fontów, czysty nagłówek,
     projekcja właściwości CIM, `Get-CpuLoadPercent`, `[System.IO.DriveInfo]`, jeden
     `Get-Process`. Sekcja `### Performance`: **1458–1763 ms → ~280 ms**;
  4. `git tag v1.1.0 && git push origin v1.1.0` — dalej robi CI.
  (Importance: Medium, Points: 2 — zrobione 2026-08-26.) Punkt 2: żaden test nie pilnował
  zgodności obu wersji — dopisany (`oh-my-stats.Tests.ps1`, „Should keep the config version
  in step with the module manifest").

- [x] **Zdecydować, czy publikujemy do PowerShell Gallery** — blok
  `publish-powershell-gallery` w `release.yml` jest zakomentowany i czeka na sekret
  `PSGALLERY_API_KEY`. Dopóki jest zakomentowany, „wydanie" znaczy tylko wpis na
  GitHubie: instalacja to `git clone`, nie `Install-Module`. Decyzja Pawła — jeśli tak,
  klucz idzie przez `password-broker`, nigdy do pliku. (Importance: Low, Points: 3)
  **Decyzja Pawła 2026-08-26: publikujemy.** Blok odkomentowany i naprawiony — miał dwa
  błędy, które wywaliłyby go przy pierwszym uruchomieniu: (1) `if:` na poziomie joba nie
  widzi `secrets`, więc warunek przeniesiony do kroku; (2) `Publish-Module -Path ./pwsh`
  pada, bo Gallery wymaga, żeby nazwa katalogu równała się nazwie modułu — job stage'uje
  moduł do katalogu `oh-my-stats/`. Do tego moduł nie dawał się zainstalować samodzielnie:
  szukał configu w `$PSScriptRoot/../config/`, którego w zainstalowanej paczce nie ma —
  teraz sprawdza obie ścieżki, a paczka niesie własną kopię `config/default.json`.
