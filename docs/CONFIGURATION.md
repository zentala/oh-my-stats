# Configuration

Everything oh-my-stats shows, and how it looks, comes from one JSON file:
`~/.config/oh-my-stats/config.json`. Without it the module runs on the defaults
shipped in `config/default.json`.

## Basic Usage

```powershell
# Show stats with default config
Show-SystemStats

# Hide module status (Oh My Posh, PSReadLine, etc.)
Show-SystemStats -NoModuleStatus

# Use compact mode (coming soon)
Show-SystemStats -Compact

# Refresh cached system info
Show-SystemStats -RefreshCache

# Use custom config file
Show-SystemStats -ConfigPath "C:\my-config.json"
```

## Custom Configuration

Create `~/.config/oh-my-stats/config.json` to customize:

```json
{
  "version": "1.0",
  "modules": {
    "cpu": true,
    "ram": true,
    "disk": true,
    "uptime": true,
    "terminals": true,
    "processes": true,
    "shellModules": true
  },
  "icons": {
    "user": "0x1F464",
    "computer": "0x1F4BB",
    "windows": "0xF17A",
    "powershell": "0xE795",
    "cpu": "0xF4BC",
    "cpuChip": "0xF0E8",
    "ram": "0xEFC5",
    "ramFreq": "0xF035F",
    "disk": "0xF0A0",
    "folder": "0xF07C",
    "terminal": "0xF489",
    "process": "0xF085",
    "uptime": "0xF017"
  },
  "colors": {
    "user": "Cyan",
    "computer": "Green",
    "os": "Blue",
    "shell": "Magenta",
    "cpu": "Yellow",
    "ram": "Cyan",
    "disk": "Green",
    "info": "Gray",
    "details": "DarkGray",
    "success": "Green"
  },
  "display": {
    "progressBarWidth": 50
  }
}
```

## Performance Cache

Static system info (OS version, CPU model, RAM specs) is cached for 7 days in `~/.cache/oh-my-stats/system-info.json`:
Measured on a desktop machine (PowerShell 7.5, Windows 11):
- New shell, module import plus the first banner: ~0.28s
- Redraw in a shell that already imported the module: ~0.13s
- Rebuilding the cache: ~0.13-0.29s
- Force refresh: `Show-SystemStats -RefreshCache`

## Customization

### Icon Codes

Find Nerd Font icon codes at [nerdfonts.com](https://www.nerdfonts.com/cheat-sheet):
- Small icons (≤0xFFFF): e.g., `"0xF4BC"`
- Large icons (>0xFFFF): e.g., `"0x1F4BB"` (emoji range)

### Color Options

Available colors: `Black`, `DarkBlue`, `DarkGreen`, `DarkCyan`, `DarkRed`, `DarkMagenta`, `DarkYellow`, `Gray`, `DarkGray`, `Blue`, `Green`, `Cyan`, `Red`, `Magenta`, `Yellow`, `White`

### Helper Functions

```powershell
# Draw custom progress bars
Draw-ProgressBar -Percent 75 -Width 30

# Convert icon hex codes
Get-Icon -HexCode "0xF4BC"
```

## See also

- [README](../README.md) - install and first run
- [TROUBLESHOOTING](TROUBLESHOOTING.md) - when the icons or the config do not take effect
