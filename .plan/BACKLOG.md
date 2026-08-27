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
  **Opublikowane 2026-08-26 14:32** — `Find-Module oh-my-stats` zwraca 1.1.0, a
  `Save-Module` + `Import-Module` z Gallery daje działające `Show-SystemStats`
  (sprawdzone lokalnie, nie tylko po zielonym jobie):
  https://www.powershellgallery.com/packages/oh-my-stats/1.1.0

---

## CI było czerwone na `main` (naprawione 2026-08-26)

Znalezione przy wydawaniu v1.1.0: tag nie mógł nic wydać, bo `release.yml` ma
`needs: test`, a job testowy padał. Cztery niezależne przyczyny, wszystkie
naprawione w tej samej sesji — spisane, bo trzy z nich to pułapki, które wrócą.

- [x] **Testy Windows-only leciały na Linuksie i macOS** (15 porażek) — Pester
  `Mock Get-CimInstance` wywala się na `CommandNotFoundException`, bo mock
  wymaga, żeby komenda istniała. Prawdziwy fakt pod spodem: **ten moduł jest
  wyłącznie windowsowy** (WMI/CIM, klucz rejestru z wersją Windows, dysk `C:`),
  a matryca CI i `docs/TESTING.md` twierdziły inaczej. Fix: `-Skip:(-not $IsWindows)`
  na każdym kontekście dotykającym danych systemowych, krok `Test Show-SystemStats`
  tylko na Windows, tabela w `docs/TESTING.md` poprawiona.
  (Importance: High, Points: 3)
- [x] **`brew install --cask powershell` nie istnieje** — `Cask 'powershell' is
  unavailable`. Został tylko `powershell@preview`. Krok był zbędny od początku:
  PowerShell jest preinstalowany na każdym runnerze GitHuba. Usunięty z trzech
  workflowów razem z apt-owym odpowiednikiem dla Linuksa.
  (Importance: High, Points: 1)
- [x] **`Invoke-Pester` bez `-CI` kończy się kodem 0 mimo porażek** — job
  świecił na zielono, gdy testy padały; padał dopiero krok obok. Dokładnie
  „cisza nie znaczy sukcesu". Dopisane `-CI` w `test-pwsh.yml` i `release.yml`.
  (Importance: High, Points: 1)
- [x] **`EnricoMi/publish-unit-test-result-action` dostaje 403** — `Resource not
  accessible by integration` na `/rest/checks/runs`. Domyślny `GITHUB_TOKEN` jest
  read-only; job dostał `permissions: checks: write` + `pull-requests: write`.
  (Importance: Medium, Points: 1)
- [x] **`softprops/action-gh-release` wywalał się na dwóch assetach o tej samej
  nazwie** — `Failed to upload release asset README.md. received status code 404`.
  Lista `files:` miała `pwsh/**` (a tam siedzi `pwsh/README.md`) ORAZ `README.md`
  z rootu; assety w release'ie są adresowane samą nazwą pliku, więc drugi upload
  trafiał w nieistniejący zasób. Job kończył się błędem, przez co
  `publish-powershell-gallery` (`needs: release`) był pomijany — release na
  GitHubie wyglądał na kompletny, a do Gallery nie szło nic. Fix: pliki wypisane
  pojedynczo, bez globów. (Importance: High, Points: 1)
- [x] **PSScriptAnalyzer traktował trzy świadome decyzje jak defekty** —
  `PSAvoidGlobalVars` (`$global:OhMyPwsh_UseNerdFonts` to uzgodniony handshake
  z oh-my-pwsh), `PSUseApprovedVerbs` (`Draw-ProgressBar`) i `PSUseSingularNouns`
  (`Show-SystemStats`) — dwie ostatnie to publiczne API od 1.0.0, nie do zmiany.
  Wykluczone przez `-ExcludeRule` z komentarzem dlaczego.
  (Importance: Medium, Points: 1)
- [x] **Stare testy kasowały prawdziwy `~/.cache/oh-my-stats`** — kontekst
  `Cache Functionality` liczył ścieżki z prawdziwego `$HOME` i robił na nich
  `Remove-Item -Recurse -Force`. Przepięte na sandbox `$HOME` (ten sam wzorzec,
  co w `performance.Tests.ps1`). Pułapka przy okazji: test `Should import without
  errors` **re-importuje moduł**, co odtwarza jego zakres z prawdziwym `$HOME` —
  wstrzyknięcie sandboxa musi się powtarzać w `BeforeEach`, nie tylko raz w
  `BeforeAll`. (Importance: High, Points: 2)

- [x] **Screenshot w README wisiał na martwej domenie** — `README.md:25` wskazywał
  na `cdn.zentala.io` (exit 6, brak DNS). Przepięte na `cdn.zentala.agency`
  (200, obrazek obejrzany — to faktycznie ten terminal). Przy okazji wyszło, że
  leżący lokalnie `screenshots/pwsh.png` **był zupełnie innym plikiem** —
  zrzutem strony zentala.agency z przeglądarki, nie terminala. Podmieniony na
  wersję z CDN-u i zacommitowany. (Importance: Medium, Points: 1)
- [x] **IconUri modułu zwracał 404 — Gallery pokazywał domyślną zaślepkę** —
  `pwsh/oh-my-stats.psd1:22` wskazywał na `screenshots/icon.png`, którego w repo
  nigdy nie było (katalog `screenshots/` w ogóle nie był śledzony). Potwierdzone
  na żywej stronie pakietu: `<img class="package-icon" src=".../packageDefaultIcon.svg">`.
  Dorysowany ikonka 256×256 (trzy paski postępu w kolorach modułu), zacommitowana,
  raw URL oddaje 200. **Do Gallery trafi dopiero z nowym wydaniem.**
  (Importance: Medium, Points: 2)
