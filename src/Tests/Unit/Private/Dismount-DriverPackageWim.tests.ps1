BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Dismount-DriverPackageWim -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
        }

        Context 'Success' {
            It 'should dismount the WIM file successfully' {
                $testMountPath = 'C:\Temp\DriverPackageMount'
                Mock Dismount-WindowsImage { }

                Dismount-DriverPackageWim -MountPath $testMountPath

                Should -Invoke Dismount-WindowsImage -Exactly -Times 1 -ParameterFilter {
                    $Path -eq $testMountPath -and
                    $Discard -eq $true -and
                    $ErrorAction -eq 'Stop'
                }
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'Driver package content WIM file dismounted successfully.' -and
                    $Source -eq 'Dismount-DriverPackageWim'
                }
            }

            It 'should handle different mount paths' {
                $testMountPath = 'D:\Mount\TestPath'
                Mock Dismount-WindowsImage { }

                Dismount-DriverPackageWim -MountPath $testMountPath

                Should -Invoke Dismount-WindowsImage -Exactly -Times 1 -ParameterFilter {
                    $Path -eq $testMountPath
                }
            }
        }

        Context 'Error' {
            It 'should throw error and log when Dismount-WindowsImage fails' {
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'Dismount operation failed'
                Mock Dismount-WindowsImage {
                    throw $errorMessage
                }

                { Dismount-DriverPackageWim -MountPath $testMountPath } | Should -Throw

                Should -Invoke Dismount-WindowsImage -Exactly -Times 1 -ParameterFilter {
                    $Path -eq $testMountPath -and
                    $Discard -eq $true -and
                    $ErrorAction -eq 'Stop'
                }
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like 'Failed to dismount driver package content WIM file:*' -and
                    $Message -like "*$errorMessage*" -and
                    $Source -eq 'Dismount-DriverPackageWim' -and
                    $Severity -eq 3
                }
            }

            It 'should throw error with correct message format when dismount fails' {
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'Access denied'
                Mock Dismount-WindowsImage {
                    throw $errorMessage
                }

                { Dismount-DriverPackageWim -MountPath $testMountPath } | Should -Throw -ExpectedMessage 'Failed to dismount driver package content WIM file: *'
            }

            It 'should handle errors when mount path does not exist' {
                $testMountPath = 'C:\NonExistent\Path'
                $errorMessage = 'The system cannot find the path specified'
                Mock Dismount-WindowsImage {
                    throw $errorMessage
                }

                { Dismount-DriverPackageWim -MountPath $testMountPath } | Should -Throw

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like '*Failed to dismount driver package content WIM file:*' -and
                    $Severity -eq 3
                }
            }
        }
    }
}

