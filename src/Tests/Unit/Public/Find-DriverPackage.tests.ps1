BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Find-DriverPackage -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            Mock Write-LogEntry { }
            $script:TestServerFQDN = 'cm01.contoso.com'
            $script:TestManufacturer = 'Dell'
            $script:TestModel = 'OptiPlex 7090'
            $script:TestSystemSKU = '0A52'
            $script:TestSerialNumber = 'SN123456789'
            $script:TestTargetOS = 'Windows 11 x64'
            $script:TestUri = "https://$($script:TestServerFQDN)/AdminService/wmi/SMS_Package?`$filter=startswith(Name,'Drivers%20-')&`$select=Name,Description,Manufacturer,Version,SourceDate,PackageID,MIFName,MIFVersion"
        }

        Context 'Success - All Parameters with Default Credentials' {
            It 'should successfully find driver package with all parameters using default credentials' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    Model        = $script:TestModel
                    SystemSKU    = $script:TestSystemSKU
                    SerialNumber = $script:TestSerialNumber
                }
                $mockDriverPackage = @{
                    Description  = "(Models included:$($script:TestSystemSKU))"
                    Manufacturer = $script:TestManufacturer
                    Name         = "Drivers - $($script:TestManufacturer) $($script:TestModel) - $($script:TestTargetOS)"
                    PackageID    = 'ABC00001'
                    Version      = 'A10'
                    SourceDate   = '2025-01-15T12:00:00Z'
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    return $script:TestUri
                }
                Mock Get-DriverPackageList {
                    return @($mockDriverPackage)
                }
                Mock Confirm-DriverPackageList {
                    return $mockDriverPackage
                }
                Mock Set-DriverPackageQueryResult { }

                $result = Find-DriverPackage -Manufacturer $script:TestManufacturer -Model $script:TestModel -TargetOS $script:TestTargetOS -ServerFQDN $script:TestServerFQDN

                $result | Should -Not -BeNullOrEmpty
                $result.PackageID | Should -Be 'ABC00001'
                $result.Manufacturer | Should -Be $script:TestManufacturer
                Should -Invoke Get-HardwareData -Exactly -Times 1 -ParameterFilter {
                    $Manufacturer -eq $script:TestManufacturer -and
                    $Model -eq $script:TestModel
                }
                Should -Invoke Set-DriverPackageQuery -Exactly -Times 1 -ParameterFilter {
                    $ServerFQDN -eq $script:TestServerFQDN -and
                    $Manufacturer -eq $script:TestManufacturer -and
                    $SystemSKU -eq $script:TestSystemSKU -and
                    $TargetOS -eq $script:TestTargetOS
                }
                Should -Invoke Get-DriverPackageList -Exactly -Times 1 -ParameterFilter {
                    $Uri -eq $script:TestUri -and
                    -not $PSBoundParameters.ContainsKey('AdminServiceUser') -and
                    -not $PSBoundParameters.ContainsKey('AdminServicePass')
                }
                Should -Invoke Confirm-DriverPackageList -Exactly -Times 1
                Should -Invoke Set-DriverPackageQueryResult -Exactly -Times 1
            }
        }

        Context 'Success - All Parameters with Explicit Credentials' {
            It 'should successfully find driver package with all parameters using explicit credentials' {
                $testUser = 'DOMAIN\ServiceAccount'
                $testPass = 'SecurePassword123'
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    Model        = $script:TestModel
                    SystemSKU    = $script:TestSystemSKU
                    SerialNumber = $script:TestSerialNumber
                }
                $mockDriverPackage = @{
                    Description  = "(Models included:$($script:TestSystemSKU))"
                    Manufacturer = $script:TestManufacturer
                    Name         = "Drivers - $($script:TestManufacturer) $($script:TestModel) - $($script:TestTargetOS)"
                    PackageID    = 'ABC00002'
                    Version      = 'A11'
                    SourceDate   = '2025-02-15T12:00:00Z'
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    return $script:TestUri
                }
                Mock Get-DriverPackageList {
                    return @($mockDriverPackage)
                }
                Mock Confirm-DriverPackageList {
                    return $mockDriverPackage
                }
                Mock Set-DriverPackageQueryResult { }

                $result = Find-DriverPackage -Manufacturer $script:TestManufacturer -Model $script:TestModel -TargetOS $script:TestTargetOS -ServerFQDN $script:TestServerFQDN -AdminServiceUser $testUser -AdminServicePass $testPass

                $result | Should -Not -BeNullOrEmpty
                $result.PackageID | Should -Be 'ABC00002'
                Should -Invoke Get-DriverPackageList -Exactly -Times 1 -ParameterFilter {
                    $Uri -eq $script:TestUri -and
                    $AdminServiceUser -eq $testUser -and
                    $AdminServicePass -eq $testPass
                }
            }
        }

        Context 'Success - Minimal Parameters' {
            It 'should successfully find driver package with only required ServerFQDN parameter' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    SystemSKU    = $script:TestSystemSKU
                }
                $mockDriverPackage = @{
                    Description  = "(Models included:$($script:TestSystemSKU))"
                    Manufacturer = $script:TestManufacturer
                    Name         = "Drivers - $($script:TestManufacturer)"
                    PackageID    = 'ABC00003'
                    Version      = 'A12'
                    SourceDate   = '2025-03-15T12:00:00Z'
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    return $script:TestUri
                }
                Mock Get-DriverPackageList {
                    return @($mockDriverPackage)
                }
                Mock Confirm-DriverPackageList {
                    return $mockDriverPackage
                }
                Mock Set-DriverPackageQueryResult { }

                $result = Find-DriverPackage -ServerFQDN $script:TestServerFQDN

                $result | Should -Not -BeNullOrEmpty
                $result.PackageID | Should -Be 'ABC00003'
                Should -Invoke Get-HardwareData -Exactly -Times 1 -ParameterFilter {
                    -not $PSBoundParameters.ContainsKey('Manufacturer') -and
                    -not $PSBoundParameters.ContainsKey('Model')
                }
                Should -Invoke Set-DriverPackageQuery -Exactly -Times 1 -ParameterFilter {
                    $ServerFQDN -eq $script:TestServerFQDN -and
                    -not $PSBoundParameters.ContainsKey('TargetOS')
                }
            }
        }

        Context 'Success - Hardware Data Without Optional Properties' {
            It 'should successfully find driver package when hardware data does not include Model or SerialNumber' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    SystemSKU    = $script:TestSystemSKU
                }
                $mockDriverPackage = @{
                    Description  = "(Models included:$($script:TestSystemSKU))"
                    Manufacturer = $script:TestManufacturer
                    Name         = "Drivers - $($script:TestManufacturer)"
                    PackageID    = 'ABC00004'
                    Version      = 'A13'
                    SourceDate   = '2025-04-15T12:00:00Z'
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    return $script:TestUri
                }
                Mock Get-DriverPackageList {
                    return @($mockDriverPackage)
                }
                Mock Confirm-DriverPackageList {
                    return $mockDriverPackage
                }
                Mock Set-DriverPackageQueryResult { }

                $result = Find-DriverPackage -ServerFQDN $script:TestServerFQDN

                $result | Should -Not -BeNullOrEmpty
                $result.PackageID | Should -Be 'ABC00004'
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like "Manufacturer: $($script:TestManufacturer), SystemSKU: $($script:TestSystemSKU)" -and
                    $Message -notlike "*Model:*" -and
                    $Message -notlike "*SerialNumber:*"
                }
            }
        }

        Context 'Error - Credential Validation' {
            It 'should throw error when only AdminServiceUser is provided' {
                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN -AdminServiceUser 'DOMAIN\User' } | Should -Throw "AdminServiceUser and AdminServicePass must be provided together, or both omitted to use default credentials."
            }

            It 'should throw error when only AdminServicePass is provided' {
                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN -AdminServicePass 'Password123' } | Should -Throw "AdminServiceUser and AdminServicePass must be provided together, or both omitted to use default credentials."
            }

            It 'should throw error when AdminServiceUser is empty string' {
                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN -AdminServiceUser '' -AdminServicePass 'Password123' } | Should -Throw "AdminServiceUser and AdminServicePass must be provided together, or both omitted to use default credentials."
            }

            It 'should throw error when AdminServicePass is whitespace' {
                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN -AdminServiceUser 'DOMAIN\User' -AdminServicePass '   ' } | Should -Throw "AdminServiceUser and AdminServicePass must be provided together, or both omitted to use default credentials."
            }
        }

        Context 'Error - Hardware Data Validation' {
            It 'should throw error when Get-HardwareData returns empty hashtable' {
                Mock Get-HardwareData {
                    return @{}
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw "Hardware data could not be retrieved. The manufacturer may not be supported."
            }

            It 'should throw error when Get-HardwareData returns null' {
                Mock Get-HardwareData {
                    return $null
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw "Hardware data could not be retrieved. The manufacturer may not be supported."
            }

            It 'should throw error when Manufacturer is missing from hardware data' {
                $mockHardwareData = @{
                    SystemSKU = $script:TestSystemSKU
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw "Manufacturer information is missing from hardware data."
            }

            It 'should throw error when Manufacturer is empty string in hardware data' {
                $mockHardwareData = @{
                    Manufacturer = ''
                    SystemSKU    = $script:TestSystemSKU
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw "Manufacturer information is missing from hardware data."
            }

            It 'should throw error when SystemSKU is missing from hardware data' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw "SystemSKU information is missing from hardware data."
            }

            It 'should throw error when SystemSKU is whitespace in hardware data' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    SystemSKU    = '   '
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw "SystemSKU information is missing from hardware data."
            }
        }

        Context 'Error - No Driver Package Found' {
            It 'should throw error when Confirm-DriverPackageList returns null' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    SystemSKU    = $script:TestSystemSKU
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    return $script:TestUri
                }
                Mock Get-DriverPackageList {
                    return @()
                }
                Mock Confirm-DriverPackageList {
                    return $null
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw "No driver package was found or confirmed."
            }
        }

        Context 'Error - Dependent Function Failures' {
            It 'should throw error when Get-HardwareData throws exception' {
                $errorMessage = 'Failed to retrieve hardware data: WMI query failed'
                Mock Get-HardwareData {
                    throw $errorMessage
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like "*An error occurred while finding the driver package:*" -and
                    $Severity -eq 3
                }
            }

            It 'should throw error when Set-DriverPackageQuery throws exception' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    SystemSKU    = $script:TestSystemSKU
                }
                $errorMessage = 'Invalid ServerFQDN format'

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    throw $errorMessage
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like "*An error occurred while finding the driver package:*" -and
                    $Severity -eq 3
                }
            }

            It 'should throw error when Get-DriverPackageList throws exception' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    SystemSKU    = $script:TestSystemSKU
                }
                $errorMessage = 'Unable to connect to AdminService'

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    return $script:TestUri
                }
                Mock Get-DriverPackageList {
                    throw $errorMessage
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like "*An error occurred while finding the driver package:*" -and
                    $Severity -eq 3
                }
            }

            It 'should throw error when Set-DriverPackageQueryResult throws exception' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    SystemSKU    = $script:TestSystemSKU
                }
                $mockDriverPackage = @{
                    Description  = "(Models included:$($script:TestSystemSKU))"
                    Manufacturer = $script:TestManufacturer
                    Name         = "Drivers - $($script:TestManufacturer)"
                    PackageID    = 'ABC00005'
                    Version      = 'A14'
                    SourceDate   = '2025-05-15T12:00:00Z'
                }
                $errorMessage = 'Failed to set Task Sequence variables'

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    return $script:TestUri
                }
                Mock Get-DriverPackageList {
                    return @($mockDriverPackage)
                }
                Mock Confirm-DriverPackageList {
                    return $mockDriverPackage
                }
                Mock Set-DriverPackageQueryResult {
                    throw $errorMessage
                }

                { Find-DriverPackage -ServerFQDN $script:TestServerFQDN } | Should -Throw
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like "*An error occurred while finding the driver package:*" -and
                    $Severity -eq 3
                }
            }
        }

        Context 'Logging Verification' {
            It 'should log hardware data retrieval success' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    SystemSKU    = $script:TestSystemSKU
                    Model        = $script:TestModel
                    SerialNumber = $script:TestSerialNumber
                }
                $mockDriverPackage = @{
                    Description  = "(Models included:$($script:TestSystemSKU))"
                    Manufacturer = $script:TestManufacturer
                    Name         = "Drivers - $($script:TestManufacturer)"
                    PackageID    = 'ABC00006'
                    Version      = 'A15'
                    SourceDate   = '2025-06-15T12:00:00Z'
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    return $script:TestUri
                }
                Mock Get-DriverPackageList {
                    return @($mockDriverPackage)
                }
                Mock Confirm-DriverPackageList {
                    return $mockDriverPackage
                }
                Mock Set-DriverPackageQueryResult { }

                Find-DriverPackage -ServerFQDN $script:TestServerFQDN | Out-Null

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Hardware data retrieved successfully." -and
                    $Severity -eq 0
                }
                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -like "Manufacturer: $($script:TestManufacturer), SystemSKU: $($script:TestSystemSKU)*" -and
                    $Message -like "*Model: $($script:TestModel)*" -and
                    $Message -like "*SerialNumber: $($script:TestSerialNumber)*" -and
                    $Severity -eq 0
                }
            }

            It 'should log driver package query success' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    SystemSKU    = $script:TestSystemSKU
                }
                $mockDriverPackage = @{
                    Description  = "(Models included:$($script:TestSystemSKU))"
                    Manufacturer = $script:TestManufacturer
                    Name         = "Drivers - $($script:TestManufacturer)"
                    PackageID    = 'ABC00007'
                    Version      = 'A16'
                    SourceDate   = '2025-07-15T12:00:00Z'
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    return $script:TestUri
                }
                Mock Get-DriverPackageList {
                    return @($mockDriverPackage)
                }
                Mock Confirm-DriverPackageList {
                    return $mockDriverPackage
                }
                Mock Set-DriverPackageQueryResult { }

                Find-DriverPackage -ServerFQDN $script:TestServerFQDN | Out-Null

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Driver package query set successfully." -and
                    $Severity -eq 0
                }
            }

            It 'should log driver package confirmation success with PackageID' {
                $mockHardwareData = @{
                    Manufacturer = $script:TestManufacturer
                    SystemSKU    = $script:TestSystemSKU
                }
                $mockDriverPackage = @{
                    Description  = "(Models included:$($script:TestSystemSKU))"
                    Manufacturer = $script:TestManufacturer
                    Name         = "Drivers - $($script:TestManufacturer)"
                    PackageID    = 'ABC00008'
                    Version      = 'A17'
                    SourceDate   = '2025-08-15T12:00:00Z'
                }

                Mock Get-HardwareData {
                    return $mockHardwareData
                }
                Mock Set-DriverPackageQuery {
                    return $script:TestUri
                }
                Mock Get-DriverPackageList {
                    return @($mockDriverPackage)
                }
                Mock Confirm-DriverPackageList {
                    return $mockDriverPackage
                }
                Mock Set-DriverPackageQueryResult { }

                Find-DriverPackage -ServerFQDN $script:TestServerFQDN | Out-Null

                Should -Invoke Write-LogEntry -ParameterFilter {
                    $Message -eq "Driver package found and confirmed successfully. PackageID: ABC00008" -and
                    $Severity -eq 0
                }
            }
        }
    }
}

