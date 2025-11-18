BeforeAll {
    Set-Location -Path $PSScriptRoot
    $script:ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', 'Artifacts', "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

Describe 'Integration Tests' -Tag Integration {
    BeforeAll {
        $WarningPreference = 'SilentlyContinue'
        $ErrorActionPreference = 'SilentlyContinue'

        # Mock the tasksequence environment setup
        # Mock Write-LogEntry -MockWith { } -ModuleName $script:ModuleName
        Mock Confirm-TSEnvironmentSetup -MockWith { throw } -ModuleName $script:ModuleName
        Mock Set-TSVariable -MockWith { } -ModuleName $script:ModuleName

        $script:LogFilePath = Join-Path -Path 'TestDrive:\' -ChildPath 'DriverAutomationModule.log'
    }

    Context 'Find Phase Integration Tests' {
        BeforeAll {
            $script:actual = @{
                TargetOS     = 'Windows 11 x64'
                ServerFQDN   = 'escsccm.amaisd.org'
                Manufacturer = 'Dell'
            }
        }
        It 'should find a driver package for the local machine with CIM queries' {
            $params = @{
                TargetOS         = $actual.TargetOS
                ServerFQDN       = $actual.ServerFQDN
            }
            $result = Find-DriverPackage @params
            $result | Should -Not -BeNullOrEmpty
            $result.PackageID | Should -Be "AMA0009E"
            $result.Name | Should -Be "Drivers - Dell OptiPlex 7090 Tower - Windows 11 x64"
        }
    }

    Context 'Download Phase Integration Tests' {
        BeforeAll {
            $script:actual = @{
                TargetOS     = 'Windows 11 x64'
                ServerFQDN   = 'escsccm.amaisd.org'
                Manufacturer = 'Dell'
            }

            $script:tsVariableStore = @{}

            Mock Set-TSVariable -MockWith {
                param($Name, $Value)
                $script:tsVariableStore[$Name] = $Value
            } -ModuleName $script:ModuleName

            Mock Get-TSValue -MockWith {
                param($Name)
                if ($script:tsVariableStore.ContainsKey($Name)) {
                    return $script:tsVariableStore[$Name]
                }
                if ($Name -eq 'DriverPackagePath') {
                    return 'TestDrive:\DriverPackage'
                }
                return $null
            } -ModuleName $script:ModuleName

            Mock Invoke-OSDDownloadContent -MockWith { } -ModuleName $script:ModuleName
        }

        It 'should download driver package content after Find phase completes' {
            $script:tsVariableStore.Clear()

            $findParams = @{
                TargetOS   = $actual.TargetOS
                ServerFQDN = $actual.ServerFQDN
            }
            $findResult = Find-DriverPackage @findParams
            $findResult | Should -Not -BeNullOrEmpty

            $customLocation = Join-Path -Path 'TestDrive:\' -ChildPath 'DriverPackage'
            { Get-DriverPackageContent -CustomLocation $customLocation } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-OSDDownloadContent -ModuleName $script:ModuleName -Exactly -Times 1 -ParameterFilter {
                $PackageID -eq $findResult.PackageID -and
                $DestinationLocationType -eq 'Custom' -and
                $CustomLocationPath -eq $customLocation
            }
        }

        It 'should throw error when driver package query result is not found' {
            Mock Get-DriverPackageQueryResult -MockWith { return $null } -ModuleName $script:ModuleName

            $customLocation = Join-Path -Path 'TestDrive:\' -ChildPath 'DriverPackage'
            { Get-DriverPackageContent -CustomLocation $customLocation } | Should -Throw '*Driver package query result not found*'
        }
    }

    Context 'Install Phase Integration Tests' {
        BeforeAll {
            $script:testDriverPackagePath = Join-Path -Path 'TestDrive:\' -ChildPath 'DriverPackage'
            $script:testMountPath = Join-Path -Path 'TestDrive:\' -ChildPath 'Drivers'
            $script:testOSDisk = 'C:'

            Mock Mount-DriverPackageWim -MockWith { } -ModuleName $script:ModuleName
            Mock Invoke-DISM -MockWith { } -ModuleName $script:ModuleName
            Mock Dismount-DriverPackageWim -MockWith { } -ModuleName $script:ModuleName

            New-Item -Path $script:testDriverPackagePath -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $script:testDriverPackagePath -ChildPath 'DriverPackage.wim') -ItemType File -Force | Out-Null
        }

        It 'should install driver package with all required parameters' {
            $params = @{
                DriverPackagePath = $script:testDriverPackagePath
                OSDisk           = $script:testOSDisk
                MountPath        = $script:testMountPath
            }

            { Install-DriverPackage @params } | Should -Not -Throw

            Should -Invoke -CommandName Mount-DriverPackageWim -ModuleName $script:ModuleName -Exactly -Times 1 -ParameterFilter {
                $PackageDirectory -eq $script:testDriverPackagePath -and
                $MountPath -eq $script:testMountPath
            }

            Should -Invoke -CommandName Invoke-DISM -ModuleName $script:ModuleName -Exactly -Times 1 -ParameterFilter {
                $MountPath -eq $script:testMountPath -and
                $OSDisk -eq $script:testOSDisk
            }

            Should -Invoke -CommandName Dismount-DriverPackageWim -ModuleName $script:ModuleName -Exactly -Times 1 -ParameterFilter {
                $MountPath -eq $script:testMountPath
            }
        }

        It 'should throw error when driver package path does not exist' {
            Mock Mount-DriverPackageWim -MockWith { throw 'No driver package content found in the specified directory.' } -ModuleName $script:ModuleName

            $nonExistentPath = 'TestDrive:\NonExistent\DriverPackage'
            $params = @{
                DriverPackagePath = $nonExistentPath
                OSDisk           = $script:testOSDisk
                MountPath        = $script:testMountPath
            }

            { Install-DriverPackage @params } | Should -Throw '*No driver package content found*'
        }

        It 'should throw error when mount operation fails' {
            Mock Mount-DriverPackageWim -MockWith { throw 'Mount failed' } -ModuleName $script:ModuleName

            $params = @{
                DriverPackagePath = $script:testDriverPackagePath
                OSDisk           = $script:testOSDisk
                MountPath        = $script:testMountPath
            }

            { Install-DriverPackage @params } | Should -Throw '*Failed to install the driver package*'
        }

        It 'should throw error when DISM operation fails' {
            Mock Invoke-DISM -MockWith { throw 'DISM failed' } -ModuleName $script:ModuleName

            $params = @{
                DriverPackagePath = $script:testDriverPackagePath
                OSDisk           = $script:testOSDisk
                MountPath        = $script:testMountPath
            }

            { Install-DriverPackage @params } | Should -Throw '*Failed to install the driver package*'
        }
    }

    Context 'Full Workflow Integration Tests' {
        BeforeAll {
            $script:actual = @{
                TargetOS     = 'Windows 11 x64'
                ServerFQDN   = 'escsccm.amaisd.org'
                Manufacturer = 'Dell'
            }

            $script:tsVariableStore = @{}

            Mock Set-TSVariable -MockWith {
                param($Name, $Value)
                $script:tsVariableStore[$Name] = $Value
            } -ModuleName $script:ModuleName

            Mock Get-TSValue -MockWith {
                param($Name)
                if ($script:tsVariableStore.ContainsKey($Name)) {
                    return $script:tsVariableStore[$Name]
                }
                if ($Name -eq 'DriverPackagePath') {
                    return 'TestDrive:\DriverPackage'
                }
                if ($Name -eq 'DriverPackagePath01') {
                    return 'TestDrive:\DriverPackage'
                }
                if ($Name -eq 'OSDTargetSystemDrive') {
                    return 'C:'
                }
                if ($Name -eq '_SMSTSMDataPath') {
                    return 'TestDrive:\'
                }
                return $null
            } -ModuleName $script:ModuleName

            Mock Invoke-OSDDownloadContent -MockWith { } -ModuleName $script:ModuleName
            Mock Mount-DriverPackageWim -MockWith { } -ModuleName $script:ModuleName
            Mock Invoke-DISM -MockWith { } -ModuleName $script:ModuleName
            Mock Dismount-DriverPackageWim -MockWith { } -ModuleName $script:ModuleName

            $script:testDriverPackagePath = Join-Path -Path 'TestDrive:\' -ChildPath 'DriverPackage'
            $script:testMountPath = Join-Path -Path 'TestDrive:\' -ChildPath 'Drivers'
            New-Item -Path $script:testDriverPackagePath -ItemType Directory -Force | Out-Null
            New-Item -Path (Join-Path -Path $script:testDriverPackagePath -ChildPath 'DriverPackage.wim') -ItemType File -Force | Out-Null
        }

        It 'should execute Find, Download, and Install phases sequentially' {
            $script:tsVariableStore.Clear()

            $findParams = @{
                TargetOS   = $actual.TargetOS
                ServerFQDN = $actual.ServerFQDN
            }
            $findResult = Find-DriverPackage @findParams
            $findResult | Should -Not -BeNullOrEmpty
            $findResult.PackageID | Should -Be "AMA0009E"

            $customLocation = Join-Path -Path 'TestDrive:\' -ChildPath 'DriverPackage'
            { Get-DriverPackageContent -CustomLocation $customLocation } | Should -Not -Throw

            $installParams = @{
                DriverPackagePath = $script:testDriverPackagePath
                OSDisk           = 'C:'
                MountPath        = $script:testMountPath
            }
            { Install-DriverPackage @installParams } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-OSDDownloadContent -ModuleName $script:ModuleName -Exactly -Times 1
            Should -Invoke -CommandName Mount-DriverPackageWim -ModuleName $script:ModuleName -Exactly -Times 1
            Should -Invoke -CommandName Invoke-DISM -ModuleName $script:ModuleName -Exactly -Times 1
            Should -Invoke -CommandName Dismount-DriverPackageWim -ModuleName $script:ModuleName -Exactly -Times 1
        }
    }
}
