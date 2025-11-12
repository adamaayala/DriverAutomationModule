BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Get-DriverPackageList -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
            $script:TestUri = 'https://cm01.contoso.com/AdminService/wmi/SMS_Package?$filter=startswith(Name,''Drivers%20-'')&$select=Name,PackageID'
        }

        Context 'Success - Default Credentials' {
            It 'should return driver packages when using default credentials' {
                $mockResponse = @{
                    value = @(
                        @{
                            Name      = 'Drivers - Dell OptiPlex 7090'
                            PackageID = 'ABC00001'
                        },
                        @{
                            Name      = 'Drivers - Dell OptiPlex 7090 - Windows 11'
                            PackageID = 'ABC00002'
                        }
                    )
                }

                Mock Invoke-RestMethod -ParameterFilter {
                    $Uri -eq $script:TestUri -and
                    $Method -eq 'Get' -and
                    $UseDefaultCredentials -eq $true
                } {
                    return $mockResponse
                }

                $result = Get-DriverPackageList -Uri $script:TestUri

                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -Be 2
                $result[0].Name | Should -Be 'Drivers - Dell OptiPlex 7090'
                $result[0].PackageID | Should -Be 'ABC00001'
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'Using default credentials for AdminService authentication.'
                }
                Should -Invoke Invoke-RestMethod -Exactly -Times 1
            }

            It 'should return single driver package when only one is found' {
                $mockResponse = @{
                    value = @(
                        @{
                            Name      = 'Drivers - Dell OptiPlex 7090'
                            PackageID = 'ABC00001'
                        }
                    )
                }

                Mock Invoke-RestMethod -ParameterFilter {
                    $Uri -eq $script:TestUri -and
                    $Method -eq 'Get' -and
                    $UseDefaultCredentials -eq $true
                } {
                    return $mockResponse
                }

                $result = Get-DriverPackageList -Uri $script:TestUri

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'Drivers - Dell OptiPlex 7090'
                $result.PackageID | Should -Be 'ABC00001'
            }
        }

        Context 'Success - Explicit Credentials' {
            It 'should return driver packages when using explicit credentials' {
                $mockResponse = @{
                    value = @(
                        @{
                            Name      = 'Drivers - Dell OptiPlex 7090'
                            PackageID = 'ABC00001'
                        }
                    )
                }

                $testUser = 'DOMAIN\ServiceAccount'
                $testPass = 'SecurePassword123'

                Mock Invoke-RestMethod -ParameterFilter {
                    $Uri -eq $script:TestUri -and
                    $Method -eq 'Get' -and
                    $Credential -ne $null
                } {
                    return $mockResponse
                }

                $result = Get-DriverPackageList -Uri $script:TestUri -AdminServiceUser $testUser -AdminServicePass $testPass

                $result | Should -Not -BeNullOrEmpty
                $result.Name | Should -Be 'Drivers - Dell OptiPlex 7090'
                $result.PackageID | Should -Be 'ABC00001'
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'Using provided credentials for AdminService authentication.'
                }
                Should -Invoke Invoke-RestMethod -Exactly -Times 1
            }

            It 'should use default credentials when only user is provided' {
                $mockResponse = @{
                    value = @(
                        @{
                            Name      = 'Drivers - Dell OptiPlex 7090'
                            PackageID = 'ABC00001'
                        }
                    )
                }

                Mock Invoke-RestMethod -ParameterFilter {
                    $UseDefaultCredentials -eq $true
                } {
                    return $mockResponse
                }

                $result = Get-DriverPackageList -Uri $script:TestUri -AdminServiceUser 'DOMAIN\ServiceAccount'

                $result | Should -Not -BeNullOrEmpty
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'Using default credentials for AdminService authentication.'
                }
            }

            It 'should use default credentials when only password is provided' {
                $mockResponse = @{
                    value = @(
                        @{
                            Name      = 'Drivers - Dell OptiPlex 7090'
                            PackageID = 'ABC00001'
                        }
                    )
                }

                Mock Invoke-RestMethod -ParameterFilter {
                    $UseDefaultCredentials -eq $true
                } {
                    return $mockResponse
                }

                $result = Get-DriverPackageList -Uri $script:TestUri -AdminServicePass 'SecurePassword123'

                $result | Should -Not -BeNullOrEmpty
                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'Using default credentials for AdminService authentication.'
                }
            }
        }

        Context 'Error - No Packages Found' {
            It 'should throw error when response value is null' {
                $mockResponse = @{
                    value = $null
                }

                Mock Invoke-RestMethod {
                    return $mockResponse
                }

                { Get-DriverPackageList -Uri $script:TestUri } | Should -Throw "No driver package(s) found on the AdminService endpoint."

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'No driver package(s) found on the AdminService endpoint.' -and
                    $Severity -eq 3
                }
            }

            It 'should throw error when response value is empty array' {
                $mockResponse = @{
                    value = @()
                }

                Mock Invoke-RestMethod {
                    return $mockResponse
                }

                { Get-DriverPackageList -Uri $script:TestUri } | Should -Throw "No driver package(s) found on the AdminService endpoint."

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -eq 'No driver package(s) found on the AdminService endpoint.' -and
                    $Severity -eq 3
                }
            }

            It 'should throw error when response value count is zero' {
                $mockResponse = @{
                    value = @()
                }

                Mock Invoke-RestMethod {
                    return $mockResponse
                }

                { Get-DriverPackageList -Uri $script:TestUri } | Should -Throw "No driver package(s) found on the AdminService endpoint."
            }
        }

        Context 'Error - Invoke-RestMethod Failures' {
            It 'should throw error and log when Invoke-RestMethod fails with network error' {
                $errorMessage = 'Unable to connect to the remote server'

                Mock Invoke-RestMethod {
                    throw $errorMessage
                }

                { Get-DriverPackageList -Uri $script:TestUri } | Should -Throw

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like '*Failed to retrieve driver package list:*' -and
                    $Message -like "*$errorMessage*"
                }
            }

            It 'should throw error and log when Invoke-RestMethod fails with authentication error' {
                $errorMessage = 'The remote server returned an error: (401) Unauthorized'

                Mock Invoke-RestMethod {
                    throw $errorMessage
                }

                { Get-DriverPackageList -Uri $script:TestUri } | Should -Throw

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like '*Failed to retrieve driver package list:*'
                }
            }

            It 'should throw error and log when Invoke-RestMethod fails with invalid URI' {
                $errorMessage = 'Invalid URI: The format of the URI could not be determined'

                Mock Invoke-RestMethod {
                    throw $errorMessage
                }

                { Get-DriverPackageList -Uri $script:TestUri } | Should -Throw

                Should -Invoke Write-LogEntry -Exactly -Times 1 -ParameterFilter {
                    $Message -like '*Failed to retrieve driver package list:*'
                }
            }
        }
    }
}

