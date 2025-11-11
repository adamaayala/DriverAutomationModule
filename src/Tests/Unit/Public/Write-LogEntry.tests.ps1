BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Write-LogEntry -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
        }

        BeforeEach {
            Mock Set-LogFilePath { "TestDrive:\DriverAutomationModule.log" }
            Mock Write-Host { }
        }

        Context 'Success - Basic Functionality' {
            It 'should write a message with default parameters' {
                Write-LogEntry -Message 'Test message' -Source 'Pester'
                Should -Invoke Write-Host -Times 1
            }

            It 'should initialize log file path when not set' {
                $script:LogFilePath = $null
                Write-LogEntry -Message 'Test message'

                Should -Invoke Set-LogFilePath -Exactly -Times 1 -ParameterFilter {
                    $LogFileName -eq 'DriverAutomationModule.log'
                }
                Test-Path -Path "TestDrive:\DriverAutomationModule.log" | Should -BeTrue
            }

            It 'should not initialize log file path when already set' {
                Write-LogEntry -Message 'Test message'

                Should -Invoke Set-LogFilePath -Exactly -Times 0
            }

            It 'should write to the correct log file path' {
                Write-LogEntry -Message 'Test message'

                Test-Path -Path "TestDrive:\DriverAutomationModule.log" | Should -BeTrue
                "TestDrive:\DriverAutomationModule.log" | Should -FileContentMatch 'Test message'
            }
        }
        Context 'Error' {
            It 'should write an error message to the console' {
                Mock Out-File { throw 'Error writing to log file' }

                Write-LogEntry -Message 'Test message' -Severity 3 -Source 'Pester'
                Should -Invoke Write-Host -Times 1
            }
        }
    }
}

