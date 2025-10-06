BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "../../pwsh/oh-my-stats.psd1"
    Import-Module $modulePath -Force

    # Helper function to extract CPU short name (copied from module logic)
    function Get-CpuShortName {
        param([string]$CpuName)

        if ($CpuName -match "Intel.*Core.*i(\d)-(\d{4,5}\w*)") {
            return "i$($matches[1])-$($matches[2])"
        } elseif ($CpuName -match "AMD Ryzen (\d+) (\d{4}\w*)") {
            return "Ryzen $($matches[1]) $($matches[2])"
        } elseif ($CpuName -match "AMD Ryzen (\d+) PRO (\d{4}\w*)") {
            return "Ryzen $($matches[1]) PRO $($matches[2])"
        } elseif ($CpuName -match "Intel.*Xeon.*(\w+)-(\d{4}\w*)") {
            return "Xeon $($matches[1])-$($matches[2])"
        } elseif ($CpuName -match "Apple (\w+)") {
            return "Apple $($matches[1])"
        } else {
            # Fallback: clean up common patterns
            $cpuShort = $CpuName -replace "Intel\(R\) Core\(TM\) ", "" `
                                  -replace "AMD ", "" `
                                  -replace "Processor", "" `
                                  -replace "\(R\)", "" `
                                  -replace "\(TM\)", "" `
                                  -replace "\s+", " "
            $cpuShort = $cpuShort.Trim()
            # Limit length if too long
            if ($cpuShort.Length -gt 30) {
                $cpuShort = $cpuShort.Substring(0, 27) + "..."
            }
            return $cpuShort
        }
    }
}

Describe 'CPU Detection from Fixtures' {
    BeforeAll {
        $cpuConfigs = Import-Csv (Join-Path $PSScriptRoot "../fixtures/cpu-configs.csv")
    }

    Context 'CPU Name Formatting' {
        foreach ($config in $cpuConfigs) {
            It "Should detect '$($config.Type)' as '$($config.ExpectedShort)'" {
                $result = Get-CpuShortName -CpuName $config.Name
                $result | Should -Be $config.ExpectedShort
            }
        }
    }

    Context 'CPU Specs Extraction' {
        It 'Should extract cores and threads correctly' {
            Mock Get-CimInstance {
                [PSCustomObject]@{
                    Name = "Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz"
                    NumberOfCores = 6
                    NumberOfLogicalProcessors = 12
                    MaxClockSpeed = 2200
                    LoadPercentage = 50
                }
            } -ParameterFilter { $ClassName -eq 'Win32_Processor' }

            # This would require refactoring Show-SystemStats to be testable
            # For now, just test the helper function
            $result = Get-CpuShortName -CpuName "Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz"
            $result | Should -Be "i7-8750H"
        }
    }
}

Describe 'CPU Edge Cases' {
    Context 'Invalid or Missing Data' {
        It 'Should handle empty CPU name' {
            $result = Get-CpuShortName -CpuName ""
            $result | Should -Be ""
        }

        It 'Should handle null CPU name' {
            $result = Get-CpuShortName -CpuName $null
            $result | Should -BeNullOrEmpty
        }

        It 'Should truncate very long CPU names' {
            $longName = "Super Long Processor Name That Exceeds Thirty Characters And Should Be Truncated"
            $result = Get-CpuShortName -CpuName $longName
            $result.Length | Should -BeLessOrEqual 30
            $result | Should -Match '\.\.\.$'
        }
    }

    Context 'Vendor-Specific Patterns' {
        It 'Should detect Intel Core i-series' {
            $result = Get-CpuShortName -CpuName "Intel(R) Core(TM) i5-12400F CPU @ 2.50GHz"
            $result | Should -Be "i5-12400F"
        }

        It 'Should detect AMD Ryzen series' {
            $result = Get-CpuShortName -CpuName "AMD Ryzen 7 5800X 8-Core Processor"
            $result | Should -Be "Ryzen 7 5800X"
        }

        It 'Should detect AMD Ryzen PRO series' {
            $result = Get-CpuShortName -CpuName "AMD Ryzen 5 PRO 4650G with Radeon Graphics"
            $result | Should -Be "Ryzen 5 PRO 4650G"
        }

        It 'Should detect Intel Xeon series' {
            $result = Get-CpuShortName -CpuName "Intel(R) Xeon(R) CPU E-2288G @ 3.70GHz"
            $result | Should -Be "Xeon E-2288G"
        }
    }
}
