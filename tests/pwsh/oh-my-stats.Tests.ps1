BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "../../pwsh/oh-my-stats.psd1"
    Import-Module $modulePath -Force
}

Describe 'oh-my-stats Module' {
    Context 'Module Loading' {
        It 'Should import without errors' {
            { Import-Module $modulePath -Force } | Should -Not -Throw
        }

        It 'Should export Show-SystemStats function' {
            $commands = Get-Command -Module oh-my-stats
            $commands.Name | Should -Contain 'Show-SystemStats'
        }

        It 'Should have valid manifest' {
            $manifest = Test-ModuleManifest -Path $modulePath
            $manifest.Version | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Show-SystemStats Function' {
        It 'Should execute without errors' {
            { Show-SystemStats -NoModuleStatus } | Should -Not -Throw
        }

        It 'Should accept -Compact parameter' {
            { Show-SystemStats -Compact -NoModuleStatus } | Should -Not -Throw
        }

        It 'Should accept custom config path' {
            $configPath = Join-Path $PSScriptRoot "../../config/default.json"
            { Show-SystemStats -ConfigPath $configPath -NoModuleStatus } | Should -Not -Throw
        }
    }

    Context 'Configuration' {
        It 'Should load default config' {
            $configPath = Join-Path $PSScriptRoot "../../config/default.json"
            $config = Get-Content $configPath | ConvertFrom-Json
            $config.version | Should -Not -BeNullOrEmpty
        }

        It 'Should have all required config sections' {
            $configPath = Join-Path $PSScriptRoot "../../config/default.json"
            $config = Get-Content $configPath | ConvertFrom-Json
            $config.modules | Should -Not -BeNullOrEmpty
            $config.icons | Should -Not -BeNullOrEmpty
            $config.colors | Should -Not -BeNullOrEmpty
        }

        It 'Should validate icon hex codes' {
            $configPath = Join-Path $PSScriptRoot "../../config/default.json"
            $config = Get-Content $configPath | ConvertFrom-Json
            $config.icons.cpu | Should -Match '^0x[0-9A-F]+$'
        }
    }

    Context 'Cross-Platform Support' {
        It 'Should detect OS correctly' {
            $IsWindows -or $IsMacOS -or $IsLinux | Should -Be $true
        }

        It 'Should work on current platform' {
            { Show-SystemStats -NoModuleStatus } | Should -Not -Throw
        }
    }
}
