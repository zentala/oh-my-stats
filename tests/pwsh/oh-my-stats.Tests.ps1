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

    Context 'Error Handling - WMI/CIM Failures' {
        It 'Should handle Win32_OperatingSystem query failure gracefully' {
            Mock Get-CimInstance {
                throw "WMI service not available"
            } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }

            # Should write error and return without crashing
            { Show-SystemStats -NoModuleStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should handle Win32_Processor query failure gracefully' {
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_Processor') {
                    throw "Access denied"
                }
                # Let Win32_OperatingSystem work normally
                & (Get-Command Get-CimInstance -CommandType Cmdlet) @PSBoundParameters
            }

            { Show-SystemStats -NoModuleStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should use fallback when Win32_PhysicalMemory fails' {
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_PhysicalMemory') {
                    throw "RAM info not available"
                }
                # Let other queries work
                & (Get-Command Get-CimInstance -CommandType Cmdlet) @PSBoundParameters
            }

            # Should not throw, should use default RAM speed (DDR4)
            { Show-SystemStats -NoModuleStatus -WarningAction SilentlyContinue } | Should -Not -Throw
        }

        It 'Should handle CPU LoadPercentage = 0 by trying Get-Counter' {
            Mock Get-CimInstance {
                if ($ClassName -eq 'Win32_Processor') {
                    return [PSCustomObject]@{
                        Name = "Test CPU"
                        NumberOfCores = 4
                        NumberOfLogicalProcessors = 8
                        MaxClockSpeed = 3000
                        LoadPercentage = 0
                    }
                }
                & (Get-Command Get-CimInstance -CommandType Cmdlet) @PSBoundParameters
            }

            # Should attempt Get-Counter fallback (might fail in test env, that's ok)
            { Show-SystemStats -NoModuleStatus -WarningAction SilentlyContinue -Verbose } | Should -Not -Throw
        }
    }

    Context 'Error Handling - Registry Access' {
        It 'Should handle registry access denial gracefully' {
            Mock Get-ItemProperty {
                throw "Access denied to registry"
            } -ParameterFilter { $Path -like '*Windows NT\CurrentVersion*' }

            # Should fall back to "Unknown" build/version
            { Show-SystemStats -NoModuleStatus -WarningAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Error Handling - Disk Access' {
        It 'Should handle C: drive inaccessible' {
            Mock Get-PSDrive {
                throw "Drive not accessible"
            } -ParameterFilter { $Name -eq 'C' }

            # Should set disk values to 0 and continue
            { Show-SystemStats -NoModuleStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Error Handling - Performance Counters' {
        It 'Should handle Get-Counter failure gracefully' {
            Mock Get-Counter {
                throw "Performance counters not available"
            }

            # Should fallback to WMI LoadPercentage or use 0%
            { Show-SystemStats -NoModuleStatus -WarningAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Error Handling - Process Enumeration' {
        It 'Should handle Get-Process failure' {
            Mock Get-Process {
                throw "Cannot enumerate processes"
            }

            # Should handle gracefully (might skip process/terminal counts)
            { Show-SystemStats -NoModuleStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context 'Cache Functionality' {
        BeforeEach {
            # Clean cache before each test
            $cacheDir = Join-Path $HOME ".cache/oh-my-stats"
            if (Test-Path $cacheDir) {
                Remove-Item $cacheDir -Recurse -Force
            }
        }

        It 'Should create cache on first run' {
            Show-SystemStats -NoModuleStatus | Out-Null

            $cacheFile = Join-Path $HOME ".cache/oh-my-stats/system-info.json"
            Test-Path $cacheFile | Should -Be $true
        }

        It 'Should use cache on subsequent runs' {
            # First run creates cache
            Show-SystemStats -NoModuleStatus | Out-Null

            $cacheFile = Join-Path $HOME ".cache/oh-my-stats/system-info.json"
            $cacheTime1 = (Get-Item $cacheFile).LastWriteTime

            Start-Sleep -Milliseconds 100

            # Second run should use existing cache (not modify it)
            Show-SystemStats -NoModuleStatus | Out-Null
            $cacheTime2 = (Get-Item $cacheFile).LastWriteTime

            # Cache file should not be rewritten (times should match)
            $cacheTime2 | Should -Be $cacheTime1
        }

        It 'Should refresh cache when -RefreshCache is used' {
            # First run creates cache
            Show-SystemStats -NoModuleStatus | Out-Null

            $cacheFile = Join-Path $HOME ".cache/oh-my-stats/system-info.json"
            $cacheTime1 = (Get-Item $cacheFile).LastWriteTime

            Start-Sleep -Milliseconds 100

            # Force refresh
            Show-SystemStats -NoModuleStatus -RefreshCache | Out-Null
            $cacheTime2 = (Get-Item $cacheFile).LastWriteTime

            # Cache should be refreshed (new timestamp)
            $cacheTime2 | Should -BeGreaterThan $cacheTime1
        }

        It 'Should have valid cache JSON structure' {
            Show-SystemStats -NoModuleStatus | Out-Null

            $cacheFile = Join-Path $HOME ".cache/oh-my-stats/system-info.json"
            $cache = Get-Content $cacheFile | ConvertFrom-Json

            $cache.CPU | Should -Not -BeNullOrEmpty
            $cache.RAM | Should -Not -BeNullOrEmpty
            $cache.Disk | Should -Not -BeNullOrEmpty
            $cache.OS | Should -Not -BeNullOrEmpty
        }
    }
}
