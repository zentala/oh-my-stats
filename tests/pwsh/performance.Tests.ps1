<#
    Performance tests for the system-info cache.

    Speed itself is not asserted in CI: wall-clock on a shared runner is noise, and a
    test that fails on a slow morning teaches nothing. What IS asserted is the
    behaviour that makes the module fast - on a cache hit the static queries
    (Win32_PhysicalMemory, the Windows version registry key, the second Win32_Processor
    call) must not run at all, while the dynamic ones still must.

    The stopwatch lives in its own Describe, tagged 'Performance', and is skipped when
    $env:CI is set. Run it locally with:
        Invoke-Pester ./tests/pwsh/performance.Tests.ps1 -Output Detailed

    The module reads its cache path from $HOME, so every test here runs against a
    throwaway $HOME injected into the module scope. The real ~/.cache/oh-my-stats is
    never read, written, or deleted.
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "../../pwsh/oh-my-stats.psd1"
    Import-Module $modulePath -Force

    $script:SandboxHome = Join-Path ([IO.Path]::GetTempPath()) "oh-my-stats-tests-$([guid]::NewGuid())"
    $script:CacheDir    = Join-Path $script:SandboxHome ".cache/oh-my-stats"
    $script:CacheFile   = Join-Path $script:CacheDir "system-info.json"

    # Point the module's $HOME at the sandbox. Module scope wins over global scope,
    # so Get-/Save-SystemInfoCache resolve their paths inside the temp directory.
    & (Get-Module oh-my-stats) { param($SandboxHome) $script:HOME = $SandboxHome } $script:SandboxHome

    function New-FakeStaticData {
        @{
            CPU  = @{ Name = 'Test CPU'; ShortName = 'Test'; Cores = 4; Threads = 8; Speed = 3.5 }
            RAM  = @{ Total = 16; Speed = '3200MHz' }
            Disk = @{ Total = 500 }
            OS   = @{ Short = 'Win11 Pro'; Version = '23H2'; Edition = 'Windows 11 Pro'; Icon = '0xF17A' }
        }
    }

    function Reset-Cache {
        Remove-Item $script:CacheDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # A warm cache written by the module itself, so the shape always matches what it reads.
    function Set-WarmCache {
        & (Get-Module oh-my-stats) { param($Data) Save-SystemInfoCache -SystemInfo $Data } (New-FakeStaticData)
    }
}

AfterAll {
    Remove-Item $script:SandboxHome -Recurse -Force -ErrorAction SilentlyContinue
    # Drop the sandboxed module so later test files re-import with the real $HOME.
    Remove-Module oh-my-stats -Force -ErrorAction SilentlyContinue
}

