# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-08-26

### Added
- **Works without Nerd Fonts** - `display.nerdFonts` config flag, default `false`
  - `false` renders a Unicode icon set that any terminal font can draw
  - `true` renders the Nerd Font glyphs as before
  - Setting `$global:OhMyPwsh_UseNerdFonts = $true` overrides the config, so
    oh-my-pwsh and oh-my-stats switch icons on together
- **Icon-free mode** - an empty icon string now renders no icon and no gap,
  so a config can strip icons entirely without leaving ghost spaces
- **Performance regression tests** (`tests/pwsh/performance.Tests.ps1`, 30 tests)
  - Assert the behaviour behind the cache: a warm cache skips `Win32_PhysicalMemory`,
    the Windows version registry key, and one of the two `Win32_Processor` calls
  - Guard each measured fix below: no `LoadPercentage` query, `-Property` on every
    CIM call, one `Get-Process` call, no `Get-PSDrive`, and an unreadable counter
    reported as `$null` rather than 0%
  - Cache lifecycle: written cold, untouched warm, rewritten by `-RefreshCache`,
    rebuilt when stale, and a corrupt file no longer matters
  - Stopwatch test, skipped when `$env:CI` is set, prints cold vs warm timings
- **CI/CD workflows** - test matrix across Windows, Linux and macOS; release
  pipeline on tag push; status badges in the README

### Changed
- Icons are precomputed once per run instead of being resolved per line
- The header renders as plain text; only the stat rows carry a prefix icon
- Removed the PowerShell module status display

### Performance
- **`Show-SystemStats` runs in ~190ms, down from 1458-1763ms** on the startup path
  - `Win32_Processor.LoadPercentage` cost ~1050ms on its own - WMI samples the CPU
    inside the provider to answer it. `Get-CpuLoadPercent` now reads two raw
    `Win32_PerfRawData_PerfOS_Processor` samples instead, and returns `$null` when the
    counter cannot be read so a broken counter is not mistaken for an idle CPU
  - `-Property` on every `Get-CimInstance`: asking for a whole WMI class costs an order
    of magnitude more than asking for the four properties actually read (~450ms -> ~33ms
    for `Win32_OperatingSystem`)
  - Disk usage reads `[System.IO.DriveInfo]` instead of `Get-PSDrive`, which walks every
    PowerShell drive
  - One `Get-Process` snapshot, counted twice, instead of two full enumerations

### Fixed
- Ghost spaces where an icon string was empty
- CPU icon rendering as a wide glyph that broke row alignment

## [1.0.0] - 2025-10-06

### Added
- **Performance Caching System** - 44% faster startup (2.9s → 1.6s)
  - Static system info cached for 7 days in `~/.cache/oh-my-stats/system-info.json`
  - Caches: OS version, CPU specs, RAM total/speed, disk total
  - Dynamic queries only: CPU load, RAM/disk usage, process counts, uptime
  - `-RefreshCache` parameter to force cache regeneration

- **Comprehensive Test Suite** - 68 Pester tests
  - CPU detection tests (Intel i3/i5/i7/i9, AMD Ryzen, Xeon, edge cases)
  - Windows version detection tests (Win10/11, different builds)
  - Helper function tests (Draw-ProgressBar, Get-Icon)
  - Error handling tests (WMI failures, registry access, disk errors)
  - Cache functionality tests

- **Exported Helper Functions**
  - `Draw-ProgressBar` - Create custom progress bars
  - `Get-Icon` - Convert Nerd Font hex codes to icons

- **Robust Error Handling**
  - Graceful fallbacks for WMI/CIM query failures
  - Registry access error handling
  - Performance counter fallbacks
  - Disk and process enumeration error handling

- **CSV Test Fixtures**
  - 14 CPU configurations (Intel, AMD, various generations)
  - 10 Windows version configurations
  - 9 RAM configurations (DDR3/4/5, various sizes)
  - 8 disk configurations (different sizes and types)

### Changed
- Draw-ProgressBar now clamps percentage to 0-100 range
- Get-Icon always returns string type for consistency
- Optimized CPU load detection (WMI first, then Get-Counter fallback)

### Fixed
- Draw-ProgressBar crashes on negative or >100% values
- Get-Icon type inconsistency ([char] vs [string])
- CPU load detection edge cases

### Performance
- **Startup time:** 2.9s → 1.6-1.8s (44% improvement with cache hit)
- Module import: ~100ms
- Cache load: <10ms
- Cache miss: ~2.9s (generates cache for next run)

### Tested Platforms
- Windows 11 Home 24H2 (Build 26100) ✅
- Windows 10 (experimental)
- macOS (PowerShell 7+) - experimental
- Linux (PowerShell 7+) - experimental

## [0.1.0] - 2025-01-XX

### Added
- Project initialization
- Basic module structure
- Mock implementations for Zsh and Bash

---

**Legend:**
- `Added` - New features
- `Changed` - Changes in existing functionality
- `Deprecated` - Soon-to-be removed features
- `Removed` - Removed features
- `Fixed` - Bug fixes
- `Security` - Vulnerability fixes
