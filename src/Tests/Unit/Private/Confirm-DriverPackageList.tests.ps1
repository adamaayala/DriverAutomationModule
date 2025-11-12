BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Confirm-DriverPackageList -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
        }

        Context 'Success - Single Package' {
            It 'should return the single package when only one is provided' {
                $singlePackage = @{
                    PackageID  = 'ABC00001'
                    Name       = 'Drivers - Dell OptiPlex 7090'
                    SourceDate = '2024-01-15T12:00:00Z'
                }

                $result = Confirm-DriverPackageList -DriverPackageList $singlePackage

                $result | Should -Not -BeNullOrEmpty
                $result.PackageID | Should -Be 'ABC00001'
                $result.Name | Should -Be 'Drivers - Dell OptiPlex 7090'
            }

            It 'should return the single package when array with one item is provided' {
                $singlePackage = @(
                    @{
                        PackageID  = 'ABC00001'
                        Name       = 'Drivers - Dell OptiPlex 7090'
                        SourceDate = '2024-01-15T12:00:00Z'
                    }
                )

                $result = Confirm-DriverPackageList -DriverPackageList $singlePackage

                $result | Should -Not -BeNullOrEmpty
                $result.PackageID | Should -Be 'ABC00001'
            }
        }

        Context 'Success - Multiple Packages' {
            It 'should return the package with the latest SourceDate when multiple packages are provided' {
                $multiplePackages = @(
                    @{
                        Description = "(Models included:0AC5;0AC6)"
                        Manufacturer = "Dell"
                        MIFName = "OptiPlex 3000"
                        MIFVersion = "Windows 11 x64"
                        Name = "Drivers - Dell OptiPlex 3000 - Windows 11 x64"
                        PackageID = "AMA00011"
                        SourceDate = "2025-02-06T21:58:44Z"
                        Version = "A10"
                    },
                    @{
                        Description = "(Models included:(Models included:07A3))"
                        Manufacturer = "Dell"
                        MIFName = ""
                        MIFVersion = ""
                        Name = "Drivers - Dell Optiplex 3050 - Windows 11 x64"
                        PackageID = "AMA00017"
                        SourceDate = "2025-04-04T18:38:29Z"
                        Version = "A00"
                    },
                    @{
                        Description = "(Models included:CTI_PC15-SM)"
                        Manufacturer = "ClearTouch"
                        MIFName = ""
                        MIFVersion = ""
                        Name = "Drivers - ClearTouch CTI_PC15-SM - Windows 11 x64"
                        PackageID = "AMA0003D"
                        SourceDate = "2025-07-14T16:16:44Z"
                        Version = "A00"
                    },
                    @{
                        Description = "(Models included:0B34;0B49)"
                        Manufacturer = "Dell"
                        MIFName = "XPS 13 9315 2-in-1"
                        MIFVersion = "Windows 11 x64"
                        Name = "Drivers - Dell XPS 13 9315 2-in-1 - Windows 11 x64"
                        PackageID = "AMA00051"
                        SourceDate = "2025-07-18T17:58:08Z"
                        Version = "A09"
                    }
                )

                $result = Confirm-DriverPackageList -DriverPackageList $multiplePackages

                $result | Should -Not -BeNullOrEmpty
                $result.PackageID | Should -Be 'AMA00051'
                $result.Name | Should -Be "Drivers - Dell XPS 13 9315 2-in-1 - Windows 11 x64"
                $result.SourceDate | Should -Be "2025-07-18T17:58:08Z"
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq "Multiple driver packages found. Selecting the latest package."
                }
            }

            It 'should return the latest package when packages have same date but different times' {
                $multiplePackages = @(
                    @{
                        Description = "(Models included:MT63A-SHA;CTI_PC65-ST)"
                        Manufacturer = "ClearTouch"
                        MIFName = ""
                        MIFVersion = ""
                        Name = "Drivers - ClearTouch CTI_PC65-ST - Windows 11 x64"
                        PackageID = "AMA0003F"
                        SourceDate = "2025-07-15T16:15:00Z"
                        Version = "A00"
                    },
                    @{
                        Description = "(Models included:CTI_PCOPS-PC25-SM)"
                        Manufacturer = "ClearTouch"
                        MIFName = ""
                        MIFVersion = ""
                        Name = "Drivers - ClearTouch CTI_PCOPS-PC25-SM - Windows 11 x64"
                        PackageID = "AMA00041"
                        SourceDate = "2025-07-14T16:15:11Z"
                        Version = "A00"
                    },
                    @{
                        Description = "(Models included:CTI_PC15-SM)"
                        Manufacturer = "ClearTouch"
                        MIFName = ""
                        MIFVersion = ""
                        Name = "Drivers - ClearTouch CTI_PC15-SM - Windows 11 x64"
                        PackageID = "AMA0003D"
                        SourceDate = "2025-07-26T16:16:44Z"
                        Version = "A00"
                    }
                )

                $result = Confirm-DriverPackageList -DriverPackageList $multiplePackages

                $result.PackageID | Should -Be 'AMA0003D'
                $result.SourceDate | Should -Be "2025-07-26T16:16:44Z"
            }

            It 'should handle packages in any order and still select the latest' {
                $multiplePackages = @(
                    @{
                        Description = "(Models included:0AC5;0AC6)"
                        Manufacturer = "Dell"
                        MIFName = "OptiPlex 3000"
                        MIFVersion = "Windows 11 x64"
                        Name = "Drivers - Dell OptiPlex 3000 - Windows 11 x64"
                        PackageID = "AMA00011"
                        SourceDate = "2025-02-06T21:58:44Z"
                        Version = "A10"
                    },
                    @{
                        Description = "(Models included:0B19)"
                        Manufacturer = "Dell"
                        MIFName = "XPS 15 9520"
                        MIFVersion = "Windows 11 x64"
                        Name = "Drivers - Dell XPS 15 9520 - Windows 11 x64"
                        PackageID = "AMA00053"
                        SourceDate = "2025-07-18T17:58:08Z"
                        Version = "A11"
                    },
                    @{
                        Description = "(Models included:(Models included:07A3))"
                        Manufacturer = "Dell"
                        MIFName = ""
                        MIFVersion = ""
                        Name = "Drivers - Dell Optiplex 3050 - Windows 11 x64"
                        PackageID = "AMA00017"
                        SourceDate = "2025-04-04T18:38:29Z"
                        Version = "A00"
                    }
                )

                $result = Confirm-DriverPackageList -DriverPackageList $multiplePackages

                $result.PackageID | Should -Be 'AMA00053'
                $result.SourceDate | Should -Be "2025-07-18T17:58:08Z"
            }
        }

        Context 'Success - Pipeline Input' {
            It 'should accept pipeline input and return the correct package' {
                $singlePackage = @{
                    PackageID  = 'ABC00001'
                    Name       = 'Drivers - Dell OptiPlex 7090'
                    SourceDate = '2024-01-15T12:00:00Z'
                }

                $result = $singlePackage | Confirm-DriverPackageList

                $result | Should -Not -BeNullOrEmpty
                $result.PackageID | Should -Be 'ABC00001'
            }

            It 'should accept pipeline input with multiple packages and select the latest' {
                $multiplePackages = @(
                    @{
                        Description = "(Models included:0AC5;0AC6)"
                        Manufacturer = "Dell"
                        MIFName = "OptiPlex 3000"
                        MIFVersion = "Windows 11 x64"
                        Name = "Drivers - Dell OptiPlex 3000 - Windows 11 x64"
                        PackageID = "AMA00011"
                        SourceDate = "2025-02-06T21:58:44Z"
                        Version = "A10"
                    },
                    @{
                        Description = "(Models included:0B34;0B49)"
                        Manufacturer = "Dell"
                        MIFName = "XPS 13 9315 2-in-1"
                        MIFVersion = "Windows 11 x64"
                        Name = "Drivers - Dell XPS 13 9315 2-in-1 - Windows 11 x64"
                        PackageID = "AMA00051"
                        SourceDate = "2025-07-18T17:58:08Z"
                        Version = "A09"
                    }
                )

                $result = Confirm-DriverPackageList -DriverPackageList $multiplePackages

                $result.PackageID | Should -Be 'AMA00051'
            }
        }

        Context 'Error - No Packages' {
            It 'should return nothing and log error when empty array is provided' {
                $emptyArray = @()

                $result = Confirm-DriverPackageList -DriverPackageList $emptyArray

                $result | Should -BeNullOrEmpty
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq "No driver packages found." -and
                    $Severity -eq 3
                }
            }

        }

        Context 'Logging Verification' {
            BeforeEach {
                Mock Write-LogEntry { }
            }

            It 'should log package count and confirmation for single package' {
                $singlePackage = @{
                    PackageID  = 'ABC00001'
                    Name       = 'Drivers - Test'
                    SourceDate = '2024-01-15T12:00:00Z'
                }

                Confirm-DriverPackageList -DriverPackageList $singlePackage | Out-Null

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Driver package count: 1"
                }
            }

            It 'should log package count, multiple packages message, and confirmation for multiple packages' {
                $multiplePackages = @(
                    @{
                        Description = "(Models included:0AC5;0AC6)"
                        Manufacturer = "Dell"
                        MIFName = "OptiPlex 3000"
                        MIFVersion = "Windows 11 x64"
                        Name = "Drivers - Dell OptiPlex 3000 - Windows 11 x64"
                        PackageID = "AMA00011"
                        SourceDate = "2025-02-06T21:58:44Z"
                        Version = "A10"
                    },
                    @{
                        Description = "(Models included:0B34;0B49)"
                        Manufacturer = "Dell"
                        MIFName = "XPS 13 9315 2-in-1"
                        MIFVersion = "Windows 11 x64"
                        Name = "Drivers - Dell XPS 13 9315 2-in-1 - Windows 11 x64"
                        PackageID = "AMA00051"
                        SourceDate = "2025-07-18T17:58:08Z"
                        Version = "A09"
                    }
                )

                Confirm-DriverPackageList -DriverPackageList $multiplePackages | Out-Null

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Driver package count: 2"
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Multiple driver packages found. Selecting the latest package."
                }
            }

            It 'should log package count and error for empty array' {
                $emptyArray = @()

                $null = Confirm-DriverPackageList -DriverPackageList $emptyArray

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq "Driver package count: 0"
                }
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq "No driver packages found." -and
                    $Severity -eq 3
                }
            }
        }
    }
}