- [x] **Opis modułu kłamał o platformach** — `Description` mówił „Cross-platform”,
  a `Tags` niosły `Linux` i `macOS`, choć moduł czyta WMI/CIM i jest wyłącznie
  windowsowy (patrz wpis o matrycy testów wyżej). Opis przepisany na konkretny
  (co pokazuje, czym się konfiguruje, że cache trzyma to poza czasem startu,
  „Windows only”), tagi poprawione, te same fałszywe deklaracje wycięte z README
  (nagłówek, badge platformy, sekcja Features, nagłówki instalacji).
  (Importance: High, Points: 2)
- [x] **Wydane v1.1.1 — opis dotarł do Gallery, ikona nie (nie z naszej winy)** —
  tag `v1.1.1`, cała matryca zielona, `Publish-Module` wykonany naprawdę (klucz
  ustawiony, nie wpadło w gałąź „skipping"). Nowy opis widoczny na stronie pakietu.
  Ikona **dalej pokazuje `packageDefaultIcon.svg`** — i to nie jest nasz błąd:
  pobrany `.nupkg` niesie poprawny `<iconUrl>`, a **Pester i Terminal-Icons
  renderują dokładnie tę samą zaślepkę**, mimo że deklarują `iconUrl` w tej samej
  formie (`raw.githubusercontent`). Wniosek: strona pakietu w PowerShell Gallery
  nie renderuje dziś zdalnych ikon nikomu. Po naszej stronie nie ma czego naprawiać.
  Gdyby kiedyś miało to zadziałać, droga prowadzi przez ikonę **osadzoną w paczce**
  (`<icon>`, następca `<iconUrl>` w NuGecie), nie przez URL. (Importance: Low, Points: 3)
- [x] **README nie prowadził do Gallery, a instalacja zaczynała się od `git clone`** —
  po wydaniu v1.1.1 domyślną drogą jest `Install-Module`, a README nadal
  proponował „Method 1: Clone and Import" i „Method 2: Direct Download", oba
  przez `git clone`, i nie linkował strony pakietu ani jednym słowem. Kolejność
  odwrócona: Gallery jako pierwsza (z `Update-Module`), one-liner
  `irm .../install.ps1 | iex` jako alternatywa dla tych, którzy nie chcą Gallery,
  a klonowanie zeszło do CONTRIBUTING, bo jest dla kontrybutorów. Dodany badge
  `powershellgallery/v` (odpowiada 1.1.1). Badge'a z liczbą pobrań świadomie NIE
  dodałem — pokazuje dziś `0`. Zweryfikowane: `Find-Module oh-my-stats` → 1.1.1,
  `Save-Module` daje komplet plików (psd1/psm1/config/LICENSE/README), import tej
  kopii i `Show-SystemStats` rysuje banner. (Importance: High, Points: 2)
- [x] **`pwsh/README.md` — plik jadący W PACZCE — kłamał najbardziej** — czytają go
  ludzie po `Install-Module`, a mówił „cross-platform", „PowerShell Gallery
  (Coming Soon)" i pokazywał konfigurację przez `$OhMyStatsConfig` z kluczem
  `Theme`, których w module NIE MA (grep: zero trafień). Blok zastąpiony prawdziwymi
  kluczami z `config/default.json` i `-ConfigPath`. Dwa linki relatywne
  (`../docs/CONTRIBUTING.md`) zamienione na URL-e — w paczce nie ma katalogu `docs/`,
  więc nie prowadziły donikąd. (Importance: High, Points: 2)
- [ ] **Flaky test: `$warm | Should -BeLessThan $cold`** —
  `tests/pwsh/performance.Tests.ps1:306` porównuje dwa pomiary zegara bez marginesu.
  Jeden z czterech przebiegów dziś dał 98/1; trzy kolejne 99/0. Na obciążonym
  runnerze będzie losowo czerwienić CI, a czerwony przebieg bez przyczyny uczy
  ignorować testy. Fix: margines (np. `$warm | Should -BeLessThan ($cold * 0.9)`)
  albo mediana z kilku pomiarów zamiast pojedynczego. (Importance: Medium, Points: 2)
- [ ] **`Draw-ProgressBar` — nieapprowany czasownik, ostrzeżenie przy każdym imporcie** —
  `Import-Module oh-my-stats` z Gallery wypisuje WARNING o „unapproved verbs".
  Widzi to każdy użytkownik przy starcie shella. `Draw` nie jest na liście `Get-Verb`.
  Rekomendacja: `Write-ProgressBar` jako nazwa właściwa + `Draw-ProgressBar` jako
  alias, żeby nie zepsuć nikomu profilu; to zmiana publicznego API, więc decyzja
  Pawła, nie auto-fix. (Importance: Medium, Points: 3)
- [ ] **`pawel@zentala.agency` niezweryfikowany** — `docs/CONTRIBUTING.md:226`,
  podmieniony z `pawel@zentala.io` razem z CDN-em. Sprawdzone jest tylko to, że
  domena `zentala.agency` odpowiada po HTTP; czy skrzynka pod tym adresem
  odbiera pocztę — nie. (Importance: Medium, Points: 1)
