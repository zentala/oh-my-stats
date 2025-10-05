# TODO - Windows Release Checklist

## Kolejność Wykonania

1. **Error Handling** (Priority 2) - najpierw stabilność
2. **Pester Tests z mockami** (Priority 3) - używając CSV fixtures
3. **Manual Testing** (Priority 1) - testy na prawdziwych systemach

## Test Fixtures (CSV)

Stworzone pliki z typowymi konfiguracjami:
- `tests/fixtures/cpu-configs.csv` - 14 różnych CPU (Intel i3/i5/i7/i9, AMD Ryzen, Xeon, Threadripper)
- `tests/fixtures/windows-configs.csv` - 10 różnych Windows (Win10/11, różne buildy, edycje)
- `tests/fixtures/ram-configs.csv` - 9 różnych RAM (4GB-128GB, DDR3/4/5, różne usage)
- `tests/fixtures/disk-configs.csv` - 8 różnych dysków (120GB-4TB, różne fill levels)

**Jak używać w testach Pester:**
```powershell
$cpuConfigs = Import-Csv ./tests/fixtures/cpu-configs.csv

foreach ($config in $cpuConfigs) {
    It "Should detect $($config.Type) correctly" {
        Mock Get-CimInstance {
            [PSCustomObject]@{
                Name = $config.Name
                NumberOfCores = $config.Cores
                NumberOfLogicalProcessors = $config.Threads
                MaxClockSpeed = $config.MaxClockSpeed
            }
        } -ParameterFilter { $ClassName -eq 'Win32_Processor' }

        # Test CPU detection logic
        $result = Show-SystemStats -NoModuleStatus
        # Assert expectations
    }
}
```

Z czasem można dodawać nowe wiersze do CSV - testy automatycznie pokryją nowe przypadki.

---

## Priority 1 - Critical dla Release (MUST HAVE)

### Testowanie CPU Compatibility
- [ ] **Intel CPUs** - Przetestować wykrywanie na:
  - [ ] Intel Core i3 (8th-14th gen) - regex `i(\d)-(.\d{4,5}\w*)`
  - [ ] Intel Core i5 (8th-14th gen)
  - [ ] Intel Core i7 (8th-14th gen) ✅ (tested on i7-8750H)
  - [ ] Intel Core i9 (12th-14th gen)
  - [ ] Intel Xeon (Server CPUs)
  - [ ] Starsze Intel (Core 2 Duo, Pentium) - fallback scenario

- [ ] **AMD CPUs** - Przetestować wykrywanie na:
  - [ ] AMD Ryzen 3 (seria 3000-7000)
  - [ ] AMD Ryzen 5 (seria 3000-7000)
  - [ ] AMD Ryzen 7 (seria 3000-7000)
  - [ ] AMD Ryzen 9 (seria 5000-7000)
  - [ ] AMD Ryzen PRO (business line)
  - [ ] AMD Threadripper (HEDT)
  - [ ] Starsze AMD (FX, Athlon) - fallback scenario

- [ ] **Edge Cases**:
  - [ ] CPU z nazwą > 30 znaków (sprawdzić substring logic line 150-152)
  - [ ] CPU bez MaxClockSpeed w WMI
  - [ ] Systemy wieloprocesorowe (więcej niż 1 CPU)
  - [ ] VM/Hyper-V (często mają dziwne nazwy CPU)

### Testowanie Windows Versions
- [ ] **Windows 11** - Przetestować na:
  - [ ] Build 22000 (21H2) - pierwsza wersja Win11
  - [ ] Build 22621 (22H2)
  - [ ] Build 22631 (23H2) - obecna wersja
  - [ ] Build 26xxx (24H2 preview)

- [ ] **Windows 10** - Przetestować na:
  - [ ] Build 19042 (20H2)
  - [ ] Build 19044 (21H2)
  - [ ] Build 19045 (22H2) - ostatnia wersja Win10

- [ ] **Windows Editions**:
  - [ ] Home (regex match line 164)
  - [ ] Pro (regex match line 165)
  - [ ] Enterprise (line 166)
  - [ ] Education (line 167)
  - [ ] Pro for Workstations

