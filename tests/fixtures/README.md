# Test Fixtures - Typowe Konfiguracje Windows

Ten folder zawiera CSV z typowymi konfiguracjami systemów Windows używanymi w testach Pester.

## Pliki

### cpu-configs.csv
**14 różnych procesorów** pokrywających:
- Intel Core i3/i5/i7/i9 (generacje 8-13)
- Intel Xeon (server CPUs)
- AMD Ryzen 3/5/7/9 (seria 3000-7000)
- AMD Ryzen PRO
- AMD Threadripper
- Starsze CPUs (Core 2 Duo, AMD FX)
- Virtual machine CPUs
- Edge cases (bardzo długa nazwa)

**Kolumny:**
- `Type` - identyfikator testowy
- `Vendor` - Intel/AMD/Generic
- `Name` - pełna nazwa z WMI (jak w Win32_Processor.Name)
- `ExpectedShort` - oczekiwana skrócona nazwa po parsowaniu
- `Cores` - liczba rdzeni fizycznych
- `Threads` - liczba wątków logicznych
- `MaxClockSpeed` - MHz (jak w WMI)
- `Notes` - dodatkowe informacje

### windows-configs.csv
**10 różnych wersji Windows** pokrywających:
- Windows 11 (buildy 22000-26100)
- Windows 10 (buildy 18363-19045)
- Edycje: Home, Pro, Enterprise, Education
- Wersje: 20H2, 21H1, 21H2, 22H2, 23H2, 24H2
- Edge case: brak DisplayVersion (fallback detection)

**Kolumny:**
- `Type` - identyfikator testowy
- `Build` - numer buildu (jak w registry CurrentBuild)
- `DisplayVersion` - wersja wyświetlana (jak w registry DisplayVersion, może być puste)
- `Caption` - pełna nazwa (jak w Win32_OperatingSystem.Caption)
- `ExpectedVersion` - oczekiwana wersja (21H2, 22H2, etc.)
- `ExpectedEdition` - oczekiwana edycja (Windows 11 Pro, etc.)
- `ExpectedShort` - oczekiwany skrót (Win11 Pro, Win10 Home, etc.)
- `Notes` - dodatkowe informacje

### ram-configs.csv
**9 różnych konfiguracji RAM** pokrywających:
- Wielkości: 4GB, 8GB, 16GB, 32GB, 64GB, 128GB
- Typy: DDR3, DDR4, DDR5
- Scenariusze użycia: low (12%), medium (50%), high (75%), critical (88%)
- Edge case: brak Speed w WMI

**Kolumny:**
- `Type` - identyfikator testowy
- `TotalKB` - całkowita pamięć w KB (jak w Win32_OperatingSystem.TotalVisibleMemorySize)
- `FreeKB` - wolna pamięć w KB (jak w Win32_OperatingSystem.FreePhysicalMemory)
- `Speed` - prędkość MHz (jak w Win32_PhysicalMemory.Speed, może być puste)
- `ExpectedUsedGB` - oczekiwane użycie w GB
- `ExpectedTotalGB` - oczekiwany total w GB
- `ExpectedPercent` - oczekiwany procent użycia
- `ExpectedSpeedDisplay` - oczekiwany wyświetlany string (3200MHz lub DDR4)
- `Notes` - dodatkowe informacje

### disk-configs.csv
**8 różnych konfiguracji dysków** pokrywających:
- Rozmiary: 120GB, 256GB, 500GB, 1TB, 2TB, 4TB
- Fill levels: 25%, 50%, 75%, 90%, 97%
- Edge case: brak dostępu do dysku (permissions)

**Kolumny:**
- `Type` - identyfikator testowy
- `UsedBytes` - użyte bajty (jak w Get-PSDrive.Used)
- `FreeBytes` - wolne bajty (jak w Get-PSDrive.Free)
- `ExpectedUsedGB` - oczekiwane użycie w GB
- `ExpectedTotalGB` - oczekiwany total w GB
- `ExpectedPercent` - oczekiwany procent użycia
- `Notes` - dodatkowe informacje

## Jak Używać w Testach

### Przykład 1: Test CPU Detection

```powershell
Describe 'CPU Detection Tests' {
    BeforeAll {
        Import-Module ./pwsh/oh-my-stats.psd1 -Force
        $cpuConfigs = Import-Csv ./tests/fixtures/cpu-configs.csv
    }

    foreach ($config in $cpuConfigs) {
        Context "Testing $($config.Type)" {
            It "Should parse $($config.Name) to $($config.ExpectedShort)" {
                # Mock WMI data
                Mock Get-CimInstance {
                    [PSCustomObject]@{
                        Name = $config.Name
                        NumberOfCores = $config.Cores
                        NumberOfLogicalProcessors = $config.Threads
                        MaxClockSpeed = $config.MaxClockSpeed
                        LoadPercentage = 50
                    }
                } -ParameterFilter { $ClassName -eq 'Win32_Processor' }

                # Run CPU detection logic here
                # Assert: $actualShortName | Should -Be $config.ExpectedShort
            }
        }
    }
}
```

### Przykład 2: Test RAM Calculation

```powershell
Describe 'RAM Calculation Tests' {
    BeforeAll {
        $ramConfigs = Import-Csv ./tests/fixtures/ram-configs.csv
    }

    foreach ($config in $ramConfigs) {
        It "Should calculate $($config.Type) correctly" {
            # Mock OS data
            Mock Get-CimInstance {
                [PSCustomObject]@{
                    TotalVisibleMemorySize = $config.TotalKB
                    FreePhysicalMemory = $config.FreeKB
                }
            } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }

            # Mock RAM speed
            Mock Get-CimInstance {
                @([PSCustomObject]@{
                    Speed = if ($config.Speed) { $config.Speed } else { $null }
                })
            } -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' }

            # Run RAM calculation
            # Assert values match Expected* columns
        }
    }
}
```

## Dodawanie Nowych Konfiguracji

Aby dodać nową konfigurację testową:

1. Otwórz odpowiedni CSV w edytorze
2. Dodaj nowy wiersz z danymi
3. Wypełnij wszystkie kolumny (zachowaj format)
4. Zapisz plik
5. Testy automatycznie pokryją nowy przypadek przy następnym uruchomieniu

**Przykład dodania nowego CPU:**
```csv
Intel_i5_14th,Intel,"Intel(R) Core(TM) i5-14600K CPU @ 3.50GHz",i5-14600K,14,20,3500,Raptor Lake Refresh
```

## Zalecenia

- **Utrzymuj CSV aktualne** - dodawaj nowe popularne konfiguracje
- **Testuj edge cases** - dodawaj nietypowe scenariusze
- **Dokumentuj w Notes** - opisz co testuje dany wiersz
- **Używaj realistic data** - dane jak z prawdziwych systemów
- **Sprawdzaj Expected values** - upewnij się że są poprawne

## Pokrycie Testów

Obecne pliki CSV pokrywają:
- ✅ Najpopularniejsze procesory konsumenckie (2020-2024)
- ✅ Wszystkie edycje Windows 10/11
- ✅ Typowe konfiguracje RAM (4-128GB)
- ✅ Typowe rozmiary dysków (120GB-4TB)
- ⚠️ Nie pokrywa: Windows Server, starsze Windows (<10), egzotyczne CPU

Do rozważenia w przyszłości:
- Windows Server configurations
- Multi-CPU systems
- ARM processors (Snapdragon)
- Exotic RAM configs (mixed speeds, single channel)
