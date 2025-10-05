#!/usr/bin/env pwsh
# oh-my-stats PowerShell Installer
# Cross-platform installer for Windows, macOS, Linux

param(
    [switch]$Force,
    [switch]$Global
)

$ErrorActionPreference = 'Stop'

Write-Host "🎨 oh-my-stats Installer" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "❌ PowerShell 7+ required. Install from: https://github.com/PowerShell/PowerShell" -ForegroundColor Red
    exit 1
}

# Backup existing profile
if (Test-Path $PROFILE) {
    $backupPath = "$PROFILE.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $PROFILE $backupPath
    Write-Host "✓ Backed up profile to: $backupPath" -ForegroundColor Green
} else {
    # Create profile directory if it doesn't exist
    $profileDir = Split-Path $PROFILE
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }
}

# Clone or download module
$moduleUrl = "https://raw.githubusercontent.com/zentala/oh-my-stats/main/pwsh/oh-my-stats.psm1"
$manifestUrl = "https://raw.githubusercontent.com/zentala/oh-my-stats/main/pwsh/oh-my-stats.psd1"
$configUrl = "https://raw.githubusercontent.com/zentala/oh-my-stats/main/config/default.json"

$modulePath = if ($Global) {
    Join-Path $env:ProgramFiles "PowerShell/Modules/oh-my-stats"
} else {
    Join-Path ([Environment]::GetFolderPath('MyDocuments')) "PowerShell/Modules/oh-my-stats"
}

# Create module directory
if (-not (Test-Path $modulePath)) {
    New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
}

# Download module files
Write-Host "📥 Downloading module..." -ForegroundColor Yellow
try {
    Invoke-WebRequest $moduleUrl -OutFile (Join-Path $modulePath "oh-my-stats.psm1")
    Invoke-WebRequest $manifestUrl -OutFile (Join-Path $modulePath "oh-my-stats.psd1")
    Write-Host "✓ Module downloaded to: $modulePath" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download module: $_" -ForegroundColor Red
    exit 1
}

# Download default config
$configPath = if ($env:XDG_CONFIG_HOME) {
    Join-Path $env:XDG_CONFIG_HOME "oh-my-stats"
} else {
    Join-Path $HOME ".config/oh-my-stats"
}

if (-not (Test-Path $configPath)) {
    New-Item -ItemType Directory -Path $configPath -Force | Out-Null
}

try {
    Invoke-WebRequest $configUrl -OutFile (Join-Path $configPath "config.json")
    Write-Host "✓ Config downloaded to: $configPath/config.json" -ForegroundColor Green
} catch {
    Write-Host "⚠ Failed to download config, using defaults" -ForegroundColor Yellow
}

# Add to profile
$profileContent = @"

# oh-my-stats - System statistics display
Import-Module oh-my-stats -ErrorAction SilentlyContinue
if (Get-Module oh-my-stats) {
    Show-SystemStats
}
"@

if ($Force -or -not (Select-String -Path $PROFILE -Pattern "oh-my-stats" -Quiet -ErrorAction SilentlyContinue)) {
    Add-Content $PROFILE $profileContent
    Write-Host "✓ Added to profile: $PROFILE" -ForegroundColor Green
} else {
    Write-Host "⚠ oh-my-stats already in profile, use -Force to override" -ForegroundColor Yellow
}

# Check dependencies
Write-Host ""
Write-Host "📋 Checking dependencies..." -ForegroundColor Yellow

$deps = @{
    "oh-my-posh" = @{
        Install = "winget install JanDeDobbeleer.OhMyPosh"
        Optional = $true
    }
    "PSReadLine" = @{
        Install = "Install-Module PSReadLine -Force"
        Optional = $true
    }
}

foreach ($dep in $deps.Keys) {
    if (Get-Command $dep -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ $dep installed" -ForegroundColor Green
    } else {
        $status = if ($deps[$dep].Optional) { "optional" } else { "required" }
        Write-Host "  ⚠ $dep missing ($status)" -ForegroundColor Yellow
        Write-Host "    Install: $($deps[$dep].Install)" -ForegroundColor DarkGray
    }
}

# Final message
Write-Host ""
Write-Host "✨ Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Restart PowerShell or run: . `$PROFILE" -ForegroundColor White
Write-Host "  2. Install a Nerd Font: https://www.nerdfonts.com/" -ForegroundColor White
Write-Host "  3. Configure terminal to use Nerd Font" -ForegroundColor White
Write-Host ""
Write-Host "Documentation: https://github.com/zentala/oh-my-stats" -ForegroundColor DarkGray
