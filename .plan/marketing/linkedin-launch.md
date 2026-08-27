# LinkedIn — premiera oh-my-stats

## TLDR

Szkic posta na LinkedIn o `oh-my-stats`. Kąt: nie „zrobiłem narzędzie", tylko
„kazałem trzem agentom zrecenzować własny projekt i znaleźli rzecz, której człowiek
nie ma jak zobaczyć". Do decyzji: publikować teraz czy po naprawieniu znalezisk High
z `.plan/BACKLOG.md` (rekomendacja: po).

---

## Wersja A — „zły plik w paczce" (rekomendowana)

Wydałem mały moduł do PowerShella. Pokazuje w terminalu obciążenie CPU, RAM-u
i dysku — paski, ikony, jedna linijka w profilu. Nic odkrywczego.

Ciekawe zaczęło się, kiedy zamiast klepnąć „gotowe", puściłem na niego trzech
agentów z trzema różnymi pytaniami: co widzi użytkownik, co widzi programista,
i czy to w ogóle ma sens wobec konkurencji.

Najlepsze znalezisko było takie, którego sam bym nie zobaczył nigdy.

Do PowerShell Gallery jechał **zły README**. Repo ma dwa: jeden dla GitHuba,
z linkami do folderu `docs/`, i drugi, celowo napisany dla paczki — z pełnymi
adresami, bo zainstalowany moduł nie ma żadnego `docs/`. Skrypt wydania kopiował
ten pierwszy. Czyli: każdy, kto zainstalował moduł i chciał doczytać o konfiguracji,
klikał w link donikąd.

Na GitHubie wyglądało to bez zarzutu. Testy zielone. Wydanie zielone. Paczka na
Gallery. Jedno miejsce, w którym to było widać, to plik, którego nikt nie ogląda —
osiem linijek YAML-a w środku workflow.

Drugi agent zmierzył coś, o czym README twierdziło od roku: „~1.6 s startu".
Naprawdę jest 0,28 s. Sześć razy szybciej, niż sam o sobie pisałem — bo liczba
została wpisana raz, przy optymalizacji, i nigdy więcej nie sprawdzona.

Trzeci powiedział mi rzecz najmniej przyjemną: winfetch robi to samo od lat
i robi więcej. Miał rację.

Wniosek, który zabieram dalej: **dokumentacja psuje się cicho.** Nie ma testu,
który by to złapał, nie ma czerwonego znaczka, nikt nie zgłosi buga w linku
w README paczki, którą zainstalował raz. Kod ma CI. Prawda o kodzie nie ma nic.

Link do projektu w komentarzu.

---

## Wersja B — krótsza, bez agentów (gdyby wątek AI się przejadł)

„~1.6 s startu" — tak README mojego modułu opisywało go od roku.

Zmierzyłem wczoraj: 0,28 s.

Liczba trafiła do dokumentacji raz, przy optymalizacji, i została. Nic jej nie
pilnowało, bo dokumentacji nic nie pilnuje. Testy sprawdzają, czy kod robi to,
co ma robić. Nikt nie sprawdza, czy plik obok mówi o nim prawdę.

Przy okazji znalazłem, że do paczki w PowerShell Gallery jechał nie ten README,
co trzeba — użytkownicy po instalacji dostawali linki do folderu, którego paczka
nie zawiera. Na GitHubie wszystko wyglądało dobrze.

Dokumentacja psuje się cicho i nikt tego nie zgłasza.

---

## Notatki do publikacji

- **Kiedy:** dopiero po naprawieniu pozycji High z `.plan/BACKLOG.md` (zepsuty
  `config.json` wywalający terminal, martwe klucze `thresholds`/`performance`,
  Nerd Font). Post prowadzi ruch do repo; nie ma sensu prowadzić go do znanych bugów.
- **Screenshot:** obowiązkowy, to jest ta kategoria narzędzi. Dziś mamy
  `https://cdn.zentala.agency/terminal/pwsh.png`. Lepszy będzie po dodaniu logo
  (backlog) — do rozważenia, czy nie poczekać z postem na tamto.
- **Link:** w komentarzu, nie w treści — LinkedIn tnie zasięg postom z linkiem
  wychodzącym. NIESPRAWDZONE, powtarzam za powszechną praktyką, nie za pomiarem.
- **Wersja angielska:** warta zrobienia osobno, bo publiczność narzędzi
  terminalowych jest anglojęzyczna. Nie tłumaczyć zdanie w zdanie.
