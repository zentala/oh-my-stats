@{
    ModuleVersion = '1.1.1'
    GUID = '8a7b9c5d-4e3f-2a1b-9c8d-7e6f5a4b3c2d'
    Author = 'Paweł Żentała'
    CompanyName = 'oh-my-stats'
    Copyright = '(c) 2025 Paweł Żentała. All rights reserved.'
    Description = 'Neofetch-style system stats for your PowerShell prompt: CPU, RAM and disk as colour-coded bars, plus OS, uptime and process counts. Nerd Font icons with a plain Unicode fallback, JSON config, and a cache that keeps the banner off your startup time. Windows only (reads WMI/CIM).'
    PowerShellVersion = '7.0'

    RootModule = 'oh-my-stats.psm1'

    FunctionsToExport = @('Show-SystemStats', 'Draw-ProgressBar', 'Get-Icon')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'Stats', 'Neofetch', 'System', 'Monitor', 'Dashboard', 'NerdFont', 'Prompt', 'Profile', 'Windows')
            LicenseUri = 'https://github.com/zentala/oh-my-stats/blob/main/LICENSE'
            ProjectUri = 'https://github.com/zentala/oh-my-stats'
            IconUri = 'https://raw.githubusercontent.com/zentala/oh-my-stats/main/screenshots/icon.png'
            ReleaseNotes = 'https://github.com/zentala/oh-my-stats/blob/main/CHANGELOG.md'
        }
    }
}
