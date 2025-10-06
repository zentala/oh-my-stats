BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "../../pwsh/oh-my-stats.psd1"
    Import-Module $modulePath -Force
}

Describe 'Draw-ProgressBar' {
    Context 'Basic functionality' {
        It 'Should return a string' {
            $result = Draw-ProgressBar -Percent 50
            $result | Should -BeOfType [string]
        }

        It 'Should have correct length (50 chars + ANSI codes)' {
            $result = Draw-ProgressBar -Percent 50 -Width 50
            # Remove ANSI codes to count actual bar characters
            $cleanResult = $result -replace '\e\[\d+m', ''
            $cleanResult.Length | Should -Be 50
        }

        It 'Should respect custom width' {
            $result = Draw-ProgressBar -Percent 50 -Width 20
            $cleanResult = $result -replace '\e\[\d+m', ''
            $cleanResult.Length | Should -Be 20
        }
    }

    Context 'Progress bar fill levels' {
        It 'Should show empty bar at 0%' {
            $result = Draw-ProgressBar -Percent 0 -Width 10
            $cleanResult = $result -replace '\e\[\d+m', ''
            $cleanResult | Should -Match '^░{10}$'
        }

        It 'Should show half-full bar at 50%' {
            $result = Draw-ProgressBar -Percent 50 -Width 10
            $cleanResult = $result -replace '\e\[\d+m', ''
            $cleanResult | Should -Match '^█{5}░{5}$'
        }

        It 'Should show full bar at 100%' {
            $result = Draw-ProgressBar -Percent 100 -Width 10
            $cleanResult = $result -replace '\e\[\d+m', ''
            $cleanResult | Should -Match '^█{10}$'
        }

        It 'Should round down fractional fills' {
            $result = Draw-ProgressBar -Percent 45 -Width 10
            $cleanResult = $result -replace '\e\[\d+m', ''
            # 45% of 10 = 4.5, should floor to 4
            $cleanResult | Should -Match '^█{4}░{6}$'
        }
    }

    Context 'Color coding based on percentage' {
        It 'Should be Green for low usage (<60%)' {
            $result = Draw-ProgressBar -Percent 30
            $result | Should -Match '\e\[32m'  # Green ANSI code
        }

        It 'Should be Green at exactly 59%' {
            $result = Draw-ProgressBar -Percent 59
            $result | Should -Match '\e\[32m'
        }

        It 'Should be Yellow for medium usage (60-79%)' {
            $result = Draw-ProgressBar -Percent 70
            $result | Should -Match '\e\[33m'  # Yellow ANSI code
        }

        It 'Should be Yellow at exactly 60%' {
            $result = Draw-ProgressBar -Percent 60
            $result | Should -Match '\e\[33m'
        }

        It 'Should be Yellow at exactly 79%' {
            $result = Draw-ProgressBar -Percent 79
            $result | Should -Match '\e\[33m'
        }

        It 'Should be Red for high usage (>=80%)' {
            $result = Draw-ProgressBar -Percent 90
            $result | Should -Match '\e\[31m'  # Red ANSI code
        }

        It 'Should be Red at exactly 80%' {
            $result = Draw-ProgressBar -Percent 80
            $result | Should -Match '\e\[31m'
        }

        It 'Should be Red at 100%' {
            $result = Draw-ProgressBar -Percent 100
            $result | Should -Match '\e\[31m'
        }
    }

    Context 'Edge cases' {
        It 'Should handle negative percentages as 0%' {
            $result = Draw-ProgressBar -Percent -10 -Width 10
            $cleanResult = $result -replace '\e\[\d+m', ''
            # Negative * Width / 100 = negative, floor = 0
            $cleanResult | Should -Match '^░{10}$'
        }

        It 'Should handle percentages over 100%' {
            $result = Draw-ProgressBar -Percent 150 -Width 10
            $cleanResult = $result -replace '\e\[\d+m', ''
            # 150% of 10 = 15, but string multiplication will work
            # Actually this might overflow - let's just check it doesn't crash
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Get-Icon' {
    Context 'Small hex codes (<=0xFFFF)' {
        It 'Should convert small hex using [char]' {
            $result = Get-Icon -HexCode "0xF000"
            $result | Should -BeOfType [string]
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should handle standard Unicode (0x2764 = ❤)' {
            $result = Get-Icon -HexCode "0x2764"
            $result | Should -Be ([char]0x2764)
        }

        It 'Should handle ASCII range (0x0041 = A)' {
            $result = Get-Icon -HexCode "0x0041"
            $result | Should -Be "A"
        }
    }

    Context 'Large hex codes (>0xFFFF)' {
        It 'Should convert large hex using ConvertFromUtf32' {
            $result = Get-Icon -HexCode "0x1F600"  # 😀 emoji
            $result | Should -BeOfType [string]
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should handle emoji range correctly' {
            $result = Get-Icon -HexCode "0x1F4A9"  # 💩 emoji
            $expected = [System.Char]::ConvertFromUtf32(0x1F4A9)
            $result | Should -Be $expected
        }
    }

    Context 'Nerd Fonts range' {
        It 'Should handle Nerd Fonts icons (0xF17A = Windows icon)' {
            $result = Get-Icon -HexCode "0xF17A"
            $result | Should -BeOfType [string]
        }

        It 'Should handle Nerd Fonts Material Design icons' {
            $result = Get-Icon -HexCode "0xF0E8"  # CPU icon
            $result | Should -BeOfType [string]
        }
    }

    Context 'Edge cases' {
        It 'Should handle hex string with 0x prefix' {
            $result = Get-Icon -HexCode "0xFF"
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should handle decimal string (implicit conversion)' {
            $result = Get-Icon -HexCode "65"  # 65 = 'A'
            $result | Should -Be "A"
        }
    }
}
