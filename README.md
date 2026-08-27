# oh-my-stats

[![Tests](https://github.com/zentala/oh-my-stats/actions/workflows/test.yml/badge.svg)](https://github.com/zentala/oh-my-stats/actions/workflows/test.yml)
[![Release](https://github.com/zentala/oh-my-stats/actions/workflows/release.yml/badge.svg)](https://github.com/zentala/oh-my-stats/actions/workflows/release.yml)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/oh-my-stats?label=PSGallery)](https://www.powershellgallery.com/packages/oh-my-stats)
[![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-blue)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey)](https://github.com/zentala/oh-my-stats)
[![License](https://img.shields.io/badge/license-MIT-orange)](LICENSE)

> 🎨 A system stats banner for your PowerShell prompt

A neofetch-like banner for **PowerShell 7 on Windows**, built for terminals with Nerd Fonts. Zsh, Bash and Fish ports are planned, not written.

<img src="https://cdn.zentala.agency/terminal/pwsh.png" alt="PowerShell Terminal Screenshot" style="max-width: 700px; height: auto;">

## ✨ Features

- 🖥️ **Real-time system stats** - CPU, RAM, Disk usage with color-coded progress bars
- 🎨 **Beautiful UI** - Nerd Font icons and ANSI colors
- 🔧 **Customizable** - JSON config for modules, colors, and icons
- 🚀 **Fast loading** - Smart caching system, ~1.6s startup (44% faster!)
- 🧪 **Well tested** - 99 Pester tests covering CPU detection, error handling, caching
- 🪟 **Windows** - Windows 10/11 on PowerShell 7+ (stats come from WMI/CIM)
- 🐚 **Multi-shell** - PowerShell today; Zsh, Bash and Fish planned

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

### Zsh / Bash

Not written yet. PowerShell only for now.

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

## 🧩 Works well with

None of these are required - oh-my-stats runs on its own, and picks them up if
they are there:

- [Oh My Posh](https://ohmyposh.dev/) - prompt theming
- [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) - file icons in listings
- [PSReadLine](https://github.com/PowerShell/PSReadLine) - history and completion

## 🤝 Contributing

Contributions welcome! Please read [CONTRIBUTING.md](docs/CONTRIBUTING.md) for:
- Code style guidelines
- Pull request process
- Development setup
- Testing requirements

### Development Roadmap

**Current status: v1.1.1 (Windows, PowerShell 7+)**
- [x] PowerShell module (Windows)
- [x] Error handling & robustness
- [x] Performance caching (44% faster)
- [x] Test suite (99 tests)
- [x] Documentation
- [x] CI/CD (GitHub Actions)
- [x] PowerShell Gallery release
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
