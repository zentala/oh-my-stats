# oh-my-stats for PowerShell

PowerShell implementation of oh-my-stats - a system stats banner for your prompt.
Windows and PowerShell 7+; the stats come from WMI/CIM.

## 🚀 Installation

### From the PowerShell Gallery

```powershell
Install-Module -Name oh-my-stats -Scope CurrentUser

Add-Content $PROFILE "`nImport-Module oh-my-stats"
Add-Content $PROFILE "Show-SystemStats`n"
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

Keys: `modules` (which rows to draw), `display` (bar width, Nerd Font on/off),
`icons` / `unicodeIcons`, `colors`.

## 🎨 Customization

Icon codes, colors, every config key and the helper functions:
[docs/CONFIGURATION.md](https://github.com/zentala/oh-my-stats/blob/main/docs/CONFIGURATION.md).

## 📦 Dependencies

- PowerShell 7.x+
- A Nerd Font, if you want the full icon set - see Configuration

## 🧪 Testing

The suite lives in the repo, not in this package:
[docs/TESTING.md](https://github.com/zentala/oh-my-stats/blob/main/docs/TESTING.md).

## 🤝 Contributing

See [CONTRIBUTING.md](https://github.com/zentala/oh-my-stats/blob/main/docs/CONTRIBUTING.md)

## 📝 Functions

### `Show-SystemStats`
Draw the stats banner.

**Parameters:**
- `-ConfigPath` - path to another config file
- `-NoModuleStatus` - hide the module row
- `-RefreshCache` - rebuild the cached system info

```powershell
Show-SystemStats -NoModuleStatus
```

### `Draw-ProgressBar`
```powershell
Draw-ProgressBar -Percent 75 -Width 30
```

### `Get-Icon`
```powershell
Get-Icon -HexCode "0xF4BC"
```

## 🐛 Troubleshooting

Icons as `?`, module not loading, slow start, WMI errors:
[docs/TROUBLESHOOTING.md](https://github.com/zentala/oh-my-stats/blob/main/docs/TROUBLESHOOTING.md).

## 📄 License

MIT License - see [LICENSE](https://github.com/zentala/oh-my-stats/blob/main/LICENSE)
