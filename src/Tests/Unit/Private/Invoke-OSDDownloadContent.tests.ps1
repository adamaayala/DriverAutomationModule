BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Invoke-OSDDownloadContent -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
            Mock Set-TSVariable { }
        }

        Context 'Success - NoPath Parameter Set - TSCache' {
            It 'should set task sequence variables and execute OSDDownloadContent for TSCache in full OS' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'TSCache'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process { }
                $expectedExecutablePath = Join-Path -Path $env:WINDIR -ChildPath "CCM\OSDDownloadContent.exe"

                Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName

                Should -Invoke Confirm-TSEnvironmentSetup -Exactly -Times 1
                Should -Invoke Set-TSVariable -Exactly -Times 8
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDownloadPackages' -and $Value -eq $testPackageID
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationLocationType' -and $Value -eq $testDestinationLocationType
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationVariable' -and $Value -eq $testDestinationVariableName
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationPath'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDownloadPackages'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationLocationType'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationVariable'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationPath'
                }
                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $FilePath -eq $expectedExecutablePath -and
                    $NoNewWindow -eq $true -and
                    $Wait -eq $true -and
                    $ErrorAction -eq 'Stop'
                }
                Should -Invoke Write-LogEntry -Exactly -Times 5
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Set TS variable OSDDownloadDownloadPackages to $testPackageID" -and
                    $Source -eq 'Invoke-OSDDownloadContent'
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Set TS variable OSDDownloadDestinationLocationType to $testDestinationLocationType" -and
                    $Source -eq 'Invoke-OSDDownloadContent'
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Set TS variable OSDDownloadDestinationVariable to $testDestinationVariableName" -and
                    $Source -eq 'Invoke-OSDDownloadContent'
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq 'Successfully executed OSDDownloadContent' -and
                    $Source -eq 'Invoke-OSDDownloadContent'
                }
            }

            It 'should clear task sequence variables in finally block for TSCache' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'TSCache'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process { }

                Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName

                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDownloadPackages'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationLocationType'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationVariable'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationPath'
                }
            }
        }

        Context 'Success - NoPath Parameter Set - CCMCache' {
            It 'should set task sequence variables and execute OSDDownloadContent for CCMCache in full OS' {
                $testPackageID = 'ABC12345'
                $testDestinationLocationType = 'CCMCache'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process { }
                $expectedExecutablePath = Join-Path -Path $env:WINDIR -ChildPath "CCM\OSDDownloadContent.exe"

                Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $FilePath -eq $expectedExecutablePath
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDownloadPackages' -and $Value -eq $testPackageID
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationLocationType' -and $Value -eq $testDestinationLocationType
                }
            }
        }

        Context 'Success - CustomPath Parameter Set' {
            It 'should set task sequence variables including CustomLocationPath and execute OSDDownloadContent' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'Custom'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                $testCustomLocationPath = 'C:\Temp'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process { }
                $expectedExecutablePath = Join-Path -Path $env:WINDIR -ChildPath "CCM\OSDDownloadContent.exe"

                Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName -CustomLocationPath $testCustomLocationPath

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $FilePath -eq $expectedExecutablePath
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationPath' -and $Value -eq $testCustomLocationPath
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Set TS variable OSDDownloadDestinationPath to $testCustomLocationPath" -and
                    $Source -eq 'Invoke-OSDDownloadContent'
                }
            }

            It 'should handle different custom paths correctly' {
                $testPackageID = 'XYZ98765'
                $testDestinationLocationType = 'Custom'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                $testCustomLocationPath = 'D:\Downloads\Drivers'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process { }

                Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName -CustomLocationPath $testCustomLocationPath

                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationPath' -and $Value -eq $testCustomLocationPath
                }
            }
        }

        Context 'Success - WinPE Environment' {
            It 'should use OSDDownloadContent.exe in WinPE environment' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'TSCache'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $true }
                Mock Start-Process { }

                Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $FilePath -eq 'OSDDownloadContent.exe'
                }
            }

            It 'should use OSDDownloadContent.exe in WinPE for Custom path' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'Custom'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                $testCustomLocationPath = 'C:\Temp'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $true }
                Mock Start-Process { }

                Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName -CustomLocationPath $testCustomLocationPath

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $FilePath -eq 'OSDDownloadContent.exe'
                }
            }
        }

        Context 'Error - Start-Process Failures' {
            It 'should throw error and log when Start-Process fails' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'TSCache'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                $errorMessage = 'OSDDownloadContent execution failed'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process {
                    throw $errorMessage
                }

                { Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName } | Should -Throw

                Should -Invoke Start-Process -Exactly -Times 1
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like 'Failed to execute OSDDownloadContent. Error: *' -and
                    $Message -like "*$errorMessage*" -and
                    $Source -eq 'Invoke-OSDDownloadContent' -and
                    $Severity -eq 3
                }
            }

            It 'should clear task sequence variables even when Start-Process fails' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'TSCache'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process {
                    throw 'Execution failed'
                }

                { Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName } | Should -Throw

                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDownloadPackages'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationLocationType'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationVariable'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationPath'
                }
            }

            It 'should throw error with correct message format when OSDDownloadContent fails' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'TSCache'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                $errorMessage = 'Access denied'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process {
                    throw $errorMessage
                }

                { Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName } | Should -Throw -ExpectedMessage 'Failed to execute OSDDownloadContent. Error: *'
            }

            It 'should handle errors when executable is not found' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'TSCache'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                $errorMessage = 'The system cannot find the file specified'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process {
                    throw $errorMessage
                }

                { Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName } | Should -Throw

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like '*Failed to execute OSDDownloadContent. Error:*' -and
                    $Message -like "*$errorMessage*" -and
                    $Severity -eq 3
                }
            }
        }

        Context 'Error - Confirm-TSEnvironmentSetup Failures' {
            It 'should throw error when Confirm-TSEnvironmentSetup fails' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'TSCache'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                $errorMessage = 'Unable to connect to Task Sequence Environment'
                Mock Confirm-TSEnvironmentSetup {
                    throw $errorMessage
                }

                { Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName } | Should -Throw

                Should -Invoke Confirm-TSEnvironmentSetup -Exactly -Times 1
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like '*Failed to execute OSDDownloadContent. Error:*' -and
                    $Message -like "*$errorMessage*" -and
                    $Severity -eq 3
                }
            }
        }

        Context 'Success - Parameter Validation' {
            It 'should handle different PackageID formats correctly' {
                $testPackageID = 'ABC12345'
                $testDestinationLocationType = 'TSCache'
                $testDestinationVariableName = 'OSDDownloadDestinationPath'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process { }

                Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName

                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDownloadPackages' -and $Value -eq $testPackageID
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Set TS variable OSDDownloadDownloadPackages to $testPackageID" -and
                    $Source -eq 'Invoke-OSDDownloadContent'
                }
            }

            It 'should handle different destination variable names correctly' {
                $testPackageID = 'PKG00001'
                $testDestinationLocationType = 'TSCache'
                $testDestinationVariableName = 'CustomDestinationPath'
                Mock Confirm-TSEnvironmentSetup { }
                Mock Test-Path -ParameterFilter { $Path -eq 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT' } { return $false }
                Mock Start-Process { }

                Invoke-OSDDownloadContent -PackageID $testPackageID -DestinationLocationType $testDestinationLocationType -DestinationVariableName $testDestinationVariableName

                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'OSDDownloadDestinationVariable' -and $Value -eq $testDestinationVariableName
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Set TS variable OSDDownloadDestinationVariable to $testDestinationVariableName" -and
                    $Source -eq 'Invoke-OSDDownloadContent'
                }
            }
        }
    }
}
