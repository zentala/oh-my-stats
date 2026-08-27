# oh-my-stats

[![Tests](https://github.com/zentala/oh-my-stats/actions/workflows/test.yml/badge.svg)](https://github.com/zentala/oh-my-stats/actions/workflows/test.yml)
[![Release](https://github.com/zentala/oh-my-stats/actions/workflows/release.yml/badge.svg)](https://github.com/zentala/oh-my-stats/actions/workflows/release.yml)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/oh-my-stats?label=PSGallery)](https://www.powershellgallery.com/packages/oh-my-stats)
[![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-blue)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)](https://github.com/zentala/oh-my-stats)
[![License](https://img.shields.io/badge/license-MIT-orange)](LICENSE)

> 🎨 A system stats banner for your PowerShell prompt

A neofetch-like banner for **PowerShell 7 on Windows** for terminals with Nerd Fonts.

<img src="https://cdn.zentala.agency/terminal/pwsh.png" alt="PowerShell Terminal Screenshot" style="max-width: 700px; height: auto;">

## ✨ Features

- 🖥️ **Real-time system stats** - CPU, RAM, Disk usage with color-coded progress bars
- 🎨 **Beautiful UI** - Nerd Font icons and ANSI colors
- 🔧 **Customizable** - JSON config for modules, colors, and icons
- 🚀 **Fast loading** - Static system info is cached, so the banner costs ~0.3s at shell startup
- 🧪 **Well tested** - 99 Pester tests covering CPU detection, error handling, caching
- 🪟 **Windows** - Windows 10/11 on PowerShell 7+ (stats come from WMI/CIM)

## 🚀 Installation

### PowerShell (Windows)

You need PowerShell 7.x+ ([install](https://github.com/PowerShell/PowerShell)) and a
[Nerd Font](https://www.nerdfonts.com/) - CascadiaCode or FiraCode, for example - set
as your terminal font.

#### From the PowerShell Gallery

```powershell
Install-Module -Name oh-my-stats -Scope CurrentUser
```

<details>
<summary>Show the banner on every new prompt</summary>

```powershell
Add-Content $PROFILE "`nImport-Module oh-my-stats"
Add-Content $PROFILE "Show-SystemStats`n"
```

Update later with `Update-Module oh-my-stats`. Package page:
[powershellgallery.com/packages/oh-my-stats](https://www.powershellgallery.com/packages/oh-my-stats).

</details>

#### Alternative: one-line installer

Skips the Gallery. Downloads the module from GitHub, writes a default config to
`~/.config/oh-my-stats/`, and adds the two profile lines for you - your existing
profile is backed up first:

```powershell
irm https://raw.githubusercontent.com/zentala/oh-my-stats/main/pwsh/install.ps1 | iex
```

#### Alternative: run from a clone

For working on the module itself - see
[CONTRIBUTING](docs/CONTRIBUTING.md#3-development-setup).

## ⚙️ Configuration

It runs on defaults out of the box. The common switches:

```powershell
Show-SystemStats -NoModuleStatus            # hide the module row
Show-SystemStats -RefreshCache              # rebuild the cached system info
Show-SystemStats -ConfigPath "C:/my.json"   # use another config file
```

To change which rows show up, the colors, the icons or the bar width, drop a
`config.json` into `~/.config/oh-my-stats/` - every key is listed in
[docs/CONFIGURATION.md](docs/CONFIGURATION.md).

## 📚 Docs

- [Configuration](docs/CONFIGURATION.md) - config keys, icon codes, colors, helper functions
- [Troubleshooting](docs/TROUBLESHOOTING.md) - icons as `?`, module not loading, slow start, WMI errors
- [Testing](docs/TESTING.md) - running the suite, test matrix, coverage goals
- [Contributing](docs/CONTRIBUTING.md) - development setup and code style

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) for:
- Code style guidelines
- Pull request process
- Development setup
- Testing requirements

## 📄 License

[MIT License](LICENSE) - Free to use and modify

## 🙏 Credits

Inspired by [neofetch](https://github.com/dylanaraps/neofetch), [fastfetch](https://github.com/fastfetch-cli/fastfetch), and the PowerShell community.

---

**Made with ❤️ by [Paweł Żentała](https://github.com/zentala)**
