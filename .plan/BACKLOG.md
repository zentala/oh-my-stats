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