Describe 'Cache primitives' {

    BeforeEach { Reset-Cache }

    Context 'Test-CacheValid' {
        It 'Should reject a cache file that does not exist' {
            $result = & (Get-Module oh-my-stats) { param($f) Test-CacheValid $f } $script:CacheFile
            $result | Should -BeFalse
        }

        It 'Should accept a cache file written just now' {
            Set-WarmCache
            $result = & (Get-Module oh-my-stats) { param($f) Test-CacheValid $f } $script:CacheFile
            $result | Should -BeTrue
        }

        It 'Should reject a cache file older than the 7 day TTL' {
            Set-WarmCache
            (Get-Item $script:CacheFile).LastWriteTime = (Get-Date).AddDays(-8)
            $result = & (Get-Module oh-my-stats) { param($f) Test-CacheValid $f } $script:CacheFile
            $result | Should -BeFalse
        }

        It 'Should accept a cache file just inside the 7 day TTL' {
            Set-WarmCache
            (Get-Item $script:CacheFile).LastWriteTime = (Get-Date).AddDays(-6)
            $result = & (Get-Module oh-my-stats) { param($f) Test-CacheValid $f } $script:CacheFile
            $result | Should -BeTrue
        }
    }

    Context 'Get-SystemInfoCache' {
        It 'Should return nothing when no cache file exists' {
            $result = & (Get-Module oh-my-stats) { Get-SystemInfoCache }
            $result | Should -BeNullOrEmpty
        }

        It 'Should return nothing when the cache file holds invalid JSON' {
            New-Item -ItemType Directory -Path $script:CacheDir -Force | Out-Null
            Set-Content -Path $script:CacheFile -Value '{ this is not json'
            $result = & (Get-Module oh-my-stats) { Get-SystemInfoCache }
            $result | Should -BeNullOrEmpty
        }

        It 'Should return nothing when the cache file is stale' {
            Set-WarmCache
            (Get-Item $script:CacheFile).LastWriteTime = (Get-Date).AddDays(-8)
            $result = & (Get-Module oh-my-stats) { Get-SystemInfoCache }
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Save-SystemInfoCache' {
        It 'Should create the cache directory and file' {
            Set-WarmCache
            Test-Path $script:CacheFile | Should -BeTrue
        }

        It 'Should round-trip every static field' {
            Set-WarmCache
            $result = & (Get-Module oh-my-stats) { Get-SystemInfoCache }

            $result.CPU.Name    | Should -Be 'Test CPU'
            $result.CPU.Cores   | Should -Be 4
            $result.CPU.Threads | Should -Be 8
            $result.RAM.Total   | Should -Be 16
            $result.RAM.Speed   | Should -Be '3200MHz'
            $result.Disk.Total  | Should -Be 500
            $result.OS.Edition  | Should -Be 'Windows 11 Pro'
        }

        It 'Should write valid JSON' {
            Set-WarmCache
            { Get-Content $script:CacheFile -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }
}

Describe 'Cache hit skips the static queries' -Skip:(-not $IsWindows) {

    BeforeEach {
        Reset-Cache

        # Canned system data. Every query the module makes is answered from here, so the
        # test asserts which queries run, not what the host happens to report. Calling
        # through to the real cmdlet is not an option: inside a mock body,
        # Get-Command resolves back to the mock and recurses.
        Mock Get-CimInstance -ModuleName oh-my-stats -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' } -MockWith {
            [PSCustomObject]@{
                TotalVisibleMemorySize = 16777216
                FreePhysicalMemory     = 8388608
                LastBootUpTime         = (Get-Date).AddDays(-2)
                Caption                = 'Microsoft Windows 11 Pro'
            }
        }
        Mock Get-CimInstance -ModuleName oh-my-stats -ParameterFilter { $ClassName -eq 'Win32_Processor' } -MockWith {
            [PSCustomObject]@{
                Name                     = 'Intel(R) Core(TM) i7-14700 CPU @ 2.10GHz'
                NumberOfCores            = 20
                NumberOfLogicalProcessors = 28
                MaxClockSpeed            = 2100
                LoadPercentage           = 15
            }
        }
        Mock Get-CimInstance -ModuleName oh-my-stats -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' } -MockWith {
            [PSCustomObject]@{ Speed = 4200 }
        }
        Mock Get-ItemProperty -ModuleName oh-my-stats -ParameterFilter { $Path -like '*Windows NT\CurrentVersion*' } -MockWith {
            [PSCustomObject]@{ CurrentBuild = '22631'; DisplayVersion = '23H2' }
        }
        Mock Get-Process -ModuleName oh-my-stats -MockWith {
            1..3 | ForEach-Object { [PSCustomObject]@{ Name = 'pwsh' } }
        }
    }

    It 'Should not query RAM hardware on a warm cache' {
        Set-WarmCache
        Show-SystemStats -NoModuleStatus | Out-Null

        Should -Invoke Get-CimInstance -ModuleName oh-my-stats -Times 0 -Exactly -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' }
    }

    It 'Should not read the Windows version registry key on a warm cache' {
        Set-WarmCache
        Show-SystemStats -NoModuleStatus | Out-Null

        Should -Invoke Get-ItemProperty -ModuleName oh-my-stats -Times 0 -Exactly -ParameterFilter { $Path -like '*Windows NT\CurrentVersion*' }
    }

    It 'Should query the CPU once on a warm cache (load only, not specs)' {
        Set-WarmCache
        Show-SystemStats -NoModuleStatus | Out-Null

        Should -Invoke Get-CimInstance -ModuleName oh-my-stats -Times 1 -Exactly -ParameterFilter { $ClassName -eq 'Win32_Processor' }
    }

    It 'Should query RAM hardware when the cache is cold' {
        Show-SystemStats -NoModuleStatus | Out-Null

        Should -Invoke Get-CimInstance -ModuleName oh-my-stats -Times 1 -Exactly -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' }
    }

    It 'Should read the Windows version registry key when the cache is cold' {
        Show-SystemStats -NoModuleStatus | Out-Null

        Should -Invoke Get-ItemProperty -ModuleName oh-my-stats -Times 2 -Exactly -ParameterFilter { $Path -like '*Windows NT\CurrentVersion*' }
    }

    It 'Should query the CPU twice when the cache is cold (specs plus load)' {
        Show-SystemStats -NoModuleStatus | Out-Null

        Should -Invoke Get-CimInstance -ModuleName oh-my-stats -Times 2 -Exactly -ParameterFilter { $ClassName -eq 'Win32_Processor' }
    }

    It 'Should re-query the static data when -RefreshCache is passed over a warm cache' {
        Set-WarmCache
        Show-SystemStats -NoModuleStatus -RefreshCache | Out-Null

        Should -Invoke Get-CimInstance -ModuleName oh-my-stats -Times 1 -Exactly -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' }
    }

    It 'Should still collect dynamic data on a warm cache' {
        Set-WarmCache
        Show-SystemStats -NoModuleStatus | Out-Null

        # Uptime and RAM usage come from the OS object, process counts from Get-Process.
        Should -Invoke Get-CimInstance -ModuleName oh-my-stats -Times 1 -Exactly -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }
        Should -Invoke Get-Process -ModuleName oh-my-stats
    }
}

