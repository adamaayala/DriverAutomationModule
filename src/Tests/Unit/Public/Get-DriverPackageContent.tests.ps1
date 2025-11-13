BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Get-DriverPackageContent -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
        }

        Context 'Success - Basic Functionality' {
            It 'should download driver package content successfully' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'
                $testPackageID = 'ABC00001'
                $mockDriverPackageQueryResult = @{
                    PackageID    = $testPackageID
                    Name         = 'Drivers - Dell OptiPlex 7090 - Windows 11 x64'
                    Manufacturer = 'Dell'
                    Version      = 'A10'
                    Description  = '(Models included:0A52)'
                }

                Mock Get-DriverPackageQueryResult {
                    return $mockDriverPackageQueryResult
                }
                Mock Invoke-OSDDownloadContent { }

                Get-DriverPackageContent -CustomLocation $testCustomLocation

                Should -Invoke Get-DriverPackageQueryResult -Exactly -Times 1
                Should -Invoke Invoke-OSDDownloadContent -Exactly -Times 1 -ParameterFilter {
                    $PackageID -eq $testPackageID -and
                    $DestinationLocationType -eq 'Custom' -and
                    $DestinationVariableName -eq 'DriverPackagePath' -and
                    $CustomLocationPath -eq $testCustomLocation
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq 'Driver package query result retrieved successfully.' -and
                    $Source -eq 'Get-DriverPackageContent' -and
                    $Severity -eq 0
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq 'Driver package content downloaded successfully.' -and
                    $Source -eq 'Get-DriverPackageContent' -and
                    $Severity -eq 0
                }
            }

            It 'should handle different custom locations' {
                $testCustomLocation = 'D:\Downloads\Drivers\Dell'
                $testPackageID = 'XYZ12345'
                $mockDriverPackageQueryResult = @{
                    PackageID    = $testPackageID
                    Name         = 'Drivers - HP EliteBook - Windows 10 x64'
                    Manufacturer = 'HP'
                    Version      = 'B20'
                    Description  = '(Models included:1234)'
                }

                Mock Get-DriverPackageQueryResult {
                    return $mockDriverPackageQueryResult
                }
                Mock Invoke-OSDDownloadContent { }

                Get-DriverPackageContent -CustomLocation $testCustomLocation

                Should -Invoke Invoke-OSDDownloadContent -Exactly -Times 1 -ParameterFilter {
                    $CustomLocationPath -eq $testCustomLocation
                }
            }

            It 'should handle different package IDs' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'
                $testPackageID = 'PKG99999'
                $mockDriverPackageQueryResult = @{
                    PackageID    = $testPackageID
                    Name         = 'Drivers - Lenovo ThinkPad - Windows 11 x64'
                    Manufacturer = 'Lenovo'
                    Version      = 'C30'
                    Description  = '(Models included:5678)'
                }

                Mock Get-DriverPackageQueryResult {
                    return $mockDriverPackageQueryResult
                }
                Mock Invoke-OSDDownloadContent { }

                Get-DriverPackageContent -CustomLocation $testCustomLocation

                Should -Invoke Invoke-OSDDownloadContent -Exactly -Times 1 -ParameterFilter {
                    $PackageID -eq $testPackageID
                }
            }
        }

        Context 'Error - Driver Package Query Result Not Found' {
            It 'should throw error when Get-DriverPackageQueryResult returns null' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'

                Mock Get-DriverPackageQueryResult {
                    return $null
                }

                { Get-DriverPackageContent -CustomLocation $testCustomLocation } | Should -Throw -ExpectedMessage 'Failed to download the driver package content: Driver package query result not found'

                Should -Invoke Get-DriverPackageQueryResult -Exactly -Times 1
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq 'Driver package query result retrieved successfully.' -and
                    $Severity -eq 0
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like 'Failed to download the driver package content:*' -and
                    $Source -eq 'Get-DriverPackageContent' -and
                    $Severity -eq 3
                }
            }

            It 'should throw error when Get-DriverPackageQueryResult returns empty hashtable' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'

                Mock Get-DriverPackageQueryResult {
                    return @{}
                }

                { Get-DriverPackageContent -CustomLocation $testCustomLocation } | Should -Throw

                Should -Invoke Get-DriverPackageQueryResult -Exactly -Times 1
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq 'Driver package query result retrieved successfully.' -and
                    $Severity -eq 0
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like 'Failed to download the driver package content:*' -and
                    $Source -eq 'Get-DriverPackageContent' -and
                    $Severity -eq 3
                }
            }

            It 'should throw error when Get-DriverPackageQueryResult returns hashtable without PackageID' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'
                $mockDriverPackageQueryResult = @{
                    Name         = 'Drivers - Test'
                    Manufacturer = 'Test'
                }

                Mock Get-DriverPackageQueryResult {
                    return $mockDriverPackageQueryResult
                }

                { Get-DriverPackageContent -CustomLocation $testCustomLocation } | Should -Throw

                Should -Invoke Get-DriverPackageQueryResult -Exactly -Times 1
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq 'Driver package query result retrieved successfully.' -and
                    $Severity -eq 0
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like 'Failed to download the driver package content:*' -and
                    $Source -eq 'Get-DriverPackageContent' -and
                    $Severity -eq 3
                }
            }
        }

        Context 'Error - Get-DriverPackageQueryResult Failures' {
            It 'should throw error when Get-DriverPackageQueryResult throws exception' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'
                $errorMessage = 'Failed to retrieve driver package query result from registry'

                Mock Get-DriverPackageQueryResult {
                    throw $errorMessage
                }

                { Get-DriverPackageContent -CustomLocation $testCustomLocation } | Should -Throw

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like 'Failed to download the driver package content:*' -and
                    $Source -eq 'Get-DriverPackageContent' -and
                    $Severity -eq 3
                }
            }
        }

        Context 'Error - Invoke-OSDDownloadContent Failures' {
            It 'should throw error when Invoke-OSDDownloadContent throws exception' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'
                $testPackageID = 'ABC00001'
                $errorMessage = 'Failed to execute OSDDownloadContent. Error: Access denied'
                $mockDriverPackageQueryResult = @{
                    PackageID    = $testPackageID
                    Name         = 'Drivers - Dell OptiPlex 7090 - Windows 11 x64'
                    Manufacturer = 'Dell'
                    Version      = 'A10'
                    Description  = '(Models included:0A52)'
                }

                Mock Get-DriverPackageQueryResult {
                    return $mockDriverPackageQueryResult
                }
                Mock Invoke-OSDDownloadContent {
                    throw $errorMessage
                }

                { Get-DriverPackageContent -CustomLocation $testCustomLocation } | Should -Throw

                Should -Invoke Get-DriverPackageQueryResult -Exactly -Times 1
                Should -Invoke Invoke-OSDDownloadContent -Exactly -Times 1
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq 'Driver package query result retrieved successfully.' -and
                    $Severity -eq 0
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like 'Failed to download the driver package content:*' -and
                    $Source -eq 'Get-DriverPackageContent' -and
                    $Severity -eq 3
                }
            }

            It 'should throw error with correct message format when download fails' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'
                $testPackageID = 'XYZ12345'
                $errorMessage = 'Network connection failed'
                $mockDriverPackageQueryResult = @{
                    PackageID    = $testPackageID
                    Name         = 'Drivers - HP EliteBook - Windows 10 x64'
                    Manufacturer = 'HP'
                    Version      = 'B20'
                    Description  = '(Models included:1234)'
                }

                Mock Get-DriverPackageQueryResult {
                    return $mockDriverPackageQueryResult
                }
                Mock Invoke-OSDDownloadContent {
                    throw $errorMessage
                }

                { Get-DriverPackageContent -CustomLocation $testCustomLocation } | Should -Throw -ExpectedMessage 'Failed to download the driver package content: *'
            }

            It 'should handle errors when package download times out' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'
                $testPackageID = 'PKG99999'
                $errorMessage = 'The operation timed out'
                $mockDriverPackageQueryResult = @{
                    PackageID    = $testPackageID
                    Name         = 'Drivers - Lenovo ThinkPad - Windows 11 x64'
                    Manufacturer = 'Lenovo'
                    Version      = 'C30'
                    Description  = '(Models included:5678)'
                }

                Mock Get-DriverPackageQueryResult {
                    return $mockDriverPackageQueryResult
                }
                Mock Invoke-OSDDownloadContent {
                    throw $errorMessage
                }

                { Get-DriverPackageContent -CustomLocation $testCustomLocation } | Should -Throw

                Should -Invoke Invoke-OSDDownloadContent -Exactly -Times 1
            }
        }

        Context 'Logging Verification' {
            It 'should log driver package query result retrieval success' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'
                $testPackageID = 'ABC00001'
                $mockDriverPackageQueryResult = @{
                    PackageID    = $testPackageID
                    Name         = 'Drivers - Dell OptiPlex 7090 - Windows 11 x64'
                    Manufacturer = 'Dell'
                    Version      = 'A10'
                    Description  = '(Models included:0A52)'
                }

                Mock Get-DriverPackageQueryResult {
                    return $mockDriverPackageQueryResult
                }
                Mock Invoke-OSDDownloadContent { }

                Get-DriverPackageContent -CustomLocation $testCustomLocation | Out-Null

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq 'Driver package query result retrieved successfully.' -and
                    $Source -eq 'Get-DriverPackageContent' -and
                    $Severity -eq 0
                }
            }

            It 'should log driver package content download success' {
                $testCustomLocation = 'C:\Temp\DriverPackageContent'
                $testPackageID = 'XYZ12345'
                $mockDriverPackageQueryResult = @{
                    PackageID    = $testPackageID
                    Name         = 'Drivers - HP EliteBook - Windows 10 x64'
                    Manufacturer = 'HP'
                    Version      = 'B20'
                    Description  = '(Models included:1234)'
                }

                Mock Get-DriverPackageQueryResult {
                    return $mockDriverPackageQueryResult
                }
                Mock Invoke-OSDDownloadContent { }

                Get-DriverPackageContent -CustomLocation $testCustomLocation | Out-Null

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq 'Driver package content downloaded successfully.' -and
                    $Source -eq 'Get-DriverPackageContent' -and
                    $Severity -eq 0
                }
            }
        }
    }
}

