# Testing Strategy - oh-my-stats

## Overview

oh-my-stats uses a multi-layered testing approach to ensure reliability across platforms, shells, and system configurations.

## Test Levels

### 1. Unit Tests (Pester)
**Location:** `tests/pwsh/oh-my-stats.Tests.ps1`

**Coverage:**
- Module loading and exports
- Configuration file loading
- Function parameter validation
- Icon conversion (Get-Icon)
- Progress bar rendering (Draw-ProgressBar)

**Run locally:**
```powershell
Invoke-Pester ./tests/pwsh/ -Output Detailed
```

### 2. Integration Tests
**Location:** `tests/pwsh/integration.Tests.ps1` (TODO)

**Coverage:**
- Full system stats display
- Config customization
- Multi-platform OS detection
- CPU vendor detection (Intel, AMD, Apple)
- Error handling for missing modules

### 3. Performance Tests (Pester)
**Location:** `tests/pwsh/performance.Tests.ps1`

Wall-clock is not asserted in CI — a shared runner is too noisy, and a test that fails
on a slow morning teaches nothing. What is asserted is the **behaviour** that makes the
module fast: on a cache hit the static queries must not run at all.

**Coverage:**
- Cache primitives: `Test-CacheValid` (missing file, fresh, stale past the 7 day TTL),
  `Get-SystemInfoCache` (missing, corrupt JSON, stale), `Save-SystemInfoCache` round-trip
- Query routing: a warm cache skips `Win32_PhysicalMemory` and the Windows version
  registry key, and drops `Win32_Processor` from two calls to one (load only)
- A cold run and `-RefreshCache` do make those queries
- Cache lifecycle: written on a cold run, left untouched on a warm run, rewritten by
  `-RefreshCache`, rebuilt when stale, and a corrupt file does not crash the module

**Sandbox:** the module resolves its cache path from `$HOME`, so these tests inject a
throwaway `$HOME` into the module scope. The real `~/.cache/oh-my-stats` is never read,
written, or deleted.

**Stopwatch:** one test in the `Performance`-tagged `Describe` measures a cold run
against the median of three warm runs and prints both numbers. It is skipped when
`$env:CI` is set. Run it locally:

```powershell
Invoke-Pester ./tests/pwsh/performance.Tests.ps1 -Output Detailed
# cold: 2658 ms | warm (median of 3): 1577 ms | saved: 40.7%
```

The assertion is relative (warm beats cold), not an absolute threshold — thresholds
depend on the machine and turn into flaky tests.

### 4. Cross-Platform Tests (CI/CD)
**Platforms tested:**
- Windows (latest)
- Ubuntu Linux (latest)
- macOS (latest)

**GitHub Actions:** `.github/workflows/test-pwsh.yml`

## Test Matrix

| Test Type | Windows | Linux | macOS | Frequency |
|-----------|---------|-------|-------|-----------|
| Unit Tests | ✅ | ✅ | ✅ | Every PR |
| Performance (cache behaviour) | ✅ | — | — | Every PR |
| Integration | ✅ | ✅ | ✅ | Every PR |
| Module Import | ✅ | ✅ | ✅ | Every commit |
| Show-SystemStats | ✅ | ✅ | ✅ | Every commit |
| Config Loading | ✅ | ✅ | ✅ | Every commit |

## CPU Vendor Test Cases

### Intel
- [ ] Core i3/i5/i7/i9 (8th-14th gen)
- [ ] Xeon processors
- [ ] Legacy Core 2 Duo

### AMD
- [ ] Ryzen 3/5/7/9
- [ ] Ryzen PRO
- [ ] Threadripper

### Apple
- [ ] M1/M2/M3 (Pro/Max/Ultra)

### Fallback
- [ ] Unknown/Generic CPUs

## Windows Version Test Cases

- [ ] Windows 11 (builds 22000+)
  - [ ] Home
  - [ ] Pro
  - [ ] Enterprise
  - [ ] Education
- [ ] Windows 10 (builds 10240-19045)
  - [ ] All editions
- [ ] Windows Server (if applicable)

## Release Testing Strategy

### Pre-Release Checklist

1. **Automated Tests** (GitHub Actions)
   - ✅ Unit tests pass on all platforms
   - ✅ Integration tests pass
   - ✅ Module imports successfully
   - ✅ Show-SystemStats executes without errors
   - ✅ Config loads correctly

