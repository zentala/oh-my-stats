# Troubleshooting

## Icons Not Displaying

**Problem:** Icons show as `?` or empty boxes

**Solution:**
1. Install a [Nerd Font](https://www.nerdfonts.com/font-downloads) (e.g., CascadiaCode Nerd Font)
2. Set it as your terminal font:
   - **Windows Terminal:** Settings → Profiles → Defaults → Appearance → Font face
   - **VS Code Terminal:** Settings → Terminal › Integrated: Font Family
3. Restart your terminal

## Module Not Loading

**Problem:** `oh-my-stats module not loaded` warning

**Solution:**
```powershell
# Check module path is correct
Get-Module -ListAvailable oh-my-stats

# Verify import works
Import-Module C:\path\to\oh-my-stats\pwsh\oh-my-stats.psd1 -Verbose

# Check for errors
Import-Module oh-my-stats -Force -ErrorAction Continue
```

## Slow Performance

**Problem:** Stats take >3 seconds to load

**Solution:**
```powershell
# Check if cache exists
Test-Path ~/.cache/oh-my-stats/system-info.json

# Force cache refresh
Show-SystemStats -RefreshCache

# Check what's slow with Measure-Command
Measure-Command { Show-SystemStats -NoModuleStatus }
```

## WMI/CIM Errors

**Problem:** `Cannot access system information` error

**Solution:**
- Run PowerShell as Administrator
- Check WMI service: `Get-Service Winmgmt`
- Restart WMI: `Restart-Service Winmgmt -Force` (as Admin)

## CPU Load Shows 0%

**Problem:** CPU always shows 0% usage

**Solution:** Performance counters may be disabled. The module will attempt to use `Get-Counter` as fallback, or display 0% if unavailable.

## See also

- [README](../README.md) - install and first run
- [CONFIGURATION](CONFIGURATION.md) - every config key, icon code and color
- [TESTING](TESTING.md) - running the test suite
