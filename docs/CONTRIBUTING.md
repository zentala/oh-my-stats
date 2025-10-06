# Contributing to oh-my-stats

Thank you for your interest in contributing! 🎉

## Ways to Contribute

- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🔧 Submit pull requests
- 🌐 Add shell support (Zsh, Bash, Fish)
- 🎨 Create themes

## Getting Started

### 1. Fork & Clone

```bash
git clone https://github.com/YOUR_USERNAME/oh-my-stats.git
cd oh-my-stats
```

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### 3. Development Setup

#### PowerShell Development
```powershell
cd pwsh
Import-Module ./oh-my-stats.psd1
Show-SystemStats
```

#### Testing
```powershell
# Install Pester if needed
Install-Module Pester -Force -SkipPublisherCheck

# Run all tests (68 tests)
Invoke-Pester ./tests/pwsh/

# Run specific test file
Invoke-Pester ./tests/pwsh/cpu-detection.Tests.ps1 -Output Detailed

# Run with code coverage
Invoke-Pester ./tests/pwsh/ -CodeCoverage ./pwsh/*.psm1
```

**Test categories:**
- ✅ CPU detection (8 tests) - Intel, AMD, edge cases
- ✅ Windows version detection (11 tests) - Win10/11, builds
- ✅ Helper functions (26 tests) - Draw-ProgressBar, Get-Icon
- ✅ Main module (23 tests) - Error handling, cache, config

## Code Style

### PowerShell
- Follow [PowerShell Best Practices](https://github.com/PoshCode/PowerShellPracticeAndStyle)
- Use approved verbs: `Get-`, `Show-`, `Set-`, `Test-`, `Draw-`
- Use **PascalCase** for function names
- Use **camelCase** for variables
- Indent with **4 spaces** (no tabs)
- Maximum line length: **120 characters**
- Add comment-based help to functions
- Keep functions focused and under 100 lines when possible

**Example:**
```powershell
function Show-SystemStats {
    [CmdletBinding()]
    param(
        [switch]$NoModuleStatus,
        [string]$ConfigPath
    )

    # Try to load cached static data
    $cachedData = Get-SystemInfoCache

    if ($cachedData) {
        # Use cached static data
        $cpuName = $cachedData.CPU.Name
    } else {
        # Query all data (cache miss)
        $cpu = Get-CimInstance Win32_Processor
    }
}
```

### Error Handling
- Always use `try/catch` for external calls (CIM, registry, file I/O)
- Provide graceful fallbacks
- Use `Write-Verbose` for debugging info
- Use `Write-Warning` for non-critical issues
- Use `Write-Error` for critical failures

```powershell
try {
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop
} catch {
    Write-Error "Cannot access CPU information: $_"
    return
}
```

### Shell Scripts (Bash/Zsh)
- Use `shellcheck` for linting
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- POSIX-compliant when possible

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add macOS support for Show-SystemStats
fix: correct RAM calculation on Linux
docs: update installation instructions
test: add tests for config loading
chore: update dependencies
```

## Pull Request Process

1. **Update tests** - Add/update tests for new features
2. **Update docs** - Update README.md and relevant docs
3. **Update CHANGELOG** - Add entry to CHANGELOG.md
4. **Run tests** - Ensure all tests pass
5. **Create PR** - Use clear title and description

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation

## Testing
- [ ] Tested on Windows
- [ ] Tested on macOS
- [ ] Tested on Linux
- [ ] Added/updated tests
- [ ] All tests pass

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
- [ ] CHANGELOG.md updated
```

## Adding New Shell Support

Want to add support for Zsh, Bash, or Fish? Great! Here's how:

### 1. Structure

```
oh-my-stats/
├── [shell-name]/
│   ├── README.md
│   ├── oh-my-stats.[sh|zsh|fish]
│   ├── install.[sh|zsh|fish]
│   └── functions/
```

### 2. Required Functions

Every shell implementation must provide:

- `show_system_stats()` - Main display function
- `get_cpu_usage()` - CPU load detection
- `get_ram_usage()` - RAM usage detection
- `get_disk_usage()` - Disk usage detection
- `draw_progress_bar()` - Progress bar rendering
- `load_config()` - Config file loading

### 3. Config Compatibility

All implementations must use the same JSON config format from `config/default.json`

### 4. Testing

- Test on at least 2 different systems
- Verify Nerd Font icons display correctly
- Check performance (<3s load time)

## Icon Guidelines

When adding/changing icons:

1. Use Nerd Fonts: https://www.nerdfonts.com/cheat-sheet
2. Test with CascadiaCode Nerd Font
3. Verify icons display in:
   - Windows Terminal
   - iTerm2 (macOS)
   - GNOME Terminal (Linux)
4. Document hex codes in config

## Release Process

Maintainers will:

1. Update version in all manifests
2. Update CHANGELOG.md
3. Create git tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
4. Push tag: `git push origin v1.0.0`
5. GitHub Actions will auto-create release

## Questions?

- 💬 Open a [Discussion](https://github.com/zentala/oh-my-stats/discussions)
- 🐛 File an [Issue](https://github.com/zentala/oh-my-stats/issues)
- 📧 Email: pawel@zentala.io

---

**Thanks for contributing!** 🙏
