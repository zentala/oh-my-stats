# oh-my-stats

> 🎨 Beautiful, cross-platform system stats for your terminal

A neofetch-like system information display tool that works with **PowerShell**, **Zsh**, **Bash**, and **Fish** shells. Designed to integrate seamlessly with modern terminals using Nerd Fonts.

![Platform Support](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20BSD-blue)
![Shell Support](https://img.shields.io/badge/shell-PowerShell%20%7C%20Zsh%20%7C%20Bash%20%7C%20Fish-green)
![License](https://img.shields.io/badge/license-MIT-orange)

## ✨ Features

- 🖥️ **Real-time system stats** - CPU, RAM, Disk usage with progress bars
- 🎨 **Beautiful UI** - Nerd Font icons and color-coded metrics
- 🔧 **Customizable** - JSON config for modules, colors, and themes
- 🚀 **Fast loading** - Async module loading, <3s startup
- 🌐 **Cross-platform** - Windows, macOS, Linux, BSD
- 🐚 **Multi-shell** - PowerShell, Zsh, Bash, Fish

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

## 🚀 Quick Start

### PowerShell
```powershell
# Clone repository
git clone https://github.com/zentala/oh-my-stats.git
cd oh-my-stats/pwsh

# Install
./install.ps1

# Or manual: Add to your $PROFILE
Import-Module ./oh-my-stats.psm1
Show-SystemStats
```

### Zsh
```bash
# Coming soon
```

### Bash
```bash
# Coming soon
```

## ⚙️ Configuration

Create `~/.config/oh-my-stats/config.json`:

```json
{
  "modules": {
    "cpu": true,
    "ram": true,
    "disk": true,
    "uptime": true,
    "terminals": true,
    "processes": true
  },
  "theme": "default",
  "icons": {
    "cpu": "0xF4BC",
    "ram": "0xEFC5",
    "disk": "0xF0A0"
  },
  "display": {
    "showPercentageColors": true,
    "progressBarWidth": 50
  }
}
```

## 🎨 Themes

- `default` - Balanced colors
- `dracula` - Dark purple theme
- `nord` - Cool nordic theme
- Custom themes in `config/themes/`

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](docs/CONTRIBUTING.md)

### Development Roadmap

- [x] PowerShell (Windows) ✅
- [ ] PowerShell (macOS/Linux)
- [ ] Zsh support
- [ ] Bash support
- [ ] Fish support
- [ ] Config system
- [ ] Theme engine
- [ ] Package managers (Scoop, Homebrew, apt)

## 📄 License

[MIT License](LICENSE) - Free to use and modify

## 🙏 Credits

Inspired by [neofetch](https://github.com/dylanaraps/neofetch), [fastfetch](https://github.com/fastfetch-cli/fastfetch), and the PowerShell community.

---

**Made with ❤️ by [Paweł Żentała](https://github.com/zentala)**
