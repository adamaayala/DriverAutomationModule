BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Set-DriverPackageQueryResult -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
            Mock Set-TSVariable { }
            $script:test = @{
                Description  = 'Network Driver Package'
                Manufacturer = 'Intel'
                Name         = 'Intel Network Adapter Driver'
                PackageID    = 'PACK001234'
                Version      = '1.0.0'
            }
        }

        Context 'Success - Direct Parameters' {
            It 'should set all Task Sequence variables with correct prefix and values' {
                Set-DriverPackageQueryResult @script:test

                Should -Invoke Set-TSVariable -Exactly -Times 5
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'XDriverDescription' -and $Value -eq $test.Description
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'XDriverManufacturer' -and $Value -eq $test.Manufacturer
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'XDriverName' -and $Value -eq $test.Name
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'XDriverPackageID' -and $Value -eq $test.PackageID
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'XDriverVersion' -and $Value -eq $test.Version
                }
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'Successfully set the Driver Package search results to Task Sequence variables.' -and
                    $Severity -eq 0
                }
            }
        }

        Context 'Success - Pipeline Input' {
            It 'should accept pipeline input by property name' {
                $testObject = [PSCustomObject]@{
                    Description  = 'Graphics Driver'
                    Manufacturer = 'NVIDIA'
                    Name         = 'NVIDIA Graphics Driver'
                    PackageID    = 'PACK005678'
                    Version      = '2.1.0'
                }

                Mock Set-TSVariable { }

                $testObject | Set-DriverPackageQueryResult

                Should -Invoke Set-TSVariable -Exactly -Times 5
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'XDriverDescription' -and $Value -eq 'Graphics Driver'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'XDriverManufacturer' -and $Value -eq 'NVIDIA'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'XDriverName' -and $Value -eq 'NVIDIA Graphics Driver'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'XDriverPackageID' -and $Value -eq 'PACK005678'
                }
                Should -Invoke Set-TSVariable -ParameterFilter {
                    $Name -eq 'XDriverVersion' -and $Value -eq '2.1.0'
                }
            }

            It 'should handle multiple objects from pipeline' {
                $testObjects = @(
                    [PSCustomObject]@{
                        Description  = 'Driver 1'
                        Manufacturer = 'Manufacturer 1'
                        Name         = 'Name 1'
                        PackageID    = 'PACK001'
                        Version      = '1.0'
                    },
                    [PSCustomObject]@{
                        Description  = 'Driver 2'
                        Manufacturer = 'Manufacturer 2'
                        Name         = 'Name 2'
                        PackageID    = 'PACK002'
                        Version      = '2.0'
                    }
                )

                Mock Set-TSVariable { }

                $testObjects | Set-DriverPackageQueryResult

                Should -Invoke Set-TSVariable -Exactly -Times 10
            }
        }

        Context 'Error - Set-TSVariable Failures' {
            It 'should throw error and log when Set-TSVariable fails' {
                $errorMessage = 'Failed to set Task Sequence variable'
                Mock Set-TSVariable {
                    throw $errorMessage
                }

                { Set-DriverPackageQueryResult -Description 'Test' -Manufacturer 'Test' -Name 'Test' -PackageID 'Test' -Version 'Test' } | Should -Throw

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like '*Failed to set the Driver Package search results to Task Sequence variables:*' -and
                    $Message -like "*$errorMessage*" -and
                    $Severity -eq 3
                }
            }

            It 'should throw error when Set-TSVariable fails on first parameter' {
                $script:callCount = 0
                Mock Set-TSVariable {
                    $script:callCount++
                    if ($script:callCount -eq 1) {
                        throw 'First parameter failed'
                    }
                }

                { Set-DriverPackageQueryResult -Description 'Test' -Manufacturer 'Test' -Name 'Test' -PackageID 'Test' -Version 'Test' } | Should -Throw

                Should -Invoke Set-TSVariable -Exactly -Times 1
            }

            It 'should throw error when Set-TSVariable fails on last parameter' {
                $script:callCount = 0
                Mock Set-TSVariable {
                    $script:callCount++
                    if ($script:callCount -eq 5) {
                        throw 'Last parameter failed'
                    }
                }

                { Set-DriverPackageQueryResult -Description 'Test' -Manufacturer 'Test' -Name 'Test' -PackageID 'Test' -Version 'Test' } | Should -Throw

                Should -Invoke Set-TSVariable -Exactly -Times 5
            }
        }
    }
}

