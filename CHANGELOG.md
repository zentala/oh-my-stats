# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Updated documentation with comprehensive guides

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
