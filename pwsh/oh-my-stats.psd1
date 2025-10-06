@{
    ModuleVersion = '1.0.0'
    GUID = '8a7b9c5d-4e3f-2a1b-9c8d-7e6f5a4b3c2d'
    Author = 'Paweł Żentała'
    CompanyName = 'oh-my-stats'
    Copyright = '(c) 2025 Paweł Żentała. All rights reserved.'
    Description = 'Cross-platform system statistics display for PowerShell with Nerd Font icons'
    PowerShellVersion = '7.0'

    RootModule = 'oh-my-stats.psm1'

    FunctionsToExport = @('Show-SystemStats', 'Draw-ProgressBar', 'Get-Icon')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'Stats', 'Neofetch', 'System', 'Monitor', 'NerdFont', 'Windows', 'Linux', 'macOS')
            LicenseUri = 'https://github.com/zentala/oh-my-stats/blob/main/LICENSE'
            ProjectUri = 'https://github.com/zentala/oh-my-stats'
            IconUri = 'https://raw.githubusercontent.com/zentala/oh-my-stats/main/screenshots/icon.png'
            ReleaseNotes = 'Initial release with Windows support'
        }
    }
}