2. **Manual Testing** (Before tagging)
   ```powershell
   # Test on local machine
   Import-Module ./pwsh/oh-my-stats.psd1 -Force
   Show-SystemStats

   # Test with custom config
   Show-SystemStats -ConfigPath ./config/default.json

   # Test compact mode
   Show-SystemStats -Compact

   # Test without module status
   Show-SystemStats -NoModuleStatus
   ```

3. **Version Bump**
   - Update `pwsh/oh-my-stats.psd1` version
   - Update `CHANGELOG.md`
   - Update `config/default.json` version

4. **Create Tag**
   ```bash
   git tag -a v1.1.0 -m "Release v1.1.0"
   git push origin v1.1.0
   ```

5. **Release Pipeline** (Automated)
   - Test job runs on all platforms
   - If tests pass → Create GitHub Release
   - Optionally publish to PowerShell Gallery

## CI/CD Pipeline Flow

```
┌─────────────────┐
│  Push to main   │
│  or create tag  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Run Tests     │◄─── Windows/Linux/macOS
│  (Parallel)     │
└────────┬────────┘
         │
    ┌────┴────┐
    │  Pass?  │
    └────┬────┘
         │
    ┌────▼────┐
    │   Yes   │
    └────┬────┘
         │
         ▼
┌─────────────────┐
│ Create Release  │
│  (if tag push)  │
└─────────────────┘
```

## Test Coverage Goals

| Component | Target Coverage | Current |
|-----------|-----------------|---------|
| Core Functions | 90% | ~60% |
| Config Loading | 100% | 100% |
| Icon Rendering | 80% | ~40% |
| OS Detection | 90% | ~70% |
| CPU Detection | 85% | ~50% |

## Adding New Tests

### Unit Test Template
```powershell
Describe 'Feature Name' {
    Context 'Scenario' {
        It 'Should do expected behavior' {
            # Arrange
            $input = "test"

            # Act
            $result = Test-Function $input

            # Assert
            $result | Should -Be "expected"
        }
    }
}
```

### Integration Test Template
```powershell
Describe 'Full System Test' {
    BeforeAll {
        Import-Module ./pwsh/oh-my-stats.psd1 -Force
    }

    It 'Should display stats without errors' {
        { Show-SystemStats -NoModuleStatus } | Should -Not -Throw
    }
}
```

## Performance Benchmarks

**Target:** `Show-SystemStats` should execute in < 3s

| Platform | Target | Cold (cache miss) | Warm (cache hit) |
|----------|--------|-------------------|------------------|
| Windows | < 3s | ~2.7s | ~1.6s |
| macOS | < 3s | TBD | TBD |
| Linux | < 3s | TBD | TBD |

Measured on an i7-14700 by the stopwatch test in `performance.Tests.ps1`. Run it
yourself rather than trusting the table — the numbers are machine-specific.

## Future Testing Improvements

- [ ] Add integration tests for all CPU vendors
- [ ] Add tests for Windows Server
- [x] Add performance regression tests (`tests/pwsh/performance.Tests.ps1`)
- [ ] Add memory leak detection
- [ ] Add stress tests (repeated execution)
- [ ] Add screenshot regression tests
- [ ] Mock system info for consistent testing
- [ ] Add Zsh/Bash testing when implemented

## Running Tests Locally

### Quick Test
```powershell
# Test module loads
Import-Module ./pwsh/oh-my-stats.psd1
Get-Module oh-my-stats
```

### Full Test Suite
```powershell
# Install Pester if needed
Install-Module Pester -Force -SkipPublisherCheck

# Run all tests
Invoke-Pester ./tests/pwsh/ -Output Detailed

# Run with coverage
Invoke-Pester ./tests/pwsh/ -CodeCoverage ./pwsh/*.psm1
```

### Test Specific Feature
```powershell
Invoke-Pester ./tests/pwsh/oh-my-stats.Tests.ps1 -Tag "Config"
```

## Continuous Integration

**On every PR:**
- All unit tests must pass
- Code must pass PSScriptAnalyzer

**On every tag push:**
- All tests must pass on all platforms
- GitHub Release is created automatically

**Manual approval required for:**
- Publishing to PowerShell Gallery

## Test Data & Fixtures

Mock data for testing CPU detection:
```powershell
# tests/fixtures/cpu-data.json
{
  "intel_i7": "Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz",
  "amd_ryzen": "AMD Ryzen 7 5800X 8-Core Processor",
  "apple_m1": "Apple M1"
}
```

## Reporting Issues

When filing bugs, include:
1. PowerShell version (`$PSVersionTable`)
2. OS version
3. CPU model
4. Test output
5. Expected vs actual behavior

---

**Last Updated:** 2026-08-26
**Status:** ✅ Active
