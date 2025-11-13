BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Mount-DriverPackageWim -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
        }

        Context 'Success - Basic Functionality' {
            It 'should mount driver package WIM file successfully' {
                $testPackageDirectory = 'C:\Temp\DriverPackage'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $testWimPath = 'C:\Temp\DriverPackage\DriverPackage.wim'
                $mockDriverPackage = [PSCustomObject]@{
                    FullName = $testWimPath
                }
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return $mockDriverPackage
                }
                Mock Test-Path -ParameterFilter { $Path -eq $testMountPath } { return $true }
                Mock Mount-WindowsImage { }

                Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath

                Should -Invoke Get-ChildItem -Exactly -Times 1 -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                }
                Should -Invoke Mount-WindowsImage -Exactly -Times 1 -ParameterFilter {
                    $ImagePath -eq $testWimPath -and
                    $Path -eq $testMountPath -and
                    $Index -eq 1 -and
                    $ErrorAction -eq 'Stop'
                }
                Should -Invoke Write-LogEntry -Exactly -Times 2
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Driver package content WIM file: $testWimPath" -and
                    $Source -eq 'Mount-DriverPackageWim' -and
                    $Severity -eq 0
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq 'Driver package content WIM file mounted successfully.' -and
                    $Source -eq 'Mount-DriverPackageWim'
                }
            }

            It 'should create mount path if it does not exist' {
                $testPackageDirectory = 'C:\Temp\DriverPackage'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $testWimPath = 'C:\Temp\DriverPackage\DriverPackage.wim'
                $mockDriverPackage = [PSCustomObject]@{
                    FullName = $testWimPath
                }
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return $mockDriverPackage
                }
                Mock Test-Path -ParameterFilter { $Path -eq $testMountPath } { return $false }
                Mock New-Item { }
                Mock Mount-WindowsImage { }

                Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath

                Should -Invoke Test-Path -Exactly -Times 1 -ParameterFilter {
                    $Path -eq $testMountPath
                }
                Should -Invoke New-Item -Exactly -Times 1 -ParameterFilter {
                    $Path -eq $testMountPath -and
                    $ItemType -eq 'Directory' -and
                    $Force -eq $true
                }
            }

            It 'should not create mount path if it already exists' {
                $testPackageDirectory = 'C:\Temp\DriverPackage'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $testWimPath = 'C:\Temp\DriverPackage\DriverPackage.wim'
                $mockDriverPackage = [PSCustomObject]@{
                    FullName = $testWimPath
                }
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return $mockDriverPackage
                }
                Mock Test-Path -ParameterFilter { $Path -eq $testMountPath } { return $true }
                Mock New-Item { }
                Mock Mount-WindowsImage { }

                Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath

                Should -Invoke New-Item -Exactly -Times 0
            }

            It 'should handle WIM file found in subdirectory' {
                $testPackageDirectory = 'C:\Temp\DriverPackage'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $testWimPath = 'C:\Temp\DriverPackage\SubFolder\DriverPackage.wim'
                $mockDriverPackage = [PSCustomObject]@{
                    FullName = $testWimPath
                }
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return $mockDriverPackage
                }
                Mock Test-Path -ParameterFilter { $Path -eq $testMountPath } { return $true }
                Mock Mount-WindowsImage { }

                Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath

                Should -Invoke Mount-WindowsImage -Exactly -Times 1 -ParameterFilter {
                    $ImagePath -eq $testWimPath -and
                    $Path -eq $testMountPath
                }
            }

            It 'should handle different package directories and mount paths' {
                $testPackageDirectory = 'D:\Downloads\Drivers\Dell'
                $testMountPath = 'D:\Mount\DellDrivers'
                $testWimPath = 'D:\Downloads\Drivers\Dell\DriverPackage.wim'
                $mockDriverPackage = [PSCustomObject]@{
                    FullName = $testWimPath
                }
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return $mockDriverPackage
                }
                Mock Test-Path -ParameterFilter { $Path -eq $testMountPath } { return $true }
                Mock Mount-WindowsImage { }

                Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath

                Should -Invoke Mount-WindowsImage -Exactly -Times 1 -ParameterFilter {
                    $ImagePath -eq $testWimPath -and
                    $Path -eq $testMountPath
                }
            }
        }

        Context 'Error - WIM File Not Found' {
            It 'should throw error when driver package WIM file is not found' {
                $testPackageDirectory = 'C:\Temp\DriverPackage'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return $null
                }

                { Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath } | Should -Throw -ExpectedMessage 'No driver package content found in the specified directory.'

                Should -Invoke Get-ChildItem -Exactly -Times 1 -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                }
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like 'Driver package content WIM file: *' -and
                    $Source -eq 'Mount-DriverPackageWim'
                }
            }

            It 'should throw error when Get-ChildItem returns empty array' {
                $testPackageDirectory = 'C:\Temp\DriverPackage'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return @()
                }

                { Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath } | Should -Throw -ExpectedMessage 'No driver package content found in the specified directory.'
            }
        }

        Context 'Error - Mount-WindowsImage Failures' {
            It 'should throw error and log when Mount-WindowsImage fails' {
                $testPackageDirectory = 'C:\Temp\DriverPackage'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $testWimPath = 'C:\Temp\DriverPackage\DriverPackage.wim'
                $errorMessage = 'The process cannot access the file because it is being used by another process.'
                $mockDriverPackage = [PSCustomObject]@{
                    FullName = $testWimPath
                }
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return $mockDriverPackage
                }
                Mock Test-Path -ParameterFilter { $Path -eq $testMountPath } { return $true }
                Mock Mount-WindowsImage {
                    throw $errorMessage
                }

                { Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath } | Should -Throw

                Should -Invoke Mount-WindowsImage -Exactly -Times 1 -ParameterFilter {
                    $ImagePath -eq $testWimPath -and
                    $Path -eq $testMountPath -and
                    $Index -eq 1
                }
            }

            It 'should throw error with correct message format when mount fails' {
                $testPackageDirectory = 'C:\Temp\DriverPackage'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $testWimPath = 'C:\Temp\DriverPackage\DriverPackage.wim'
                $errorMessage = 'Access denied'
                $mockDriverPackage = [PSCustomObject]@{
                    FullName = $testWimPath
                }
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return $mockDriverPackage
                }
                Mock Test-Path -ParameterFilter { $Path -eq $testMountPath } { return $true }
                Mock Mount-WindowsImage {
                    throw $errorMessage
                }

                { Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath } | Should -Throw -ExpectedMessage 'Failed to mount driver package content WIM file: *'
            }

            It 'should handle errors when WIM file is corrupted' {
                $testPackageDirectory = 'C:\Temp\DriverPackage'
                $testMountPath = 'C:\Temp\DriverPackageMount'
                $testWimPath = 'C:\Temp\DriverPackage\DriverPackage.wim'
                $errorMessage = 'The specified image file is invalid or corrupted.'
                $mockDriverPackage = [PSCustomObject]@{
                    FullName = $testWimPath
                }
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return $mockDriverPackage
                }
                Mock Test-Path -ParameterFilter { $Path -eq $testMountPath } { return $true }
                Mock Mount-WindowsImage {
                    throw $errorMessage
                }

                { Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath } | Should -Throw

                Should -Invoke Mount-WindowsImage -Exactly -Times 1
            }

            It 'should handle errors when mount path is invalid' {
                $testPackageDirectory = 'C:\Temp\DriverPackage'
                $testMountPath = 'Z:\Invalid\Mount\Path'
                $testWimPath = 'C:\Temp\DriverPackage\DriverPackage.wim'
                $errorMessage = 'The system cannot find the path specified.'
                $mockDriverPackage = [PSCustomObject]@{
                    FullName = $testWimPath
                }
                Mock Get-ChildItem -ParameterFilter {
                    $Path -eq $testPackageDirectory -and
                    $Filter -eq 'DriverPackage.wim' -and
                    $Recurse -eq $true
                } {
                    return $mockDriverPackage
                }
                Mock Test-Path -ParameterFilter { $Path -eq $testMountPath } { return $false }
                Mock New-Item {
                    throw $errorMessage
                }
                Mock Mount-WindowsImage { }

                { Mount-DriverPackageWim -PackageDirectory $testPackageDirectory -MountPath $testMountPath } | Should -Throw
            }
        }
    }
}

