# oh-my-stats PowerShell Module
# Cross-platform system statistics display
# Author: Paweł Żentała
# License: MIT

# Load config
$script:ConfigPath = if ($env:XDG_CONFIG_HOME) {
    Join-Path $env:XDG_CONFIG_HOME "oh-my-stats/config.json"
} else {
    Join-Path $HOME ".config/oh-my-stats/config.json"
}

# CIM property projections. Querying a whole WMI class costs an order of magnitude more
# than asking for the handful of properties actually read below.
$script:OsProperties  = @('TotalVisibleMemorySize', 'FreePhysicalMemory', 'LastBootUpTime', 'Caption')
$script:CpuProperties = @('Name', 'NumberOfCores', 'NumberOfLogicalProcessors', 'MaxClockSpeed')

$script:DefaultConfigPath = Join-Path $PSScriptRoot "../config/default.json"
$script:Config = if (Test-Path $ConfigPath) {
    Get-Content $ConfigPath | ConvertFrom-Json
} else {
    Get-Content $DefaultConfigPath | ConvertFrom-Json
}

# Helper function: Draw progress bar
function Draw-ProgressBar {
    param(
        [int]$Percent,
        [int]$Width = 50,
        [string]$Color = "Green"
    )

    # Clamp percent to 0-100 range
    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }

    $filled = [math]::Floor($Percent * $Width / 100)
    $empty = $Width - $filled

    if ($Percent -ge 80) { $Color = "Red" }
    elseif ($Percent -ge 60) { $Color = "Yellow" }
    else { $Color = "Green" }

    $bar = "█" * $filled + "░" * $empty

    $colorCode = switch($Color) {
        "Green" { "`e[32m" }
        "Yellow" { "`e[33m" }
        "Red" { "`e[31m" }
    }

    return "${colorCode}${bar}`e[0m"
}

# Helper function: Convert UTF32 for large icons
function Get-Icon {
    param([string]$HexCode)

    $code = [int]$HexCode
    if ($code -gt 0xFFFF) {
        return [System.Char]::ConvertFromUtf32($code)
    } else {
        return [string][char]$code
    }
}

# Cache functions for performance optimization
function Test-CacheValid {
    param([string]$CacheFile)

    if (-not (Test-Path $CacheFile)) {
        return $false
    }

    try {
        $cacheAge = (Get-Date) - (Get-Item $CacheFile).LastWriteTime
        # Cache valid for 7 days
        return $cacheAge.TotalDays -lt 7
    } catch {
        return $false
    }
}

function Get-SystemInfoCache {
    $cacheDir = Join-Path $HOME ".cache/oh-my-stats"
    $cacheFile = Join-Path $cacheDir "system-info.json"

    if (Test-CacheValid $cacheFile) {
        try {
            $cached = Get-Content $cacheFile -Raw | ConvertFrom-Json
            Write-Verbose "Using cached system info (age: $((Get-Date) - (Get-Item $cacheFile).LastWriteTime))"
            return $cached
        } catch {
            Write-Verbose "Cache read failed: $_"
            return $null
        }
    }

    return $null
}

