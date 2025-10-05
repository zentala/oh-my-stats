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
        return [char]$code
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

    try {
        Clear-Host
    } catch {
        Write-Host "`n`n"
    }

    # Get system information
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    } catch {
        Write-Error "Cannot access system information. Please check if WMI service is running or run PowerShell as Administrator."
        return
    }

    try {
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
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

    # CPU load
    try {
        $cpuLoad = (Get-CimInstance Win32_Processor -ErrorAction Stop).LoadPercentage
        if (-not $cpuLoad -or $cpuLoad -eq 0) {
            try {
                $cpuLoad = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop).CounterSamples.CookedValue
            } catch {
                Write-Verbose "Performance counters unavailable, using 0%"
                $cpuLoad = 0
            }
        }
        $cpuLoad = [math]::Round($cpuLoad, 0)
    } catch {
        Write-Verbose "Cannot get CPU load, using 0%"
        $cpuLoad = 0
    }

    # RAM calculations
    $ramUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1024 / 1024, 1)
    $ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1024 / 1024, 1)
    $ramPercent = [math]::Round(($ramUsed / $ramTotal) * 100, 0)

    # Memory speed
    $memSpeed = $mem | Select-Object -First 1 | Select-Object -ExpandProperty Speed
    if (-not $memSpeed) { $memSpeed = "DDR4" } else { $memSpeed = "${memSpeed}MHz" }

    # Disk calculations
    $disk = Get-PSDrive C -ErrorAction SilentlyContinue
    if ($disk) {
        $diskUsed = [math]::Round($disk.Used / 1GB, 0)
        $diskTotal = [math]::Round(($disk.Used + $disk.Free) / 1GB, 0)
        $diskPercent = [math]::Round($disk.Used / ($disk.Used + $disk.Free) * 100, 0)
    } else {
        $diskUsed = 0
        $diskTotal = 0
        $diskPercent = 0
    }

    # Process and uptime
    $processCount = (Get-Process).Count
    try {
        $uptime = (Get-Date) - $os.LastBootUpTime
    } catch {
        Write-Verbose "Cannot get uptime, using 0"
        $uptime = New-TimeSpan -Days 0 -Hours 0
    }
    $terminalCount = (Get-Process -Name pwsh,powershell,WindowsTerminal -ErrorAction SilentlyContinue).Count

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

    # Display header
    Write-Host ""
    Write-Host "  $(Get-Icon $Config.icons.user)  " -NoNewline -ForegroundColor $Config.colors.user
    Write-Host "$env:USERNAME " -NoNewline -ForegroundColor $Config.colors.user
    Write-Host "@ " -NoNewline -ForegroundColor DarkGray
    Write-Host "$(Get-Icon $Config.icons.computer)  " -NoNewline -ForegroundColor $Config.colors.computer
    Write-Host "$env:COMPUTERNAME " -NoNewline -ForegroundColor $Config.colors.computer
    Write-Host "│ " -NoNewline -ForegroundColor DarkGray
    Write-Host "$(Get-Icon $osIcon)  " -NoNewline -ForegroundColor $Config.colors.os
    Write-Host "$osShort x64 $winVer " -NoNewline -ForegroundColor $Config.colors.os
    Write-Host "│ " -NoNewline -ForegroundColor DarkGray
    Write-Host "$(Get-Icon $Config.icons.powershell)  " -NoNewline -ForegroundColor $Config.colors.shell
    Write-Host "PowerShell v$($PSVersionTable.PSVersion)" -ForegroundColor $Config.colors.shell
    Write-Host ""

    # CPU display
    if ($Config.modules.cpu) {
        Write-Host "  " -NoNewline
        Write-Host "$(Get-Icon $Config.icons.cpu)  " -NoNewline -ForegroundColor $Config.colors.cpu
        Write-Host "CPU " -NoNewline -ForegroundColor $Config.colors.cpu
        Write-Host "$(Draw-ProgressBar -Percent $cpuLoad -Width $Config.display.progressBarWidth) " -NoNewline
        $cpuColor = if ($cpuLoad -ge 80) { "Red" } elseif ($cpuLoad -ge 60) { "Yellow" } else { "Green" }
        Write-Host "$($cpuLoad.ToString().PadLeft(2))% " -NoNewline -ForegroundColor $cpuColor
        Write-Host "[$(Get-Icon $Config.icons.cpuChip) $cpuShort @ ${cpuSpeed}GHz ${cpuCores}c/${cpuThreads}t]" -ForegroundColor $Config.colors.details
    }

    # RAM display
    if ($Config.modules.ram) {
        Write-Host "  " -NoNewline
        Write-Host "$(Get-Icon $Config.icons.ram)  " -NoNewline -ForegroundColor $Config.colors.ram
        Write-Host "RAM " -NoNewline -ForegroundColor $Config.colors.ram
        Write-Host "$(Draw-ProgressBar -Percent $ramPercent -Width $Config.display.progressBarWidth) " -NoNewline
        $ramColor = if ($ramPercent -ge 80) { "Red" } elseif ($ramPercent -ge 60) { "Yellow" } else { "Green" }
        Write-Host "$($ramPercent.ToString().PadLeft(2))% " -NoNewline -ForegroundColor $ramColor
        Write-Host "(${ramUsed}GB/${ramTotal}GB) " -NoNewline -ForegroundColor $Config.colors.info
        Write-Host "[$(Get-Icon $Config.icons.ramFreq) $memSpeed]" -ForegroundColor $Config.colors.details
    }

    # Disk display
    if ($Config.modules.disk -and $disk) {
        Write-Host "  " -NoNewline
        Write-Host "$(Get-Icon $Config.icons.disk)  " -NoNewline -ForegroundColor $Config.colors.disk
        Write-Host "HDD " -NoNewline -ForegroundColor $Config.colors.disk
        Write-Host "$(Draw-ProgressBar -Percent $diskPercent -Width $Config.display.progressBarWidth) " -NoNewline
        $diskColor = if ($diskPercent -ge 80) { "Red" } elseif ($diskPercent -ge 60) { "Yellow" } else { "Green" }
        Write-Host "$($diskPercent.ToString().PadLeft(2))% " -NoNewline -ForegroundColor $diskColor
        Write-Host "(${diskUsed}GB/${diskTotal}GB) " -NoNewline -ForegroundColor $Config.colors.info
        Write-Host "[$(Get-Icon $Config.icons.folder) C:\]" -ForegroundColor $Config.colors.details
    }

    # Stats bar
    if ($Config.modules.terminals -or $Config.modules.processes -or $Config.modules.uptime) {
        Write-Host ""
        Write-Host "  [ " -NoNewline -ForegroundColor DarkGray

        if ($Config.modules.terminals) {
            Write-Host "$(Get-Icon $Config.icons.terminal)  " -NoNewline -ForegroundColor Cyan
            Write-Host "$terminalCount terminals" -NoNewline -ForegroundColor Cyan
        }

        if ($Config.modules.processes) {
            Write-Host " │ " -NoNewline -ForegroundColor DarkGray
            Write-Host "$(Get-Icon $Config.icons.process)  " -NoNewline -ForegroundColor Green
            Write-Host "$processCount processes" -NoNewline -ForegroundColor Green
        }

        if ($Config.modules.uptime) {
            Write-Host " │ " -NoNewline -ForegroundColor DarkGray
            Write-Host "$(Get-Icon $Config.icons.uptime)  " -NoNewline -ForegroundColor Yellow
            Write-Host "$($uptime.Days)d $($uptime.Hours)h uptime" -NoNewline -ForegroundColor Yellow
        }

        Write-Host " ]" -ForegroundColor DarkGray
    }

    # Module status
    if (-not $NoModuleStatus -and $Config.modules.shellModules) {
        Write-Host ""

        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            Write-Host "    [" -NoNewline -ForegroundColor DarkGray
            Write-Host "✓" -NoNewline -ForegroundColor $Config.colors.success
            Write-Host "] " -NoNewline -ForegroundColor DarkGray
            Write-Host "Oh My Posh" -ForegroundColor $Config.colors.info
        }

        if (Get-Module -Name PSReadLine) {
            Write-Host "    [" -NoNewline -ForegroundColor DarkGray
            Write-Host "✓" -NoNewline -ForegroundColor $Config.colors.success
            Write-Host "] " -NoNewline -ForegroundColor DarkGray
            Write-Host "PSReadLine" -ForegroundColor $Config.colors.info
        }

        if (Get-Module -Name Terminal-Icons) {
            Write-Host "    [" -NoNewline -ForegroundColor DarkGray
            Write-Host "✓" -NoNewline -ForegroundColor $Config.colors.success
            Write-Host "] " -NoNewline -ForegroundColor DarkGray
            Write-Host "Terminal-Icons" -ForegroundColor $Config.colors.info
        }
    }

    Write-Host ""
}

# Export functions
Export-ModuleMember -Function Show-SystemStats
