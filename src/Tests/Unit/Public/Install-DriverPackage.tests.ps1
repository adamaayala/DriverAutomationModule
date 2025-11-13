BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Install-DriverPackage -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
        }

        Context 'Success - Basic Functionality' {
            It 'should install driver package successfully' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM { }
                Mock Dismount-DriverPackageWim { }

                Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath

                Should -Invoke Mount-DriverPackageWim -Exactly -Times 1 -ParameterFilter {
                    $PackageDirectory -eq $testDriverPackagePath -and
                    $MountPath -eq $testMountPath
                }
                Should -Invoke Invoke-DISM -Exactly -Times 1 -ParameterFilter {
                    $MountPath -eq $testMountPath -and
                    $OSDisk -eq $testOSDisk
                }
                Should -Invoke Dismount-DriverPackageWim -Exactly -Times 1 -ParameterFilter {
                    $MountPath -eq $testMountPath
                }
            }

            It 'should call functions in correct order' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $script:callOrder = @()

                Mock Mount-DriverPackageWim {
                    $script:callOrder += 'Mount'
                }
                Mock Invoke-DISM {
                    $script:callOrder += 'DISM'
                }
                Mock Dismount-DriverPackageWim {
                    $script:callOrder += 'Dismount'
                }

                Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath

                $script:callOrder[0] | Should -Be 'Mount'
                $script:callOrder[1] | Should -Be 'DISM'
                $script:callOrder[2] | Should -Be 'Dismount'
            }

            It 'should handle different driver package paths' {
                $testDriverPackagePath = 'D:\Downloads\Drivers\Dell'
                $testOSDisk = 'C:'
                $testMountPath = 'D:\Mount\DellDrivers'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM { }
                Mock Dismount-DriverPackageWim { }

                Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath

                Should -Invoke Mount-DriverPackageWim -Exactly -Times 1 -ParameterFilter {
                    $PackageDirectory -eq $testDriverPackagePath
                }
            }

            It 'should handle different OS disks' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'D:'
                $testMountPath = 'C:\Temp\DriverPackageMount'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM { }
                Mock Dismount-DriverPackageWim { }

                Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath

                Should -Invoke Invoke-DISM -Exactly -Times 1 -ParameterFilter {
                    $OSDisk -eq $testOSDisk
                }
            }

            It 'should handle different mount paths' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'E:\CustomMount\Drivers'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM { }
                Mock Dismount-DriverPackageWim { }

                Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath

                Should -Invoke Mount-DriverPackageWim -Exactly -Times 1 -ParameterFilter {
                    $MountPath -eq $testMountPath
                }
                Should -Invoke Invoke-DISM -Exactly -Times 1 -ParameterFilter {
                    $MountPath -eq $testMountPath
                }
                Should -Invoke Dismount-DriverPackageWim -Exactly -Times 1 -ParameterFilter {
                    $MountPath -eq $testMountPath
                }
            }
        }

        Context 'Error - Mount-DriverPackageWim Failures' {
            It 'should throw error when Mount-DriverPackageWim fails' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'No driver package content found in the specified directory.'

                Mock Mount-DriverPackageWim {
                    throw $errorMessage
                }
                Mock Invoke-DISM { }
                Mock Dismount-DriverPackageWim { }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw -ExpectedMessage "Failed to install the driver package: $errorMessage"

                Should -Invoke Mount-DriverPackageWim -Exactly -Times 1
                Should -Invoke Invoke-DISM -Exactly -Times 0
                Should -Invoke Dismount-DriverPackageWim -Exactly -Times 0
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like 'Failed to install the driver package:*' -and
                    $Source -eq 'Install-DriverPackage' -and
                    $Severity -eq 3
                }
            }

            It 'should throw error with correct message format when mount fails' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'Failed to mount driver package content WIM file: Access denied'

                Mock Mount-DriverPackageWim {
                    throw $errorMessage
                }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw -ExpectedMessage "Failed to install the driver package: $errorMessage"
            }

            It 'should handle errors when WIM file is corrupted' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'The specified image file is invalid or corrupted.'

                Mock Mount-DriverPackageWim {
                    throw $errorMessage
                }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw

                Should -Invoke Mount-DriverPackageWim -Exactly -Times 1
            }
        }

        Context 'Error - Invoke-DISM Failures' {
            It 'should throw error when Invoke-DISM fails' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'DISM operation failed: Exit code 1'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM {
                    throw $errorMessage
                }
                Mock Dismount-DriverPackageWim { }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw -ExpectedMessage "Failed to install the driver package: $errorMessage"

                Should -Invoke Mount-DriverPackageWim -Exactly -Times 1
                Should -Invoke Invoke-DISM -Exactly -Times 1
                Should -Invoke Dismount-DriverPackageWim -Exactly -Times 0
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like 'Failed to install the driver package:*' -and
                    $Source -eq 'Install-DriverPackage' -and
                    $Severity -eq 3
                }
            }

            It 'should throw error with correct message format when DISM fails' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'Unable to apply drivers: Invalid driver path'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM {
                    throw $errorMessage
                }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw -ExpectedMessage "Failed to install the driver package: $errorMessage"
            }

            It 'should handle errors when OS disk is invalid' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'Z:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'The system cannot find the drive specified.'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM {
                    throw $errorMessage
                }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw

                Should -Invoke Invoke-DISM -Exactly -Times 1 -ParameterFilter {
                    $OSDisk -eq $testOSDisk
                }
            }
        }

        Context 'Error - Dismount-DriverPackageWim Failures' {
            It 'should throw error when Dismount-DriverPackageWim fails' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'Failed to dismount WIM file: The process cannot access the file because it is being used by another process.'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM { }
                Mock Dismount-DriverPackageWim {
                    throw $errorMessage
                }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw -ExpectedMessage "Failed to install the driver package: $errorMessage"

                Should -Invoke Mount-DriverPackageWim -Exactly -Times 1
                Should -Invoke Invoke-DISM -Exactly -Times 1
                Should -Invoke Dismount-DriverPackageWim -Exactly -Times 1
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like 'Failed to install the driver package:*' -and
                    $Source -eq 'Install-DriverPackage' -and
                    $Severity -eq 3
                }
            }

            It 'should throw error with correct message format when dismount fails' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'Access denied to dismount path'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM { }
                Mock Dismount-DriverPackageWim {
                    throw $errorMessage
                }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw -ExpectedMessage "Failed to install the driver package: $errorMessage"
            }

            It 'should handle errors when mount path is invalid for dismount' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'Z:\Invalid\Mount\Path'
                $errorMessage = 'The system cannot find the path specified.'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM { }
                Mock Dismount-DriverPackageWim {
                    throw $errorMessage
                }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw

                Should -Invoke Dismount-DriverPackageWim -Exactly -Times 1 -ParameterFilter {
                    $MountPath -eq $testMountPath
                }
            }
        }

        Context 'Logging Verification' {
            It 'should log error with correct source when installation fails' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'Test error message'

                Mock Mount-DriverPackageWim {
                    throw $errorMessage
                }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Failed to install the driver package: $errorMessage" -and
                    $Source -eq 'Install-DriverPackage' -and
                    $Severity -eq 3
                }
            }

            It 'should log error when DISM operation fails' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'DISM operation failed'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM {
                    throw $errorMessage
                }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Failed to install the driver package: $errorMessage" -and
                    $Source -eq 'Install-DriverPackage' -and
                    $Severity -eq 3
                }
            }

            It 'should log error when dismount operation fails' {
                $testDriverPackagePath = 'C:\Temp\DriverPackage'
                $testOSDisk = 'C:'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $errorMessage = 'Dismount operation failed'

                Mock Mount-DriverPackageWim { }
                Mock Invoke-DISM { }
                Mock Dismount-DriverPackageWim {
                    throw $errorMessage
                }

                { Install-DriverPackage -DriverPackagePath $testDriverPackagePath -OSDisk $testOSDisk -MountPath $testMountPath } | Should -Throw

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Failed to install the driver package: $errorMessage" -and
                    $Source -eq 'Install-DriverPackage' -and
                    $Severity -eq 3
                }
            }
        }
    }
}