function Save-SystemInfoCache {
    param($SystemInfo)

    $cacheDir = Join-Path $HOME ".cache/oh-my-stats"
    $cacheFile = Join-Path $cacheDir "system-info.json"

    try {
        if (-not (Test-Path $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }

        $SystemInfo | ConvertTo-Json -Depth 5 | Set-Content $cacheFile -Force
        Write-Verbose "Saved system info to cache"
    } catch {
        Write-Verbose "Failed to save cache: $_"
    }
}

<#
.SYNOPSIS
    CPU load in percent, from two raw performance-counter samples.
.DESCRIPTION
    Win32_PerfRawData_PerfOS_Processor answers in ~27ms, but its PercentProcessorTime is a
    raw idle-time counter, so a percentage needs two samples and the time between them.
    The two cheaper-looking alternatives are both worse:
      * Win32_Processor.LoadPercentage makes the WMI provider sample the CPU itself and
        costs ~1050ms, over half the runtime of Show-SystemStats.
      * Get-Counter depends on the performance counter API, which is broken on some
        machines (it throws 'Internal performance counter API call failed', error c0000bb8)
        and then costs a failed call before any fallback runs.
    Returns $null when the counter cannot be read, so the caller can tell "no reading" from
    a genuine 0%.
#>
function Get-CpuLoadPercent {
    [CmdletBinding()]
    # 50ms is a long enough window for the counter delta to be meaningful, and it is pure
    # latency on every shell start - the profile waits for it.
    param([int]$SampleIntervalMs = 50)

    $query = {
        Get-CimInstance Win32_PerfRawData_PerfOS_Processor -Filter "Name='_Total'" `
            -Property PercentProcessorTime, Timestamp_Sys100NS -ErrorAction Stop
    }

    try {
        $first = & $query
        Start-Sleep -Milliseconds $SampleIntervalMs
        $second = & $query
    } catch {
        Write-Verbose "Raw performance counters unavailable: $_"
        return $null
    }

    $idleDelta = $second.PercentProcessorTime - $first.PercentProcessorTime
    $timeDelta = $second.Timestamp_Sys100NS - $first.Timestamp_Sys100NS
    if ($timeDelta -le 0) { return $null }

    $busy = 100 - (100 * $idleDelta / $timeDelta)
    [math]::Round([math]::Max(0, [math]::Min(100, $busy)), 0)
}

# Main function: Show system statistics
function Show-SystemStats {
    [CmdletBinding()]
    param(
        [switch]$Compact,
        [switch]$NoModuleStatus,
        [string]$ConfigPath,
        [switch]$RefreshCache
    )

    # Load custom config if provided
    if ($ConfigPath -and (Test-Path $ConfigPath)) {
        $Config = Get-Content $ConfigPath | ConvertFrom-Json
    } else {
        $Config = $script:Config
    }

    # Icon mode: config default, overridden by oh-my-pwsh global if set
    $useIcons = [bool]($Config.display.nerdFonts)
    if (Get-Variable -Name OhMyPwsh_UseNerdFonts -Scope Global -ErrorAction SilentlyContinue) {
        $useIcons = [bool]$global:OhMyPwsh_UseNerdFonts
    }

    try {
        Clear-Host
    } catch {
        Write-Host "`n`n"
    }

    # Try to load cached static data (unless refresh requested)
    $cachedData = $null
    if (-not $RefreshCache) {
        $cachedData = Get-SystemInfoCache
    }

    # Get or load static system information
    if ($cachedData) {
        # Use cached static data
        $cpuName = $cachedData.CPU.Name
        $cpuShort = $cachedData.CPU.ShortName
        $cpuCores = $cachedData.CPU.Cores
        $cpuThreads = $cachedData.CPU.Threads
        $cpuSpeed = $cachedData.CPU.Speed
        $ramTotal = $cachedData.RAM.Total
        $memSpeed = $cachedData.RAM.Speed
        $diskTotal = $cachedData.Disk.Total
        $osShort = $cachedData.OS.Short
        $winVer = $cachedData.OS.Version
        $winEdition = $cachedData.OS.Edition
        $osIcon = $cachedData.OS.Icon

        # Still need OS object for dynamic RAM calculation
        try {
            $os = Get-CimInstance Win32_OperatingSystem -Property $script:OsProperties -ErrorAction Stop
        } catch {
            Write-Error "Cannot access system information. Please check if WMI service is running or run PowerShell as Administrator."
            return
        }
    } else {
        # Query all static data (cache miss or refresh)
        try {
            $os = Get-CimInstance Win32_OperatingSystem -Property $script:OsProperties -ErrorAction Stop
        } catch {
            Write-Error "Cannot access system information. Please check if WMI service is running or run PowerShell as Administrator."
            return
        }

        try {
            $cpu = Get-CimInstance Win32_Processor -Property $script:CpuProperties -ErrorAction Stop | Select-Object -First 1
        } catch {
            Write-Error "Cannot access CPU information: $_"
            return
        }

        try {
            $mem = Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop
        } catch {
            Write-Verbose "Cannot get RAM speed information, using default"
            $mem = $null
        }
    }

    # CPU load
    $cpuLoad = Get-CpuLoadPercent
    if ($null -eq $cpuLoad) {
        # Last resort: ~1050ms, but it is the only reading left.
        try {
            $cpuLoad = [math]::Round((Get-CimInstance Win32_Processor -Property LoadPercentage -ErrorAction Stop).LoadPercentage, 0)
        } catch {
            Write-Verbose "Cannot get CPU load, using 0%"
            $cpuLoad = 0
        }
    }

    # RAM calculations (dynamic data always queried)
    $ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1024 / 1024, 1)
    if (-not $cachedData) {
        $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1024 / 1024, 1)
    }
    $ramPercent = [math]::Round(($ramUsed / $ramTotal) * 100, 0)

    # Memory speed (only if cache miss)
    if (-not $cachedData) {
        $memSpeed = $mem | Select-Object -First 1 | Select-Object -ExpandProperty Speed
        if (-not $memSpeed) { $memSpeed = "DDR4" } else { $memSpeed = "${memSpeed}MHz" }
    }

    # Disk calculations (always query for dynamic data)
    # DriveInfo, not Get-PSDrive: the provider call walks every PowerShell drive and costs
    # ~70ms, the .NET type reads the same two numbers from the filesystem in about none.
    $disk = try { [System.IO.DriveInfo]::new('C') } catch { $null }
    if ($disk -and $disk.IsReady) {
        $diskFree = $disk.TotalFreeSpace
        $diskSize = $disk.TotalSize
        $diskUsed = [math]::Round(($diskSize - $diskFree) / 1GB, 0)
        if (-not $cachedData) {
            $diskTotal = [math]::Round($diskSize / 1GB, 0)
        }
        $diskPercent = [math]::Round(($diskSize - $diskFree) / $diskSize * 100, 0)
    } else {
        $diskUsed = 0
        if (-not $cachedData) {
            $diskTotal = 0
        }
        $diskPercent = 0
    }

    # Process and uptime (dynamic data always queried)
    # One snapshot, counted twice - each Get-Process enumerates all ~600 processes.
    $allProcesses = Get-Process -ErrorAction SilentlyContinue
    $processCount = $allProcesses.Count
    try {
        $uptime = (Get-Date) - $os.LastBootUpTime
    } catch {
        Write-Verbose "Cannot get uptime, using 0"
        $uptime = New-TimeSpan -Days 0 -Hours 0
    }
    $terminalCount = @($allProcesses | Where-Object { $_.ProcessName -in @('pwsh', 'powershell', 'WindowsTerminal') }).Count

    # Static data processing (only on cache miss)
    if (-not $cachedData) {
        # CPU details
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

        # Format CPU name
        if ($cpuName -match "Intel.*Core.*i(\d)-(\d{4,5}\w*)") {
            # Intel Core i3/i5/i7/i9 (e.g., i7-8750H, i5-12400F)
            $cpuShort = "i$($matches[1])-$($matches[2])"
        } elseif ($cpuName -match "AMD Ryzen (\d+) (\d{4}\w*)") {
            # AMD Ryzen (e.g., Ryzen 5 5600X, Ryzen 7 5800X3D)
            $cpuShort = "Ryzen $($matches[1]) $($matches[2])"
        } elseif ($cpuName -match "AMD Ryzen (\d+) PRO (\d{4}\w*)") {
            # AMD Ryzen PRO
            $cpuShort = "Ryzen $($matches[1]) PRO $($matches[2])"
        } elseif ($cpuName -match "Intel.*Xeon.*(\w+)-(\d{4}\w*)") {
            # Intel Xeon (e.g., Xeon E-2288G)
            $cpuShort = "Xeon $($matches[1])-$($matches[2])"
        } elseif ($cpuName -match "Apple (\w+)") {
            # Apple Silicon (e.g., M1, M2, M3)
            $cpuShort = "Apple $($matches[1])"
        } else {
            # Fallback: clean up common patterns
            $cpuShort = $cpuName -replace "Intel\(R\) Core\(TM\) ", "" `
                                  -replace "AMD ", "" `
                                  -replace "Processor", "" `
                                  -replace "\(R\)", "" `
                                  -replace "\(TM\)", "" `
                                  -replace "\s+", " "
            $cpuShort = $cpuShort.Trim()
            # Limit length if too long
            if ($cpuShort.Length -gt 30) {
                $cpuShort = $cpuShort.Substring(0, 27) + "..."
            }
        }

        # OS version detection
        if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
            try {
                $winBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction Stop).CurrentBuild
                $winVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction Stop).DisplayVersion
            } catch {
                Write-Verbose "Cannot access registry, using fallback Windows detection"
                $winBuild = "Unknown"
                $winVer = $null
            }

            # Detect Windows version by build number
            if ($winBuild -ne "Unknown") {
                $winMajorVersion = if ([int]$winBuild -ge 22000) { "Windows 11" } else { "Windows 10" }
            } else {
                $winMajorVersion = "Windows"
            }

            $winEdition = $os.Caption
            if ($winEdition -match "Home") { $winEdition = "$winMajorVersion Home" }
            elseif ($winEdition -match "Pro") { $winEdition = "$winMajorVersion Pro" }
            elseif ($winEdition -match "Enterprise") { $winEdition = "$winMajorVersion Enterprise" }
            elseif ($winEdition -match "Education") { $winEdition = "$winMajorVersion Education" }
            else { $winEdition = $winMajorVersion }

            # Use DisplayVersion if available, otherwise use build-based version
            if (-not $winVer -and $winBuild -ne "Unknown") {
                if ([int]$winBuild -ge 22631) { $winVer = "23H2" }
                elseif ([int]$winBuild -ge 22621) { $winVer = "22H2" }
                elseif ([int]$winBuild -ge 22000) { $winVer = "21H2" }
                elseif ([int]$winBuild -ge 19045) { $winVer = "22H2" }
                elseif ([int]$winBuild -ge 19044) { $winVer = "21H2" }
                elseif ([int]$winBuild -ge 19043) { $winVer = "21H1" }
                elseif ([int]$winBuild -ge 19042) { $winVer = "20H2" }
                else { $winVer = "Legacy" }
            } elseif ($winBuild -eq "Unknown") {
                $winVer = ""
            }

            $osShort = $winEdition -replace "Windows 11", "Win11" -replace "Windows 10", "Win10"
            $osIcon = $Config.icons.windows
        } elseif ($IsMacOS) {
            $osShort = "macOS"
            $osIcon = "0xF179"
        } elseif ($IsLinux) {
            $osShort = "Linux"
            $osIcon = "0xF17C"
        } else {
            $osShort = "Unknown"
            $osIcon = "0xF233"
        }

        # Save static data to cache
        $staticData = @{
            CPU = @{
                Name = $cpuName
                ShortName = $cpuShort
                Cores = $cpuCores
                Threads = $cpuThreads
                Speed = $cpuSpeed
            }
            RAM = @{
                Total = $ramTotal
                Speed = $memSpeed
            }
            Disk = @{
                Total = $diskTotal
            }
            OS = @{
                Short = $osShort
                Version = $winVer
                Edition = $winEdition
                Icon = $osIcon
            }
        }
        Save-SystemInfoCache -SystemInfo $staticData
    }

    # Precompute icon set: Nerd Font hex codes or Unicode fallbacks
    if ($useIcons) {
        $osIconResolved = Get-Icon $osIcon
        $icons = @{
            user       = Get-Icon $Config.icons.user
            computer   = Get-Icon $Config.icons.computer
            os         = $osIconResolved
            powershell = Get-Icon $Config.icons.powershell
            cpu        = Get-Icon $Config.icons.cpu
            cpuChip    = Get-Icon $Config.icons.cpuChip
            ram        = Get-Icon $Config.icons.ram
            ramFreq    = Get-Icon $Config.icons.ramFreq
            disk       = Get-Icon $Config.icons.disk
            folder     = Get-Icon $Config.icons.folder
            terminal   = Get-Icon $Config.icons.terminal
            process    = Get-Icon $Config.icons.process
            uptime     = Get-Icon $Config.icons.uptime
        }
    } else {
        $osIconUnicode = if ($IsMacOS) { $Config.unicodeIcons.macos } elseif ($IsLinux) { $Config.unicodeIcons.linux } else { $Config.unicodeIcons.windows }
        $icons = @{
            user       = $Config.unicodeIcons.user
            computer   = $Config.unicodeIcons.computer
            os         = $osIconUnicode
            powershell = $Config.unicodeIcons.powershell
            cpu        = $Config.unicodeIcons.cpu
            cpuChip    = $Config.unicodeIcons.cpuChip
            ram        = $Config.unicodeIcons.ram
            ramFreq    = $Config.unicodeIcons.ramFreq
            disk       = $Config.unicodeIcons.disk
            folder     = $Config.unicodeIcons.folder
            terminal   = $Config.unicodeIcons.terminal
            process    = $Config.unicodeIcons.process
            uptime     = $Config.unicodeIcons.uptime
        }
    }

    # Display header
    Write-Host ""
    Write-Host "  " -NoNewline
    if ($icons.user) { Write-Host "$($icons.user) " -NoNewline -ForegroundColor $Config.colors.user }
    Write-Host "$env:USERNAME " -NoNewline -ForegroundColor $Config.colors.user
    Write-Host "@ " -NoNewline -ForegroundColor DarkGray
    if ($icons.computer) { Write-Host "$($icons.computer) " -NoNewline -ForegroundColor $Config.colors.computer }
    Write-Host "$env:COMPUTERNAME " -NoNewline -ForegroundColor $Config.colors.computer
    Write-Host " │ " -NoNewline -ForegroundColor DarkGray
    if ($icons.os) { Write-Host "$($icons.os) " -NoNewline -ForegroundColor $Config.colors.os }
    Write-Host "$osShort x64 $winVer " -NoNewline -ForegroundColor $Config.colors.os
    Write-Host " │ " -NoNewline -ForegroundColor DarkGray
    if ($icons.powershell) { Write-Host "$($icons.powershell) " -NoNewline -ForegroundColor $Config.colors.shell }
    Write-Host "PowerShell v$($PSVersionTable.PSVersion)" -ForegroundColor $Config.colors.shell
    Write-Host ""

    # CPU display
    if ($Config.modules.cpu) {
        Write-Host "  " -NoNewline
        if ($icons.cpu) { Write-Host "$($icons.cpu) " -NoNewline -ForegroundColor $Config.colors.cpu }
        Write-Host "CPU " -NoNewline -ForegroundColor $Config.colors.cpu
        Write-Host "$(Draw-ProgressBar -Percent $cpuLoad -Width $Config.display.progressBarWidth) " -NoNewline
        $cpuColor = if ($cpuLoad -ge 80) { "Red" } elseif ($cpuLoad -ge 60) { "Yellow" } else { "Green" }
        Write-Host "$($cpuLoad.ToString().PadLeft(2))% " -NoNewline -ForegroundColor $cpuColor
        $cpuDetail = if ($icons.cpuChip) { "$($icons.cpuChip) $cpuShort" } else { $cpuShort }
        Write-Host "[$cpuDetail @ ${cpuSpeed}GHz ${cpuCores}c/${cpuThreads}t]" -ForegroundColor $Config.colors.details
    }

    # RAM display
    if ($Config.modules.ram) {
        Write-Host "  " -NoNewline
        if ($icons.ram) { Write-Host "$($icons.ram) " -NoNewline -ForegroundColor $Config.colors.ram }
        Write-Host "RAM " -NoNewline -ForegroundColor $Config.colors.ram
        Write-Host "$(Draw-ProgressBar -Percent $ramPercent -Width $Config.display.progressBarWidth) " -NoNewline
        $ramColor = if ($ramPercent -ge 80) { "Red" } elseif ($ramPercent -ge 60) { "Yellow" } else { "Green" }
        Write-Host "$($ramPercent.ToString().PadLeft(2))% " -NoNewline -ForegroundColor $ramColor
        Write-Host "(${ramUsed}GB/${ramTotal}GB) " -NoNewline -ForegroundColor $Config.colors.info
        $freqDetail = if ($icons.ramFreq) { "$($icons.ramFreq)$memSpeed" } else { $memSpeed }
        Write-Host "[$freqDetail]" -ForegroundColor $Config.colors.details
    }

    # Disk display
    if ($Config.modules.disk -and $disk) {
        Write-Host "  " -NoNewline
        if ($icons.disk) { Write-Host "$($icons.disk) " -NoNewline -ForegroundColor $Config.colors.disk }
        Write-Host "HDD " -NoNewline -ForegroundColor $Config.colors.disk
        Write-Host "$(Draw-ProgressBar -Percent $diskPercent -Width $Config.display.progressBarWidth) " -NoNewline
        $diskColor = if ($diskPercent -ge 80) { "Red" } elseif ($diskPercent -ge 60) { "Yellow" } else { "Green" }
        Write-Host "$($diskPercent.ToString().PadLeft(2))% " -NoNewline -ForegroundColor $diskColor
        Write-Host "(${diskUsed}GB/${diskTotal}GB) " -NoNewline -ForegroundColor $Config.colors.info
        $folderDetail = if ($icons.folder) { "$($icons.folder) C:\" } else { "C:\" }
        Write-Host "[$folderDetail]" -ForegroundColor $Config.colors.details
    }

    # Stats bar
    if ($Config.modules.terminals -or $Config.modules.processes -or $Config.modules.uptime) {
        Write-Host ""
        Write-Host "  [ " -NoNewline -ForegroundColor DarkGray

        if ($Config.modules.terminals) {
            if ($icons.terminal) { Write-Host "$($icons.terminal) " -NoNewline -ForegroundColor Cyan }
            Write-Host "$terminalCount terminals" -NoNewline -ForegroundColor Cyan
        }

        if ($Config.modules.processes) {
            Write-Host " │ " -NoNewline -ForegroundColor DarkGray
            if ($icons.process) { Write-Host "$($icons.process) " -NoNewline -ForegroundColor Green }
            Write-Host "$processCount processes" -NoNewline -ForegroundColor Green
        }

        if ($Config.modules.uptime) {
            Write-Host " │ " -NoNewline -ForegroundColor DarkGray
            if ($icons.uptime) { Write-Host "$($icons.uptime) " -NoNewline -ForegroundColor Yellow }
            Write-Host "$($uptime.Days)d $($uptime.Hours)h uptime" -NoNewline -ForegroundColor Yellow
        }

        Write-Host " ]" -ForegroundColor DarkGray
    }

    Write-Host ""
}

# Export functions
Export-ModuleMember -Function Show-SystemStats, Draw-ProgressBar, Get-Icon