Describe 'Cache lifecycle through Show-SystemStats' -Skip:(-not $IsWindows) {

    BeforeEach { Reset-Cache }

    It 'Should write a cache file on a cold run' {
        Show-SystemStats -NoModuleStatus | Out-Null
        Test-Path $script:CacheFile | Should -BeTrue
    }

    It 'Should store the CPU, RAM, disk and OS sections' {
        Show-SystemStats -NoModuleStatus | Out-Null
        $cached = Get-Content $script:CacheFile -Raw | ConvertFrom-Json

        $cached.CPU.Name   | Should -Not -BeNullOrEmpty
        $cached.RAM.Total  | Should -BeGreaterThan 0
        $cached.Disk.Total | Should -BeGreaterThan 0
        $cached.OS.Short   | Should -Not -BeNullOrEmpty
    }

    It 'Should leave the cache file untouched on a warm run' {
        Show-SystemStats -NoModuleStatus | Out-Null
        $written = (Get-Item $script:CacheFile).LastWriteTime

        Start-Sleep -Milliseconds 1100
        Show-SystemStats -NoModuleStatus | Out-Null

        (Get-Item $script:CacheFile).LastWriteTime | Should -Be $written
    }

    It 'Should rewrite the cache file when -RefreshCache is passed' {
        Show-SystemStats -NoModuleStatus | Out-Null
        $written = (Get-Item $script:CacheFile).LastWriteTime

        Start-Sleep -Milliseconds 1100
        Show-SystemStats -NoModuleStatus -RefreshCache | Out-Null

        (Get-Item $script:CacheFile).LastWriteTime | Should -BeGreaterThan $written
    }

    It 'Should rebuild the cache after a stale file is found' {
        Show-SystemStats -NoModuleStatus | Out-Null
        (Get-Item $script:CacheFile).LastWriteTime = (Get-Date).AddDays(-8)

        Show-SystemStats -NoModuleStatus | Out-Null

        $age = (Get-Date) - (Get-Item $script:CacheFile).LastWriteTime
        $age.TotalMinutes | Should -BeLessThan 5
    }

    It 'Should survive a corrupt cache file' {
        New-Item -ItemType Directory -Path $script:CacheDir -Force | Out-Null
        Set-Content -Path $script:CacheFile -Value '{ truncated'

        { Show-SystemStats -NoModuleStatus } | Should -Not -Throw
    }
}

Describe 'Stopwatch' -Tag 'Performance' -Skip:([bool]$env:CI -or -not $IsWindows) {
    <#
        Wall-clock, measured only outside CI. The assertion is relative (a cache hit
        beats a cache miss) because absolute thresholds depend on the machine. The
        measured numbers are printed either way, so a regression is visible even when
        the test passes.
    #>

    It 'Should serve a warm cache faster than it builds a cold one' {
        Reset-Cache

        $cold = (Measure-Command { Show-SystemStats -NoModuleStatus | Out-Null }).TotalMilliseconds

        # Three warm runs, take the median, so one scheduling hiccup cannot flip the test.
        $warmRuns = 1..3 | ForEach-Object {
            (Measure-Command { Show-SystemStats -NoModuleStatus | Out-Null }).TotalMilliseconds
        }
        $warm = ($warmRuns | Sort-Object)[1]

        $saved = [math]::Round((1 - $warm / $cold) * 100, 1)
        Write-Host ("  cold: {0} ms | warm (median of 3): {1} ms | saved: {2}%" -f [math]::Round($cold), [math]::Round($warm), $saved)

        $warm | Should -BeLessThan $cold
    }
}