### Testowanie RAM Configurations
- [ ] **Różne typy RAM**:
  - [ ] DDR3 (starsze systemy)
  - [ ] DDR4 (większość obecnych)
  - [ ] DDR5 (nowsze systemy)
  - [ ] Brak Speed w WMI (fallback "DDR4" line 99)

- [ ] **Różne wielkości**:
  - [ ] 4GB RAM (sprawdzić wyświetlanie)
  - [ ] 8GB RAM
  - [ ] 16GB RAM
  - [ ] 32GB RAM
  - [ ] 64GB+ RAM (sprawdzić formatowanie)

- [ ] **Edge Cases**:
  - [ ] Mixed RAM (różne prędkości) - pokaże pierwszą
  - [ ] Single channel vs Dual channel

### Testowanie Disk Configurations
- [ ] **Różne typy dysków**:
  - [ ] HDD tradycyjny
  - [ ] SSD SATA
  - [ ] NVMe SSD
  - [ ] M.2 SSD

- [ ] **Różne rozmiary C:**:
  - [ ] < 100GB (mały dysk)
  - [ ] 100-500GB (typowy)
  - [ ] 500GB-1TB
  - [ ] 1TB-2TB
  - [ ] 2TB+ (sprawdzić formatowanie)

- [ ] **Edge Cases**:
  - [ ] C: prawie pełny (>95%) - sprawdzić progress bar
  - [ ] Brak dostępu do C: (permissions)
  - [ ] C: jako dysk sieciowy (mapped drive)

## Priority 2 - Error Handling (DO FIRST) ✅ DONE

All error handling implemented and tested.

---

## Priority 2.5 - Performance Optimization (CRITICAL)

**Problem:** Module load takes ~5s, target is <1s

**Root cause:** Query'owanie danych które się nie zmieniają przy każdym uruchomieniu:
- Get-CimInstance Win32_OperatingSystem (~1s)
- Get-CimInstance Win32_Processor (~1s)
- Get-CimInstance Win32_PhysicalMemory (~0.5s)
- Get-ItemProperty registry 2x (~0.5s)
- Get-Counter CPU load (~1s)

**Solution:** Cache static data, query tylko dynamic data

### Data Classification

**STATIC (cache, nie zmienia się):**
- OS version (Windows 11 Home 24H2)
- OS build number (26100)
- CPU name (Intel Core i7-8750H)
- CPU cores (6)
- CPU threads (12)
- CPU base speed (2.2 GHz)
- RAM total (32 GB)
- RAM speed (2667 MHz)
- Disk total (930 GB)
- Architecture (x64)

**DYNAMIC (query zawsze):**
- CPU load % (zmienia się co sekundę)
- RAM used % (zmienia się)
- Disk used % (zmienia się)
- Process count (zmienia się)
- Terminal count (zmienia się)
- Uptime (zmienia się)

### Cache Architecture

**Cache file location:**
```powershell
$cacheDir = Join-Path $HOME ".cache/oh-my-stats"
$cacheFile = Join-Path $cacheDir "system-info.json"
```

**Cache structure:**
```json
{
  "version": "1.0",
  "cached_at": "2025-01-06T12:34:56Z",
  "system": {
    "os_name": "Windows 11 Home",
    "os_short": "Win11 Home",
    "os_version": "24H2",
    "os_build": "26100",
    "os_architecture": "x64"
  },
  "cpu": {
    "name": "Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz",
    "short_name": "i7-8750H",
    "cores": 6,
    "threads": 12,
    "base_speed_ghz": 2.2
  },
  "ram": {
    "total_gb": 32.0,
    "speed": "2667MHz"
  },
  "disk": {
    "total_gb": 930
  }
}
```

**Cache validation:**
- Check if file exists
- Check if `cached_at` < 7 days old
- If invalid: regenerate

**Implementation steps:**

1. **Add cache functions:**
   - `Get-SystemInfoCache()` - load from cache if valid
   - `Save-SystemInfoCache($data)` - save to cache
   - `Test-CacheValid($cacheFile)` - check if cache usable

2. **Modify Show-SystemStats:**
   ```powershell
   # Try to load from cache
   $cached = Get-SystemInfoCache

   if ($cached) {
       # Use cached static data
       $cpuName = $cached.cpu.name
       $cpuShort = $cached.cpu.short_name
       # ... etc

       # Query only dynamic data
       $cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
       # ... only dynamic queries
   } else {
       # Cache miss - query everything and save
       # ... existing logic
       Save-SystemInfoCache $data
   }
   ```

