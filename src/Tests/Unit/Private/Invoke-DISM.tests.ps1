BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Invoke-DISM -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
        }

        Context 'Success - Basic Functionality' {
            It 'should invoke DISM with default OSDisk when only MountPath is provided' {
                $testMountPath = 'C:\Drivers'
                $testOSDisk = 'C:'
                Mock Start-Process { }

                Invoke-DISM -MountPath $testMountPath

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $FilePath -eq 'dism.exe' -and
                    $ArgumentList -contains "/Image:$testOSDisk\" -and
                    $ArgumentList -contains '/Add-Driver' -and
                    $ArgumentList -contains "/Driver:$testMountPath" -and
                    $ArgumentList -contains '/Recurse' -and
                    $Wait -eq $true -and
                    $NoNewWindow -eq $true -and
                    $ErrorAction -eq 'Stop'
                }
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'Applied drivers to the target system disk successfully.' -and
                    $Source -eq 'Invoke-DISM'
                }
            }

            It 'should invoke DISM with specified OSDisk' {
                $testMountPath = 'C:\Drivers'
                $testOSDisk = 'D:'
                Mock Start-Process { }

                Invoke-DISM -MountPath $testMountPath -OSDisk $testOSDisk

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $FilePath -eq 'dism.exe' -and
                    $ArgumentList -contains "/Image:$testOSDisk\" -and
                    $ArgumentList -contains '/Add-Driver' -and
                    $ArgumentList -contains "/Driver:$testMountPath" -and
                    $ArgumentList -contains '/Recurse'
                }
            }

            It 'should include LogPath in arguments when LogPath is provided' {
                $testMountPath = 'C:\Drivers'
                $testOSDisk = 'C:'
                $testLogPath = 'C:\Logs\DISM.log'
                Mock Start-Process { }

                Invoke-DISM -MountPath $testMountPath -OSDisk $testOSDisk -LogPath $testLogPath

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $FilePath -eq 'dism.exe' -and
                    $ArgumentList -contains "/Image:$testOSDisk\" -and
                    $ArgumentList -contains '/Add-Driver' -and
                    $ArgumentList -contains "/Driver:$testMountPath" -and
                    $ArgumentList -contains '/Recurse' -and
                    $ArgumentList -contains "/LogPath:$testLogPath"
                }
            }

            It 'should not include LogPath in arguments when LogPath is not provided' {
                $testMountPath = 'C:\Drivers'
                $testOSDisk = 'C:'
                Mock Start-Process { }

                Invoke-DISM -MountPath $testMountPath -OSDisk $testOSDisk

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $FilePath -eq 'dism.exe' -and
                    $ArgumentList -notcontains '/LogPath:'
                }
            }

            It 'should handle different mount paths correctly' {
                $testMountPath = 'D:\DriverPackages\Dell'
                $testOSDisk = 'D:'
                Mock Start-Process { }

                Invoke-DISM -MountPath $testMountPath -OSDisk $testOSDisk

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $ArgumentList -contains "/Driver:$testMountPath" -and
                    $ArgumentList -contains "/Image:$testOSDisk\"
                }
            }
        }

        Context 'Error - Start-Process Failures' {
            It 'should throw error and log when Start-Process fails' {
                $testMountPath = 'C:\Drivers'
                $testOSDisk = 'C:'
                $errorMessage = 'DISM execution failed'
                Mock Start-Process {
                    throw $errorMessage
                }

                { Invoke-DISM -MountPath $testMountPath -OSDisk $testOSDisk } | Should -Throw

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $FilePath -eq 'dism.exe'
                }
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like 'Failed to apply drivers to the target system disk. Error: *' -and
                    $Message -like "*$errorMessage*" -and
                    $Source -eq 'Invoke-DISM' -and
                    $Severity -eq 3
                }
            }

            It 'should throw error with correct message format when DISM fails' {
                $testMountPath = 'C:\Drivers'
                $testOSDisk = 'C:'
                $errorMessage = 'Access denied'
                Mock Start-Process {
                    throw $errorMessage
                }

                { Invoke-DISM -MountPath $testMountPath -OSDisk $testOSDisk } | Should -Throw -ExpectedMessage 'Failed to apply drivers to the target system disk. Error: *'
            }

            It 'should handle errors when mount path does not exist' {
                $testMountPath = 'C:\NonExistent\Path'
                $testOSDisk = 'C:'
                $errorMessage = 'The system cannot find the path specified'
                Mock Start-Process {
                    throw $errorMessage
                }

                { Invoke-DISM -MountPath $testMountPath -OSDisk $testOSDisk } | Should -Throw

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like '*Failed to apply drivers to the target system disk. Error:*' -and
                    $Severity -eq 3
                }
            }

            It 'should handle errors when DISM executable is not found' {
                $testMountPath = 'C:\Drivers'
                $testOSDisk = 'C:'
                $errorMessage = 'The system cannot find the file specified'
                Mock Start-Process {
                    throw $errorMessage
                }

                { Invoke-DISM -MountPath $testMountPath -OSDisk $testOSDisk } | Should -Throw

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like '*Failed to apply drivers to the target system disk. Error:*' -and
                    $Message -like "*$errorMessage*" -and
                    $Severity -eq 3
                }
            }
        }

        Context 'Success - Parameter Validation' {
            It 'should use default OSDisk value when not specified' {
                $testMountPath = 'C:\Drivers'
                Mock Start-Process { }

                Invoke-DISM -MountPath $testMountPath

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $ArgumentList -contains '/Image:C:\'
                }
            }

            It 'should handle LogPath with different paths' {
                $testMountPath = 'C:\Drivers'
                $testOSDisk = 'C:'
                $testLogPath = 'D:\Logs\DISM\driver.log'
                Mock Start-Process { }

                Invoke-DISM -MountPath $testMountPath -OSDisk $testOSDisk -LogPath $testLogPath

                Should -Invoke Start-Process -Exactly -Times 1 -ParameterFilter {
                    $ArgumentList -contains "/LogPath:$testLogPath"
                }
            }
        }
    }
}

