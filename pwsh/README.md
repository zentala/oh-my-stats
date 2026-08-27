# oh-my-stats for PowerShell

PowerShell implementation of oh-my-stats - a system stats banner for your prompt.
Windows and PowerShell 7+; the stats come from WMI/CIM.

## 🚀 Installation

### From the PowerShell Gallery

```powershell
Install-Module -Name oh-my-stats -Scope CurrentUser

Add-Content $PROFILE "`nImport-Module oh-my-stats"
Add-Content $PROFILE "Show-SystemStats`n"
. $PROFILE
```

Package page: [powershellgallery.com/packages/oh-my-stats](https://www.powershellgallery.com/packages/oh-my-stats).

### Alternative: one-line installer

Downloads the module from GitHub, writes a default config and edits your profile:

```powershell
irm https://raw.githubusercontent.com/zentala/oh-my-stats/main/pwsh/install.ps1 | iex
```

### Alternative: run from a clone

See [CONTRIBUTING](https://github.com/zentala/oh-my-stats/blob/main/docs/CONTRIBUTING.md#3-development-setup).

## ⚙️ Configuration

Config location: `~/.config/oh-my-stats/config.json`

Override defaults by editing that file, or point at another one per call:

```powershell
Show-SystemStats -ConfigPath "C:/my-config.json"
```

Keys: `modules` (which rows to draw), `display` (bar width, compact mode, Nerd
Font on/off), `icons` / `unicodeIcons`, `colors`, `thresholds` (warning and
critical percentages), `performance` (caching).

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

See [CONTRIBUTING.md](https://github.com/zentala/oh-my-stats/blob/main/docs/CONTRIBUTING.md)

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