3. **Add cache invalidation:**
   - `-RefreshCache` switch parameter
   - Delete cache file to force refresh

### Expected Performance

**Before (without cache):**
- Total: ~3s
- CIM queries: ~2s
- Registry: ~0.3s
- Counter: ~0.5s
- Other: ~0.2s

**After (with cache) - ACTUAL RESULTS:**
- Cache hit: **~1.6-1.8s** (44% faster!)
  - Module import: ~0.1s
  - Load cache: <0.01s
  - Query Win32_OperatingSystem (for dynamic RAM): ~0.5s
  - Query Win32_Processor (for CPU load): ~0.5s
  - Query Get-PSDrive (for disk usage): ~0.2s
  - Query Get-Process (2x): ~0.2s
  - Display: ~0.1s
- Cache miss: ~2.9s (generates cache for next run)

**Note:** Target was <1s, achieved 1.6-1.8s. To reach <1s would require:
- Parallelizing dynamic queries (complex, may reduce reliability)
- Using alternative data sources (may reduce accuracy)
- Current implementation prioritizes reliability over absolute speed

### Tasks

- [x] Create cache directory structure
- [x] Implement `Get-SystemInfoCache` function
- [x] Implement `Save-SystemInfoCache` function
- [x] Implement `Test-CacheValid` function
- [x] Modify `Show-SystemStats` to use cache
- [x] Add `-RefreshCache` parameter
- [x] Test cache hit performance (~1.6-1.8s, 44% improvement)
- [x] Test cache miss performance (~2.9s, generates cache)
- [ ] Test cache invalidation after 7 days
- [ ] Document cache behavior in README

---

## Priority 2 - Error Handling (DO FIRST) ✅ DONE (kept for history)

### 1. CIM Queries Protection (oh-my-stats.psm1:81-116)
- [ ] **Wrap Get-CimInstance Win32_OperatingSystem** (line 81):
  ```powershell
  try {
      $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
  } catch {
      Write-Error "Cannot access system information. Run as Administrator or check WMI service."
      return
  }
  ```

- [ ] **Wrap Get-CimInstance Win32_Processor** (line 82):
  ```powershell
  try {
      $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
  } catch {
      Write-Error "Cannot access CPU information: $_"
      return
  }
  ```

- [ ] **Wrap Get-CimInstance Win32_PhysicalMemory** (line 83):
  ```powershell
  try {
      $mem = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop
  } catch {
      Write-Warning "Cannot get RAM speed information, using default"
      $mem = $null
  }
  ```

### 2. Registry Access Protection (line 157-158)
- [ ] **Wrap registry queries**:
  ```powershell
  try {
      $winBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction Stop).CurrentBuild
      $winVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction Stop).DisplayVersion
  } catch {
      Write-Warning "Cannot access registry, using fallback Windows detection"
      $winBuild = "Unknown"
      $winVer = "Unknown"
  }
  ```

### 3. Performance Counter Protection (line 86-89)
- [ ] **Dodać fallback dla Get-Counter**:
  ```powershell
  $cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
  if (-not $cpuLoad -or $cpuLoad -eq 0) {
      try {
          $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop).CounterSamples.CookedValue
      } catch {
          Write-Verbose "Performance counters unavailable, using 0%"
          $cpuLoad = 0
      }
  }
  $cpuLoad = [math]::Round($cpuLoad, 0)
  ```

### 4. Disk Access Protection (line 102)
- [ ] **Wrap Get-PSDrive**:
  ```powershell
  try {
      $disk = Get-PSDrive C -ErrorAction Stop
      $diskUsed = [math]::Round($disk.Used / 1GB, 0)
      $diskTotal = [math]::Round(($disk.Used + $disk.Free) / 1GB, 0)
      $diskPercent = [math]::Round($disk.Used / ($disk.Used + $disk.Free) * 100, 0)
  } catch {
      Write-Verbose "Cannot access C: drive"
      $disk = $null
      $diskUsed = 0
      $diskTotal = 0
      $diskPercent = 0
  }
  ```

