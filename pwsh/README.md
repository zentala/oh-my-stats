# oh-my-stats for PowerShell

PowerShell implementation of oh-my-stats - cross-platform system statistics display.

## 🚀 Installation

### Method 1: Automatic Install
```powershell
# Download and run installer
irm https://raw.githubusercontent.com/zentala/oh-my-stats/main/pwsh/install.ps1 | iex
```

### Method 2: Manual Install
```powershell
# Clone repository
git clone https://github.com/zentala/oh-my-stats.git
cd oh-my-stats/pwsh

# Import module in your $PROFILE
Add-Content $PROFILE "`nImport-Module $PWD/oh-my-stats.psm1"
Add-Content $PROFILE "Show-SystemStats"

# Reload profile
. $PROFILE
```

### Method 3: PowerShell Gallery (Coming Soon)
```powershell
Install-Module oh-my-stats -Scope CurrentUser
```

## ⚙️ Configuration

Config location: `~/.config/oh-my-stats/config.json`

Override default settings:
```powershell
# In your $PROFILE before Show-SystemStats
$OhMyStatsConfig = @{
    ProgressBarWidth = 60
    ShowUptime = $false
    Theme = "dracula"
}
```

## 🎨 Customization

### Change Icons
Edit `config.json`:
```json
{
  "icons": {
    "cpu": "0xF4BC",
    "ram": "0xEFC5"
  }
}
```

### Disable Modules
```json
{
  "modules": {
    "terminals": false,
    "processes": false
  }
}
```

## 📦 Dependencies

**Required:**
- PowerShell 7.x+
- Nerd Font installed

**Optional (auto-detected):**
- Oh My Posh
- PSReadLine
- Terminal-Icons

## 🧪 Testing

```powershell
# Run Pester tests
Invoke-Pester ./tests/pwsh/
```

## 🤝 Contributing

See [CONTRIBUTING.md](../docs/CONTRIBUTING.md)

## 📝 Functions

### `Show-SystemStats`
Display system statistics welcome screen

**Parameters:**
- `-Config` - Custom config path
- `-Compact` - Compact display mode
- `-NoModuleStatus` - Hide module status

**Example:**
```powershell
Show-SystemStats -Compact
```

### `Get-SystemInfo`
Get raw system information object

**Returns:** PSCustomObject with system stats

## 🐛 Troubleshooting

**Icons show as `?`:**
- Install a Nerd Font: https://www.nerdfonts.com/
- Set terminal font to the Nerd Font

**Slow loading:**
- Disable async loading in config
- Check module load times with `Measure-Command { Import-Module oh-my-stats }`

**Module not found:**
- Ensure module path is correct in `$PROFILE`
- Run `Get-Module -ListAvailable` to verify

## 📄 License

MIT License - see [LICENSE](../LICENSE)
