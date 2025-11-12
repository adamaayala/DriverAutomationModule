BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Set-LogFilePath -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
        }

        BeforeEach {
            $script:TaskSequenceEnvironment = $null
            Mock Write-Host { }
        }

        Context 'Success - Non-WinPE Environment' {
            It 'should return path using TEMP directory when X:\ does not exist' {
                $testLogFileName = 'test.log'
                $expectedPath = Join-Path -Path $env:TEMP -ChildPath $testLogFileName

                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'X:\' } { return $false }

                $result = Set-LogFilePath -LogFileName $testLogFileName

                $result | Should -Be $expectedPath
                Should -Invoke Confirm-TSEnvironmentSetup -Exactly -Times 1
                Should -Invoke Write-Host -Exactly -Times 1
            }
        }
        Context 'Success - WinPE without Task Sequence Environment' {
            BeforeEach {
                $script:TaskSequenceEnvironment = $null
                Mock Write-Host { }
                $script:taskSequenceLogDirectory = 'C:\SMSTSLog'
                Mock Test-Path { return $true }
            }
            It 'should handle gracefully when TS environment is unavailable but X:\ exists' {
                $testLogFileName = 'test.log'

                Mock Confirm-TSEnvironmentSetup { throw 'Unable to connect' }

                $result = Set-LogFilePath -LogFileName $testLogFileName

                Should -Invoke Write-Host -Exactly -Times 1 -ParameterFilter {
                    $Object -eq 'Unable to connect to the Task Sequence Environment.'
                }
                $result | Should -Be ("$script:taskSequenceLogDirectory\$testLogFileName")
            }
        }

        Context 'Error - Task Sequence Environment Setup Fails' {
            It 'should write error message and continue when Confirm-TSEnvironmentSetup throws' {
                $testLogFileName = 'test.log'
                $expectedPath = Join-Path -Path $env:TEMP -ChildPath $testLogFileName

                Mock Confirm-TSEnvironmentSetup { throw 'Connection failed' }
                Mock Test-Path -ParameterFilter { $Path -eq 'X:\' } { return $false }

                $result = Set-LogFilePath -LogFileName $testLogFileName

                Should -Invoke Write-Host -Exactly -Times 1 -ParameterFilter {
                    $Object -eq 'Unable to connect to the Task Sequence Environment.'
                }
                $result | Should -Be $expectedPath
            }
        }

        Context 'Success - Different Log File Names' {
            It 'should handle different log file names correctly' {
                $testLogFileName = 'DriverAutomationModule.log'
                $expectedPath = Join-Path -Path $env:TEMP -ChildPath $testLogFileName

                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'X:\' } { return $false }

                $result = Set-LogFilePath -LogFileName $testLogFileName

                $result | Should -Be $expectedPath
            }

            It 'should handle log file names with paths' {
                $testLogFileName = 'subfolder\mylog.log'
                $expectedPath = Join-Path -Path $env:TEMP -ChildPath $testLogFileName

                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'X:\' } { return $false }

                $result = Set-LogFilePath -LogFileName $testLogFileName

                $result | Should -Be $expectedPath
            }
        }
    }
}