### 5. Null-Safe CPU Detection (line 119-122)
- [ ] **Dodać sprawdzenie przed użyciem**:
  ```powershell
  if ($cpu) {
      $cpuName = $cpu.Name
      $cpuCores = $cpu.NumberOfCores
      $cpuThreads = $cpu.NumberOfLogicalProcessors
      $cpuSpeed = [math]::Round($cpu.MaxClockSpeed / 1000, 1)
  } else {
      $cpuName = "Unknown CPU"
      $cpuCores = 0
      $cpuThreads = 0
      $cpuSpeed = 0
  }
  ```

### Config Validation
- [ ] **Dodać walidację config.json przy ładowaniu**:
  - [ ] Sprawdzić czy wszystkie required keys istnieją
  - [ ] Sprawdzić czy hex codes są poprawne
  - [ ] Sprawdzić czy kolory są valid PowerShell colors
  - [ ] Dodać friendly error message jeśli config corrupted

- [ ] **Dodać fallback jeśli config.json brakuje**:
  - [ ] Hardcoded defaults w module
  - [ ] Komunikat o stworzeniu domyślnego config

### Performance
- [ ] **Zmierzyć czas wykonania** na różnych systemach:
  - [ ] HDD vs SSD (może wpłynąć na Get-CimInstance)
  - [ ] Stary CPU vs nowy
  - [ ] Target: < 3s zawsze

- [ ] **Zoptymalizować jeśli > 3s**:
  - [ ] Cache'ować config przy module load
  - [ ] Równoległe query dla CPU/RAM/Disk jeśli możliwe

## Priority 3 - Pester Tests (DO SECOND)

### Setup Test Infrastructure
- [ ] **Stworzyć test file**: `tests/pwsh/cpu-detection.Tests.ps1`
- [ ] **Stworzyć test file**: `tests/pwsh/windows-detection.Tests.ps1`
- [ ] **Zaktualizować**: `tests/pwsh/oh-my-stats.Tests.ps1` z error handling tests

### CPU Detection Tests (używając csv)
- [ ] **Test wszystkich CPU z fixtures**:
  ```powershell
  Describe 'CPU Detection from Fixtures' {
      BeforeAll {
          Import-Module ./pwsh/oh-my-stats.psd1 -Force
          $cpuConfigs = Import-Csv ./tests/fixtures/cpu-configs.csv
      }

      foreach ($config in $cpuConfigs) {
          Context "Testing $($config.Type)" {
              It "Should detect $($config.Name) as $($config.ExpectedShort)" {
                  # Mock CIM data
                  Mock Get-CimInstance {
                      [PSCustomObject]@{
                          Name = $config.Name
                          NumberOfCores = $config.Cores
                          NumberOfLogicalProcessors = $config.Threads
                          MaxClockSpeed = $config.MaxClockSpeed
                          LoadPercentage = 50
                      }
                  } -ParameterFilter { $ClassName -eq 'Win32_Processor' }

                  # Extract CPU short name logic
                  $cpuName = $config.Name
                  # Run regex matching from module
                  # Assert $cpuShort -eq $config.ExpectedShort
              }
          }
      }
  }
  ```

### Windows Version Tests (używając csv)
- [ ] **Test wszystkich Windows z fixtures**:
  ```powershell
  Describe 'Windows Version Detection from Fixtures' {
      BeforeAll {
          $windowsConfigs = Import-Csv ./tests/fixtures/windows-configs.csv
      }

      foreach ($config in $windowsConfigs) {
          It "Should detect Build $($config.Build) as $($config.ExpectedVersion)" {
              # Mock registry data
              Mock Get-ItemProperty {
                  [PSCustomObject]@{
                      CurrentBuild = $config.Build
                      DisplayVersion = $config.DisplayVersion
                  }
              } -ParameterFilter { $Path -like '*Windows NT*' }

              # Run detection logic
              # Assert version matches expected
          }
      }
  }
  ```

### Helper Functions Tests
- [ ] **Test Draw-ProgressBar**:
  - [ ] 0% -> Green bar, all empty
  - [ ] 50% -> Green bar, half full
  - [ ] 70% -> Yellow bar
  - [ ] 90% -> Red bar
  - [ ] 100% -> Red bar, all full