Describe 'The queries that cost the most never run' -Skip:(-not $IsWindows) {

    # Each assertion here guards one measured fix from the 1458-1763ms -> ~190ms work
    # (see .plan/BACKLOG.md). They are behaviour tests, not timings: a regression puts the
    # expensive call back, and the call is what is asserted.

    BeforeEach {
        Reset-Cache

        Mock Get-CimInstance -ModuleName oh-my-stats -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' } -MockWith {
            [PSCustomObject]@{
                TotalVisibleMemorySize = 16777216
                FreePhysicalMemory     = 8388608
                LastBootUpTime         = (Get-Date).AddDays(-2)
                Caption                = 'Microsoft Windows 11 Pro'
            }
        }
        Mock Get-CimInstance -ModuleName oh-my-stats -ParameterFilter { $ClassName -eq 'Win32_Processor' } -MockWith {
            [PSCustomObject]@{
                Name                      = 'Intel(R) Core(TM) i7-14700 CPU @ 2.10GHz'
                NumberOfCores             = 20
                NumberOfLogicalProcessors = 28
                MaxClockSpeed             = 2100
                LoadPercentage            = 15
            }
        }
        Mock Get-CimInstance -ModuleName oh-my-stats -ParameterFilter { $ClassName -eq 'Win32_PhysicalMemory' } -MockWith {
            [PSCustomObject]@{ Speed = 4200 }
        }
        Mock Get-ItemProperty -ModuleName oh-my-stats -ParameterFilter { $Path -like '*Windows NT\CurrentVersion*' } -MockWith {
            [PSCustomObject]@{ CurrentBuild = '22631'; DisplayVersion = '23H2' }
        }
        Mock Get-Process -ModuleName oh-my-stats -MockWith {
            1..3 | ForEach-Object { [PSCustomObject]@{ Name = 'pwsh' } }
        }
        Mock Get-PSDrive -ModuleName oh-my-stats -MockWith {
            [PSCustomObject]@{ Name = 'C'; Used = 1; Free = 1 }
        }
    }

    It 'Should never ask Win32_Processor for LoadPercentage' {
        # WMI samples the CPU inside the provider to answer this one property: ~1050ms.
        # Get-CpuLoadPercent replaced it; mocked here so the fallback branch cannot fire
        # on a runner with broken performance counters.
        Mock Get-CpuLoadPercent -ModuleName oh-my-stats -MockWith { 15 }

        Show-SystemStats -NoModuleStatus | Out-Null

        Should -Invoke Get-CimInstance -ModuleName oh-my-stats -Times 0 -Exactly `
            -ParameterFilter { $Property -contains 'LoadPercentage' }
    }

    It 'Should project properties on every CIM query' {
        # Asking for a whole WMI class costs an order of magnitude more than asking for
        # the handful of properties actually read.
        Show-SystemStats -NoModuleStatus | Out-Null

        Should -Invoke Get-CimInstance -ModuleName oh-my-stats -Times 0 -Exactly `
            -ParameterFilter { -not $Property }
    }

    It 'Should enumerate processes exactly once' {
        # Get-Process walks every process on the box; the terminal count and the process
        # count come from one snapshot.
        Show-SystemStats -NoModuleStatus | Out-Null

        Should -Invoke Get-Process -ModuleName oh-my-stats -Times 1 -Exactly
    }

    It 'Should not touch Get-PSDrive' {
        # The provider call walks every PowerShell drive. [System.IO.DriveInfo] reads one.
        Show-SystemStats -NoModuleStatus | Out-Null

        Should -Invoke Get-PSDrive -ModuleName oh-my-stats -Times 0 -Exactly
    }

    It 'Should report no CPU reading as $null, never as 0' {
        # Silence must not look like an idle CPU: a broken counter has to be tellable from
        # a genuine 0%.
        Mock Get-CimInstance -ModuleName oh-my-stats -ParameterFilter { $ClassName -eq 'Win32_PerfRawData_PerfOS_Processor' } -MockWith {
            throw 'Internal performance counter API call failed'
        }

        $load = & (Get-Module oh-my-stats) { Get-CpuLoadPercent -SampleIntervalMs 1 }

        $load | Should -BeNullOrEmpty
        $load | Should -Not -Be 0
    }
}
