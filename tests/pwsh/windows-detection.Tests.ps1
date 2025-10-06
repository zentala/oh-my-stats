BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "../../pwsh/oh-my-stats.psd1"
    Import-Module $modulePath -Force

    # Helper function to detect Windows version (copied from module logic)
    function Get-WindowsVersion {
        param(
            [int]$Build,
            [string]$DisplayVersion,
            [string]$Caption
        )

        # Detect Windows version by build number
        $winMajorVersion = if ($Build -ge 22000) { "Windows 11" } else { "Windows 10" }

        # Determine edition
        $winEdition = if ($Caption -match "Home") { "$winMajorVersion Home" }
        elseif ($Caption -match "Pro") { "$winMajorVersion Pro" }
        elseif ($Caption -match "Enterprise") { "$winMajorVersion Enterprise" }
        elseif ($Caption -match "Education") { "$winMajorVersion Education" }
        else { $winMajorVersion }

        # Use DisplayVersion if available, otherwise use build-based version
        if (-not $DisplayVersion) {
            if ($Build -ge 22631) { $DisplayVersion = "23H2" }
            elseif ($Build -ge 22621) { $DisplayVersion = "22H2" }
            elseif ($Build -ge 22000) { $DisplayVersion = "21H2" }
            elseif ($Build -ge 19045) { $DisplayVersion = "22H2" }
            elseif ($Build -ge 19044) { $DisplayVersion = "21H2" }
            elseif ($Build -ge 19043) { $DisplayVersion = "21H1" }
            elseif ($Build -ge 19042) { $DisplayVersion = "20H2" }
            else { $DisplayVersion = "Legacy" }
        }

        $osShort = $winEdition -replace "Windows 11", "Win11" -replace "Windows 10", "Win10"

        return @{
            Version = $DisplayVersion
            Edition = $winEdition
            Short = $osShort
        }
    }
}

Describe 'Windows Version Detection from Fixtures' {
    BeforeAll {
        $windowsConfigs = Import-Csv (Join-Path $PSScriptRoot "../fixtures/windows-configs.csv")
    }

    Context 'Version Detection' {
        foreach ($config in $windowsConfigs) {
            It "Should detect Build $($config.Build) as $($config.ExpectedVersion)" {
                $result = Get-WindowsVersion -Build $config.Build -DisplayVersion $config.DisplayVersion -Caption $config.Caption
                $result.Version | Should -Be $config.ExpectedVersion
            }
        }
    }

    Context 'Edition Detection' {
        foreach ($config in $windowsConfigs) {
            It "Should detect '$($config.Caption)' as '$($config.ExpectedEdition)'" {
                $result = Get-WindowsVersion -Build $config.Build -DisplayVersion $config.DisplayVersion -Caption $config.Caption
                $result.Edition | Should -Be $config.ExpectedEdition
            }
        }
    }

    Context 'Short Name Generation' {
        foreach ($config in $windowsConfigs) {
            It "Should generate short name '$($config.ExpectedShort)' for $($config.Type)" {
                $result = Get-WindowsVersion -Build $config.Build -DisplayVersion $config.DisplayVersion -Caption $config.Caption
                $result.Short | Should -Be $config.ExpectedShort
            }
        }
    }
}

Describe 'Windows Version Edge Cases' {
    Context 'Build Number Boundaries' {
        It 'Should detect Windows 11 for build 22000' {
            $result = Get-WindowsVersion -Build 22000 -DisplayVersion "" -Caption "Microsoft Windows 11 Pro"
            $result.Edition | Should -Match "Windows 11"
        }

        It 'Should detect Windows 10 for build 19999' {
            $result = Get-WindowsVersion -Build 19999 -DisplayVersion "" -Caption "Microsoft Windows 10 Pro"
            $result.Edition | Should -Match "Windows 10"
        }

        It 'Should detect Windows 11 for build 22631 (23H2)' {
            $result = Get-WindowsVersion -Build 22631 -DisplayVersion "" -Caption "Microsoft Windows 11 Home"
            $result.Version | Should -Be "23H2"
        }

        It 'Should detect Windows 11 for build 22621 (22H2)' {
            $result = Get-WindowsVersion -Build 22621 -DisplayVersion "" -Caption "Microsoft Windows 11 Pro"
            $result.Version | Should -Be "22H2"
        }
    }

    Context 'DisplayVersion Fallback' {
        It 'Should use DisplayVersion when provided' {
            $result = Get-WindowsVersion -Build 22631 -DisplayVersion "24H2" -Caption "Microsoft Windows 11 Home"
            $result.Version | Should -Be "24H2"
        }

        It 'Should fallback to build-based detection when DisplayVersion empty' {
            $result = Get-WindowsVersion -Build 22631 -DisplayVersion "" -Caption "Microsoft Windows 11 Home"
            $result.Version | Should -Be "23H2"
        }

        It 'Should detect Legacy for old builds' {
            $result = Get-WindowsVersion -Build 18000 -DisplayVersion "" -Caption "Microsoft Windows 10 Pro"
            $result.Version | Should -Be "Legacy"
        }
    }

    Context 'Edition Matching' {
        It 'Should match Home edition' {
            $result = Get-WindowsVersion -Build 22631 -DisplayVersion "23H2" -Caption "Microsoft Windows 11 Home"
            $result.Edition | Should -Be "Windows 11 Home"
        }

        It 'Should match Pro edition' {
            $result = Get-WindowsVersion -Build 22631 -DisplayVersion "23H2" -Caption "Microsoft Windows 11 Pro"
            $result.Edition | Should -Be "Windows 11 Pro"
        }

        It 'Should match Enterprise edition' {
            $result = Get-WindowsVersion -Build 22000 -DisplayVersion "21H2" -Caption "Microsoft Windows 11 Enterprise"
            $result.Edition | Should -Be "Windows 11 Enterprise"
        }

        It 'Should match Education edition' {
            $result = Get-WindowsVersion -Build 22631 -DisplayVersion "23H2" -Caption "Microsoft Windows 11 Education"
            $result.Edition | Should -Be "Windows 11 Education"
        }
    }
}