- [ ] **Test Get-Icon**:
  - [ ] Small hex (0xF000) -> should use [char]
  - [ ] Large hex (0x1F4A9) -> should use ConvertFromUtf32
  - [ ] Invalid hex -> should handle error

### Error Handling Tests
- [ ] **Test graceful failures**:
  - [ ] WMI service down -> should show error message
  - [ ] Registry access denied -> should use fallback
  - [ ] C: drive inaccessible -> should skip disk module
  - [ ] Performance counters disabled -> should use 0%

### Documentation
- [ ] **Dodać do README**:
  - [ ] Sekcja Troubleshooting
    - Nerd Fonts nie zainstalowane
    - PowerShell < 7.0
    - Brak uprawnień do CIM
  - [ ] Compatibility Matrix - jakie Windows tested
  - [ ] FAQ - częste pytania

- [ ] **Dodać przykłady config customization**:
  - [ ] Jak zmienić kolory
  - [ ] Jak wyłączyć moduły
  - [ ] Jak zmienić szerokość progress bar

### Features
- [ ] **Dodać `-Verbose` support** dla debugowania
- [ ] **Dodać `-AsObject`** - zwraca dane zamiast drukować
- [ ] **Dodać `-NoColor`** - bez ANSI codes (dla redirects)

## Testowanie Matrix - Co User Może Mieć

### Typowe Konfiguracje Windows (Desktop/Laptop)
1. **Gaming PC**:
   - Intel i7/i9 lub AMD Ryzen 7/9
   - 16-32GB DDR4/DDR5
   - NVMe SSD 500GB-1TB
   - Windows 11 Pro/Home

2. **Office Laptop**:
   - Intel i5 lub AMD Ryzen 5
   - 8-16GB DDR4
   - SATA SSD 256-512GB
   - Windows 10/11 Pro

3. **Budget/Old PC**:
   - Intel i3 lub starszy i5/i7
   - 4-8GB DDR3/DDR4
   - HDD lub mały SSD
   - Windows 10 Home

4. **Workstation**:
   - Intel Xeon lub AMD Threadripper
   - 32-128GB RAM
   - Multiple drives, RAID
   - Windows 11 Pro for Workstations

5. **Virtual Machine**:
   - Generic CPU name w WMI
   - Dynamiczny RAM
   - Thin provisioned disk
   - Windows Server lub Desktop

### Edge Cases Windows
- **Języki systemu**: Polski, angielski, inny (performance counters!)
- **Regional settings**: Separatory liczb, formaty dat
- **Permissions**: User vs Admin (wpływ na registry/CIM)
- **Corporate environment**: Group Policy restrictions, antivirus
- **Windows Server**: 2019, 2022 (trochę inne WMI data)

## Jak Testować Bez Wszystkich Konfiguracji

### 1. Mock Testing w Pester
Stworzyć mock data dla różnych scenariuszy:
```powershell
$mockCPU = [PSCustomObject]@{
    Name = "Intel(R) Core(TM) i9-13900K CPU @ 3.00GHz"
    NumberOfCores = 24
    NumberOfLogicalProcessors = 32
    MaxClockSpeed = 3000
    LoadPercentage = 45
}

Mock Get-CimInstance { return $mockCPU } -ParameterFilter { $ClassName -eq 'Win32_Processor' }
```

### 2. Community Testing
- [ ] Stworzyć GitHub Issue: "Help test on your system"
- [ ] Template z `$PSVersionTable`, CPU model, Windows version
- [ ] Prosić o screenshot output

### 3. VM Testing (Optional)
- [ ] Windows 10 VM
- [ ] Windows 11 VM
- [ ] Windows Server VM

## Release Readiness Checklist

Przed tagowaniem v1.0.0:
- [ ] Wszystkie Priority 1 items zrobione
- [ ] Testy Pester: minimum 80% pass rate
- [ ] Przetestowane na min 3 różnych systemach Windows
- [ ] README updated z compatibility notes
- [ ] CHANGELOG.md updated
- [ ] GitHub Actions przechodzą na wszystkich jobs
- [ ] Module version w .psd1 ustawiony na 1.0.0

---

**Szacowany czas do release-ready Windows version: 6-8 godzin**

- Priority 1: 3-4h (głównie manual testing + fixes)
- Priority 2: 2-3h (error handling + validation)
- Priority 3: 1-2h (Pester tests + docs)
