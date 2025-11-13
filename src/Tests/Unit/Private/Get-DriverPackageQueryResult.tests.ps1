BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Get-DriverPackageQueryResult -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
            $script:test = @{
                Description  = 'Network Driver Package'
                Manufacturer = 'Intel'
                Name         = 'Intel Network Adapter Driver'
                PackageID    = 'PACK001234'
                Version      = '1.0.0'
            }
        }

        Context 'Success - Default Prefix' {
            It 'should return hashtable with all expected keys and values' {
                Mock Get-TSValue -ParameterFilter { $Name -eq 'XDriverDescription' } {
                    return $script:test.Description
                }
                Mock Get-TSValue -ParameterFilter { $Name -eq 'XDriverManufacturer' } {
                    return $script:test.Manufacturer
                }
                Mock Get-TSValue -ParameterFilter { $Name -eq 'XDriverName' } {
                    return $script:test.Name
                }
                Mock Get-TSValue -ParameterFilter { $Name -eq 'XDriverPackageID' } {
                    return $script:test.PackageID
                }
                Mock Get-TSValue -ParameterFilter { $Name -eq 'XDriverVersion' } {
                    return $script:test.Version
                }

                $result = Get-DriverPackageQueryResult

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 5
                $result.Description | Should -Be $script:test.Description
                $result.Manufacturer | Should -Be $script:test.Manufacturer
                $result.Name | Should -Be $script:test.Name
                $result.PackageID | Should -Be $script:test.PackageID
                $result.Version | Should -Be $script:test.Version
            }

            It 'should call Get-TSValue for each variable name with default prefix' {
                Mock Get-TSValue { return 'TestValue' }

                Get-DriverPackageQueryResult

                Should -Invoke Get-TSValue -Exactly -Times 5
                Should -Invoke Get-TSValue -ParameterFilter { $Name -eq 'XDriverDescription' }
                Should -Invoke Get-TSValue -ParameterFilter { $Name -eq 'XDriverManufacturer' }
                Should -Invoke Get-TSValue -ParameterFilter { $Name -eq 'XDriverName' }
                Should -Invoke Get-TSValue -ParameterFilter { $Name -eq 'XDriverPackageID' }
                Should -Invoke Get-TSValue -ParameterFilter { $Name -eq 'XDriverVersion' }
            }

            It 'should log each variable name and value' {
                Mock Get-TSValue { return 'TestValue' }

                Get-DriverPackageQueryResult

                Should -Invoke Write-LogEntry -Exactly -Times 5 -ParameterFilter {
                    $Message -like 'Description : *' -or
                    $Message -like 'Manufacturer : *' -or
                    $Message -like 'Name : *' -or
                    $Message -like 'PackageID : *' -or
                    $Message -like 'Version : *'
                }
            }
        }

        Context 'Success - Custom Prefix' {
            It 'should use custom prefix when specified' {
                $customPrefix = 'CustomDriver'
                Mock Get-TSValue { return 'TestValue' }

                Get-DriverPackageQueryResult -VariablePrefix $customPrefix

                Should -Invoke Get-TSValue -ParameterFilter { $Name -eq 'CustomDriverDescription' }
                Should -Invoke Get-TSValue -ParameterFilter { $Name -eq 'CustomDriverManufacturer' }
                Should -Invoke Get-TSValue -ParameterFilter { $Name -eq 'CustomDriverName' }
                Should -Invoke Get-TSValue -ParameterFilter { $Name -eq 'CustomDriverPackageID' }
                Should -Invoke Get-TSValue -ParameterFilter { $Name -eq 'CustomDriverVersion' }
            }

            It 'should return hashtable with correct values using custom prefix' {
                $customPrefix = 'MyDriver'
                $customTest = @{
                    Description  = 'Custom Description'
                    Manufacturer = 'Custom Manufacturer'
                    Name         = 'Custom Name'
                    PackageID    = 'CUSTOM001'
                    Version      = '2.0.0'
                }

                Mock Get-TSValue -ParameterFilter { $Name -eq 'MyDriverDescription' } {
                    return $customTest.Description
                }
                Mock Get-TSValue -ParameterFilter { $Name -eq 'MyDriverManufacturer' } {
                    return $customTest.Manufacturer
                }
                Mock Get-TSValue -ParameterFilter { $Name -eq 'MyDriverName' } {
                    return $customTest.Name
                }
                Mock Get-TSValue -ParameterFilter { $Name -eq 'MyDriverPackageID' } {
                    return $customTest.PackageID
                }
                Mock Get-TSValue -ParameterFilter { $Name -eq 'MyDriverVersion' } {
                    return $customTest.Version
                }

                $result = Get-DriverPackageQueryResult -VariablePrefix $customPrefix

                $result.Description | Should -Be $customTest.Description
                $result.Manufacturer | Should -Be $customTest.Manufacturer
                $result.Name | Should -Be $customTest.Name
                $result.PackageID | Should -Be $customTest.PackageID
                $result.Version | Should -Be $customTest.Version
            }
        }

        Context 'Success - Empty Values' {
            It 'should handle empty string values' {
                Mock Get-TSValue { return '' }

                $result = Get-DriverPackageQueryResult

                $result.Description | Should -Be ''
                $result.Manufacturer | Should -Be ''
                $result.Name | Should -Be ''
                $result.PackageID | Should -Be ''
                $result.Version | Should -Be ''
            }

            It 'should handle null values' {
                Mock Get-TSValue { return $null }

                $result = Get-DriverPackageQueryResult

                $result.Description | Should -BeNullOrEmpty
                $result.Manufacturer | Should -BeNullOrEmpty
                $result.Name | Should -BeNullOrEmpty
                $result.PackageID | Should -BeNullOrEmpty
                $result.Version | Should -BeNullOrEmpty
            }
        }

        Context 'Error - Get-TSValue Failures' {
            It 'should throw error and log when Get-TSValue fails' {
                $errorMessage = 'Failed to get Task Sequence variable'
                Mock Get-TSValue {
                    throw $errorMessage
                }

                { Get-DriverPackageQueryResult } | Should -Throw

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like '*Failed to get the Driver Package search results from the Task Sequence variables:*' -and
                    $Message -like "*$errorMessage*" -and
                    $Severity -eq 3
                }
            }

            It 'should throw error when Get-TSValue fails on first variable' {
                $script:callCount = 0
                Mock Get-TSValue {
                    $script:callCount++
                    if ($script:callCount -eq 1) {
                        throw 'First variable failed'
                    }
                    return 'TestValue'
                }

                { Get-DriverPackageQueryResult } | Should -Throw

                Should -Invoke Get-TSValue -Exactly -Times 1
            }

            It 'should throw error when Get-TSValue fails on last variable' {
                $script:callCount = 0
                Mock Get-TSValue {
                    $script:callCount++
                    if ($script:callCount -eq 5) {
                        throw 'Last variable failed'
                    }
                    return 'TestValue'
                }

                { Get-DriverPackageQueryResult } | Should -Throw

                Should -Invoke Get-TSValue -Exactly -Times 5
            }
        }
    }
}

