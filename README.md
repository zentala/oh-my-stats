# oh-my-stats

> 🎨 Beautiful, cross-platform system stats for your terminal

A neofetch-like system information display tool that works with **PowerShell**, **Zsh**, **Bash**, and **Fish** shells. Designed to integrate seamlessly with modern terminals using Nerd Fonts.

![Platform Support](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20BSD-blue)
![Shell Support](https://img.shields.io/badge/shell-PowerShell%20%7C%20Zsh%20%7C%20Bash%20%7C%20Fish-green)
![License](https://img.shields.io/badge/license-MIT-orange)

## ✨ Features

- 🖥️ **Real-time system stats** - CPU, RAM, Disk usage with color-coded progress bars
- 🎨 **Beautiful UI** - Nerd Font icons and ANSI colors
- 🔧 **Customizable** - JSON config for modules, colors, and icons
- 🚀 **Fast loading** - Smart caching system, ~1.6s startup (44% faster!)
- 🧪 **Well tested** - 68 Pester tests covering CPU detection, error handling, caching
- 🌐 **Cross-platform** - Windows 11/10, macOS, Linux (PowerShell 7+)
- 🐚 **Multi-shell** - PowerShell (others coming soon)

## 📸 Screenshots

### PowerShell (Windows)
```
  👤  username @ 💻  HOSTNAME │ 🪟  Win11 x64 24H2 │ 󰨊  PowerShell v7.5.3

  󰻠  CPU ███████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 39% [󰘚 i7-8750H @ 2.2GHz 6c/12t]
  󰍛  RAM ███████████████████████████░░░░░░░░░░░░░░░░░░░░░░░ 55% (17.4GB/31.9GB) [󰑭 2667MHz]
  󰋊  HDD ██████████████████████████████████░░░░░░░░░░░░░░░░ 69% (645GB/930GB) [  C:\]

  [ 󰙯  19 terminals │ 󰑮  519 processes │ 󰥔  2d 18h uptime ]

    [✓] Oh My Posh
    [✓] PSReadLine
    [✓] Aliases & History
```

### Zsh (macOS/Linux) - *Coming Soon*
### Bash (Linux/BSD) - *Coming Soon*

## 📋 Requirements

### PowerShell (All platforms)
- PowerShell 7.x+ ([Install](https://github.com/PowerShell/PowerShell))
- [Nerd Font](https://www.nerdfonts.com/) (e.g., CascadiaCode, FiraCode)
- [Oh My Posh](https://ohmyposh.dev/) (optional)
- [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) (optional)

### Zsh (macOS/Linux)
- Zsh 5.8+
- Nerd Font installed

### Bash (Linux/BSD)
- Bash 4.0+
- Nerd Font installed

## 🚀 Installation

### PowerShell (Windows/macOS/Linux)

**Method 1: Clone and Import**
```powershell
# Clone repository
git clone https://github.com/zentala/oh-my-stats.git
cd oh-my-stats

# Test it out
Import-Module ./pwsh/oh-my-stats.psd1
Show-SystemStats

# Add to your profile permanently
Add-Content $PROFILE "`nImport-Module C:\path\to\oh-my-stats\pwsh\oh-my-stats.psd1"
Add-Content $PROFILE "Show-SystemStats`n"
```

**Method 2: Direct Download**
```powershell
# Download to PowerShell modules directory
$modulePath = "$HOME\Documents\PowerShell\Modules\oh-my-stats"
git clone https://github.com/zentala/oh-my-stats.git $modulePath

# Add to profile
Add-Content $PROFILE "`nImport-Module oh-my-stats"
Add-Content $PROFILE "Show-SystemStats`n"

# Reload profile
. $PROFILE
```

### Zsh / Bash
```bash
# Coming soon - PowerShell support only for now
```

## ⚙️ Configuration

### Basic Usage

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

### Custom Configuration

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

### Performance Cache

Static system info (OS version, CPU model, RAM specs) is cached for 7 days in `~/.cache/oh-my-stats/system-info.json`:
- First run: ~2.9s (generates cache)
- Subsequent runs: ~1.6s (44% faster!)
- Force refresh: `Show-SystemStats -RefreshCache`

## 🎨 Customization

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

## 🔧 Troubleshooting

### Icons Not Displaying

**Problem:** Icons show as `?` or empty boxes

**Solution:**
1. Install a [Nerd Font](https://www.nerdfonts.com/font-downloads) (e.g., CascadiaCode Nerd Font)
2. Set it as your terminal font:
   - **Windows Terminal:** Settings → Profiles → Defaults → Appearance → Font face
   - **VS Code Terminal:** Settings → Terminal › Integrated: Font Family
3. Restart your terminal

### Module Not Loading

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

### Slow Performance

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

### WMI/CIM Errors

**Problem:** `Cannot access system information` error

**Solution:**
- Run PowerShell as Administrator
- Check WMI service: `Get-Service Winmgmt`
- Restart WMI: `Restart-Service Winmgmt -Force` (as Admin)

### CPU Load Shows 0%

**Problem:** CPU always shows 0% usage

**Solution:** Performance counters may be disabled. The module will attempt to use `Get-Counter` as fallback, or display 0% if unavailable.

## 🧪 Testing

Run the comprehensive test suite:

```powershell
# Install Pester if needed
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run all tests (68 tests)
Invoke-Pester -Path ./tests/pwsh/

# Run specific test file
Invoke-Pester -Path ./tests/pwsh/cpu-detection.Tests.ps1 -Output Detailed
```

**Test coverage:**
- ✅ CPU detection (Intel, AMD, edge cases)
- ✅ Windows version detection
- ✅ Helper functions (Draw-ProgressBar, Get-Icon)
- ✅ Error handling (WMI failures, registry access, disk errors)
- ✅ Cache functionality

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) for:
- Code style guidelines
- Pull request process
- Development setup
- Testing requirements

### Development Roadmap

**Current Status: v1.0 (Windows PowerShell)**
- [x] PowerShell module (Windows) ✅
- [x] Error handling & robustness ✅
- [x] Performance caching (44% faster) ✅
- [x] Comprehensive test suite (68 tests) ✅
- [x] Documentation ✅
- [ ] CI/CD (GitHub Actions)
- [ ] PowerShell Gallery release
- [ ] Package managers (Scoop, Winget)

**Future:**
- [ ] PowerShell (macOS/Linux support)
- [ ] Zsh support
- [ ] Bash support
- [ ] Fish support
- [ ] Theme engine

## 📄 License

[MIT License](LICENSE) - Free to use and modify

## 🙏 Credits

Inspired by [neofetch](https://github.com/dylanaraps/neofetch), [fastfetch](https://github.com/fastfetch-cli/fastfetch), and the PowerShell community.

---

**Made with ❤️ by [Paweł Żentała](https://github.com/zentala)**
