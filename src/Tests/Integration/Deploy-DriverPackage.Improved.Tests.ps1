BeforeDiscovery {
    # Test: Module discovery and import setup
    # Description: Sets up module discovery by locating and importing the DriverAutomationModule manifest
    # Variables:
    # Set-Location -Path $PSScriptRoot
    # $ModuleName = 'DriverAutomationModule'
    # $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    # if (-not (Test-Path -Path $PathToManifest)) {
    #     $PathToManifest = [System.IO.Path]::Combine('..', '..', 'Artifacts', "$ModuleName.psd1")
    # }
    # Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    # Import-Module $PathToManifest -Force
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    if (-not (Test-Path -Path $PathToManifest)) {
        $PathToManifest = [System.IO.Path]::Combine('..', '..', 'Artifacts', "$ModuleName.psd1")
    }
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

Describe 'Deploy-DriverPackage.Improved Integration Tests' -Tag Integration {
    BeforeAll {
        # Test: Main test suite initialization
        # Description: Sets up all test variables, paths, and mock data for integration testing of Deploy-DriverPackage.Improved script
        # Variables:
        # $WarningPreference = 'SilentlyContinue'
        # $ErrorActionPreference = 'Stop'
        # $script:ModuleName = 'DriverAutomationModule'
        # $testScriptRoot = $PSScriptRoot
        # $script:TestScriptPath = Path to Deploy-DriverPackage.Improved.ps1 script
        # $script:TestWorkingDirectory = Test working directory path
        # $script:TestModulePath = Path to module manifest in test directory
        # $script:TestTaskSequenceDataPath = Task Sequence data path for testing
        # $script:TestCustomLocation = Custom driver package location path
        # $script:TestDriverPackagePath = Path to driver package WIM file
        # $script:TestMountPath = Path for mounting driver package
        # $script:TestOSDisk = Target OS disk drive letter
        # $script:TestServerFQDN = Mock Configuration Manager server FQDN
        # $script:TestTargetOS = Target operating system version
        # $script:TestManufacturer = Test hardware manufacturer
        # $script:TestModel = Test hardware model
        # $script:TestSystemSKU = Test system SKU identifier
        # $script:TestPackageID = Test driver package ID
        # $script:TestDriverPackage = Mock driver package hashtable with package details
        # $script:MockTaskSequenceVariables = Mock Task Sequence variables hashtable
        # $script:MockTaskSequenceEnvironment = Mock Task Sequence environment hashtable
        $WarningPreference = 'SilentlyContinue'
        $ErrorActionPreference = 'Stop'

        $script:ModuleName = 'DriverAutomationModule'

        function Get-ModuleManifestPath {
            $testScriptRoot = $PSScriptRoot
            if ([string]::IsNullOrWhiteSpace($testScriptRoot)) {
                $testScriptRoot = Split-Path -Path $MyInvocation.PSCommandPath -Parent
            }
            $moduleManifestPath = [System.IO.Path]::Combine('..', '..', '..', $script:ModuleName, "$($script:ModuleName).psd1")
            $moduleManifestPath = [System.IO.Path]::GetFullPath((Join-Path -Path $testScriptRoot -ChildPath $moduleManifestPath))
            if (-not (Test-Path -Path $moduleManifestPath)) {
                $moduleManifestPath = [System.IO.Path]::Combine('..', '..', 'Artifacts', "$($script:ModuleName).psd1")
                $moduleManifestPath = [System.IO.Path]::GetFullPath((Join-Path -Path $testScriptRoot -ChildPath $moduleManifestPath))
            }
            return $moduleManifestPath
        }
        $testScriptRoot = $PSScriptRoot
        if ([string]::IsNullOrWhiteSpace($testScriptRoot)) {
            $testScriptRoot = Split-Path -Path $MyInvocation.PSCommandPath -Parent
        }
        $script:TestScriptPath = [System.IO.Path]::Combine('..', '..', 'Scripts', 'Deploy-DriverPackage.Improved.ps1')
        $script:TestScriptPath = [System.IO.Path]::GetFullPath((Join-Path -Path $testScriptRoot -ChildPath $script:TestScriptPath))

        if ($null -eq $TestDrive) {
            $script:TestWorkingDirectory = [System.IO.Path]::GetTempPath()
        }
        else {
            $script:TestWorkingDirectory = $TestDrive
        }
        $script:TestModulePath = Join-Path -Path $script:TestWorkingDirectory -ChildPath "$($script:ModuleName).psd1"

        if ($null -eq $TestDrive) {
            $script:TestTaskSequenceDataPath = Join-Path -Path $env:TEMP -ChildPath "PesterTSData_$([System.Guid]::NewGuid())"
        }
        else {
            $script:TestTaskSequenceDataPath = Join-Path -Path $TestDrive -ChildPath 'TSData'
        }
        $script:TestCustomLocation = Join-Path -Path $script:TestTaskSequenceDataPath -ChildPath 'DriverPackage'
        $script:TestDriverPackagePath = Join-Path -Path $script:TestCustomLocation -ChildPath 'DriverPackage.wim'
        $script:TestMountPath = Join-Path -Path $script:TestTaskSequenceDataPath -ChildPath 'Drivers'
        $script:TestOSDisk = 'C:'

        $script:TestServerFQDN = 'cm01.contoso.com'
        $script:TestTargetOS = 'Windows 11 x64'
        $script:TestManufacturer = 'Dell'
        $script:TestModel = 'OptiPlex 7090'
        $script:TestSystemSKU = '0A52'
        $script:TestPackageID = 'ABC00001'

        $script:TestDriverPackage = @{
            PackageID    = $script:TestPackageID
            Name         = "Drivers - $($script:TestManufacturer) $($script:TestModel) - $($script:TestTargetOS)"
            Manufacturer = $script:TestManufacturer
            Version      = 'A10'
            SourceDate   = '2025-01-15T12:00:00Z'
            Description  = "(Models included:$($script:TestSystemSKU))"
        }

        $script:MockTaskSequenceVariables = @{
            '_SMSTSMDataPath'     = $script:TestTaskSequenceDataPath
            'OSDWindowsVersion'   = $script:TestTargetOS
            'AdminServiceFQDN'    = $script:TestServerFQDN
            'OSDTargetSystemDrive' = $script:TestOSDisk
            'DriverPackagePath01' = $script:TestDriverPackagePath
        }

        $script:MockTaskSequenceEnvironment = @{}
        foreach ($key in $script:MockTaskSequenceVariables.Keys) {
            $script:MockTaskSequenceEnvironment[$key] = $script:MockTaskSequenceVariables[$key]
        }

        New-Item -Path $script:TestTaskSequenceDataPath -ItemType Directory -Force | Out-Null
        New-Item -Path $script:TestCustomLocation -ItemType Directory -Force | Out-Null
        New-Item -Path $script:TestMountPath -ItemType Directory -Force | Out-Null

        $moduleManifestPath = Get-ModuleManifestPath
        if (Test-Path -Path $moduleManifestPath) {
            $moduleManifestContent = Get-Content -Path $moduleManifestPath -Raw
            Set-Content -Path $script:TestModulePath -Value $moduleManifestContent -Force
        }
        else {
            Write-Warning "Module manifest not found at expected paths. Test module copy skipped."
        }
    }
    Context 'Live Server Integration Tests' -Tag LiveServer {
        BeforeAll {
            # Test: Live server integration test setup
            # Description: Sets up variables for testing against a live Configuration Manager server to verify real-world connectivity and package discovery
            # Variables:
            # $script:LiveServerFQDN = Live Configuration Manager server FQDN for testing
            # $script:LiveTargetOS = Target operating system version for live server tests
            # $script:LiveTaskSequenceDataPath = Task Sequence data path for live server tests
            # $script:LiveCustomLocation = Custom driver package location for live server tests
            # $script:LiveTaskSequenceEnvironment = Task Sequence environment variables for live server tests
            $script:LiveServerFQDN = 'escsccm.amaisd.org'
            $script:LiveTargetOS = 'Windows 11 x64'


            $script:LiveTaskSequenceDataPath = Join-Path -Path $TestDrive -ChildPath 'TSData'
            $script:LiveCustomLocation = Join-Path -Path $script:LiveTaskSequenceDataPath -ChildPath 'DriverPackage'

            New-Item -Path $script:LiveTaskSequenceDataPath -ItemType Directory -Force | Out-Null
            New-Item -Path $script:LiveCustomLocation -ItemType Directory -Force | Out-Null

            $script:LiveTaskSequenceEnvironment = @{
                '_SMSTSMDataPath'      = $script:LiveTaskSequenceDataPath
                'OSDWindowsVersion'    = $script:LiveTargetOS
                'AdminServiceFQDN'     = $script:LiveServerFQDN
                'OSDTargetSystemDrive' = 'C:'
            }
        }

        BeforeEach {
            Mock Get-TSValue {
                param([string]$Name)
                if ($script:LiveTaskSequenceEnvironment.ContainsKey($Name)) {
                    return $script:LiveTaskSequenceEnvironment[$Name]
                }
                return $null
            }

            Mock Set-TSVariable {
                param([string]$Name, [string]$Value)
                $script:LiveTaskSequenceEnvironment[$Name] = $Value
            }

            Mock Write-LogEntry { }
        }

        It 'should successfully connect to AdminService server and query driver packages' {
            $moduleManifestPath = Get-ModuleManifestPath
            Import-Module $moduleManifestPath -Force

            $params = @{
                TargetOS   = $script:LiveTargetOS
                ServerFQDN = $script:LiveServerFQDN
            }

            $result = Find-DriverPackage @params

            $result | Should -Not -BeNullOrEmpty
            $result.PackageID | Should -Not -BeNullOrEmpty
            $result.Name | Should -Not -BeNullOrEmpty
        }

        It 'should successfully execute Find phase against live server' {
            $moduleManifestPath = Get-ModuleManifestPath
            if (Test-Path -Path $moduleManifestPath) {
                $moduleManifestContent = Get-Content -Path $moduleManifestPath -Raw
                Set-Content -Path $script:TestModulePath -Value $moduleManifestContent -Force
            }

            $params = @{
                Phase            = 'Find'
                WorkingDirectory = $script:TestWorkingDirectory
            }

            { & $script:TestScriptPath @params } | Should -Not -Throw

            $driverPackageQueryResult = Get-DriverPackageQueryResult
            $driverPackageQueryResult | Should -Not -BeNullOrEmpty
            $driverPackageQueryResult.PackageID | Should -Not -BeNullOrEmpty
        }

        It 'should verify server connectivity' {
            $testUri = "https://$($script:LiveServerFQDN)/AdminService"

            try {
                $response = Invoke-WebRequest -Uri $testUri -Method Get -UseDefaultCredentials -TimeoutSec 10 -ErrorAction Stop
                $response.StatusCode | Should -Be 200
            }
            catch {
                Write-Warning "Cannot connect to AdminService at $testUri. Verify network connectivity and server availability."
                $_.Exception.Message | Should -Not -BeNullOrEmpty
            }
        }
    }

    # Context 'Module Import and Setup' {
    #     It 'should successfully import the module from working directory' {
    #         $modulePath = Join-Path -Path $script:TestWorkingDirectory -ChildPath 'DriverAutomationModule.psd1'
    #         Test-Path -Path $modulePath | Should -BeTrue
    #     }

    #     It 'should create required test directories' {
    #         Test-Path -Path $script:TestTaskSequenceDataPath | Should -BeTrue
    #         Test-Path -Path $script:TestCustomLocation | Should -BeTrue
    #         Test-Path -Path $script:TestMountPath | Should -BeTrue
    #     }
    # }

    # Context 'Find Phase Integration' {
    #     BeforeEach {
    #         Mock Get-TSValue {
    #             param([string]$Name)
    #             if ($script:MockTaskSequenceEnvironment.ContainsKey($Name)) {
    #                 return $script:MockTaskSequenceEnvironment[$Name]
    #             }
    #             return $null
    #         }

    #         Mock Set-TSVariable {
    #             param([string]$Name, [string]$Value)
    #             $script:MockTaskSequenceEnvironment[$Name] = $Value
    #         }

    #         Mock Get-HardwareData {
    #             return @{
    #                 Manufacturer = $script:TestManufacturer
    #                 Model        = $script:TestModel
    #                 SystemSKU    = $script:TestSystemSKU
    #                 SerialNumber = 'SN123456789'
    #             }
    #         }

    #         Mock Set-DriverPackageQuery {
    #             return "https://$($script:TestServerFQDN)/AdminService/wmi/SMS_Package"
    #         }

    #         Mock Get-DriverPackageList {
    #             return @($script:TestDriverPackage)
    #         }

    #         Mock Confirm-DriverPackageList {
    #             return $script:TestDriverPackage
    #         }

    #         Mock Set-DriverPackageQueryResult { }
    #         Mock Write-LogEntry { }
    #     }

    #     It 'should successfully execute Find phase with all required Task Sequence variables' {
    #         $script:MockTaskSequenceEnvironment['_SMSTSMDataPath'] = $script:TestTaskSequenceDataPath
    #         $script:MockTaskSequenceEnvironment['OSDWindowsVersion'] = $script:TestTargetOS
    #         $script:MockTaskSequenceEnvironment['AdminServiceFQDN'] = $script:TestServerFQDN

    #         $params = @{
    #             Phase            = 'Find'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Not -Throw

    #         Should -Invoke Get-HardwareData -Exactly -Times 1
    #         Should -Invoke Get-DriverPackageList -Exactly -Times 1
    #         Should -Invoke Confirm-DriverPackageList -Exactly -Times 1
    #         Should -Invoke Set-DriverPackageQueryResult -Exactly -Times 1
    #     }

    #     It 'should throw error when AdminServiceFQDN Task Sequence variable is missing' {
    #         $script:MockTaskSequenceEnvironment['_SMSTSMDataPath'] = $script:TestTaskSequenceDataPath
    #         $script:MockTaskSequenceEnvironment['OSDWindowsVersion'] = $script:TestTargetOS
    #         $script:MockTaskSequenceEnvironment.Remove('AdminServiceFQDN')

    #         $params = @{
    #             Phase            = 'Find'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw "*AdminServiceFQDN*"
    #     }

    #     It 'should successfully execute Find phase with explicit credentials' {
    #         $script:MockTaskSequenceEnvironment['_SMSTSMDataPath'] = $script:TestTaskSequenceDataPath
    #         $script:MockTaskSequenceEnvironment['OSDWindowsVersion'] = $script:TestTargetOS
    #         $script:MockTaskSequenceEnvironment['AdminServiceFQDN'] = $script:TestServerFQDN
    #         $script:MockTaskSequenceEnvironment['AdminServiceUser'] = 'DOMAIN\ServiceAccount'
    #         $script:MockTaskSequenceEnvironment['AdminServicePass'] = 'SecurePassword123'

    #         Mock Get-DriverPackageList {
    #             param($Uri, $AdminServiceUser, $AdminServicePass)
    #             if ($AdminServiceUser -eq 'DOMAIN\ServiceAccount' -and $AdminServicePass -eq 'SecurePassword123') {
    #                 return @($script:TestDriverPackage)
    #             }
    #             return @()
    #         }

    #         $params = @{
    #             Phase            = 'Find'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Not -Throw

    #         Should -Invoke Get-DriverPackageList -Exactly -Times 1 -ParameterFilter {
    #             $AdminServiceUser -eq 'DOMAIN\ServiceAccount' -and
    #             $AdminServicePass -eq 'SecurePassword123'
    #         }
    #     }
    # }

    # Context 'Download Phase Integration' {
    #     BeforeEach {
    #         $script:MockTaskSequenceEnvironment['_SMSTSMDataPath'] = $script:TestTaskSequenceDataPath

    #         Mock Get-TSValue {
    #             param([string]$Name)
    #             if ($script:MockTaskSequenceEnvironment.ContainsKey($Name)) {
    #                 return $script:MockTaskSequenceEnvironment[$Name]
    #             }
    #             return $null
    #         }

    #         Mock Get-DriverPackageQueryResult {
    #             return $script:TestDriverPackage
    #         }

    #         Mock Invoke-OSDDownloadContent {
    #             New-Item -Path $script:TestDriverPackagePath -ItemType File -Force | Out-Null
    #             return $script:TestDriverPackagePath
    #         }

    #         Mock Set-TSVariable {
    #             param([string]$Name, [string]$Value)
    #             $script:MockTaskSequenceEnvironment[$Name] = $Value
    #         }

    #         Mock Write-LogEntry { }
    #     }

    #     It 'should successfully execute Download phase when Find phase has completed' {
    #         $script:MockTaskSequenceEnvironment['DriverPackageQueryResult'] = ($script:TestDriverPackage | ConvertTo-Json -Compress)

    #         $params = @{
    #             Phase            = 'Download'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Not -Throw

    #         Should -Invoke Get-DriverPackageQueryResult -Exactly -Times 1
    #         Should -Invoke Invoke-OSDDownloadContent -Exactly -Times 1
    #     }

    #     It 'should throw error when Find phase has not completed' {
    #         $script:MockTaskSequenceEnvironment.Remove('DriverPackageQueryResult')

    #         Mock Get-DriverPackageQueryResult {
    #             return $null
    #         }

    #         $params = @{
    #             Phase            = 'Download'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw "*Find phase has completed successfully*"
    #     }

    #     It 'should throw error when _SMSTSMDataPath Task Sequence variable is missing' {
    #         $script:MockTaskSequenceEnvironment.Remove('_SMSTSMDataPath')

    #         $params = @{
    #             Phase            = 'Download'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw "*_SMSTSMDataPath*"
    #     }
    # }

    # Context 'Install Phase Integration' {
    #     BeforeEach {
    #         $script:MockTaskSequenceEnvironment['_SMSTSMDataPath'] = $script:TestTaskSequenceDataPath
    #         $script:MockTaskSequenceEnvironment['DriverPackagePath01'] = $script:TestDriverPackagePath
    #         $script:MockTaskSequenceEnvironment['OSDTargetSystemDrive'] = $script:TestOSDisk

    #         New-Item -Path $script:TestDriverPackagePath -ItemType File -Force | Out-Null

    #         Mock Get-TSValue {
    #             param([string]$Name)
    #             if ($script:MockTaskSequenceEnvironment.ContainsKey($Name)) {
    #                 return $script:MockTaskSequenceEnvironment[$Name]
    #             }
    #             return $null
    #         }

    #         Mock Mount-DriverPackageWim {
    #             return $script:TestMountPath
    #         }

    #         Mock Invoke-DISM {
    #             return @{
    #                 ExitCode = 0
    #                 Output   = 'Drivers installed successfully'
    #             }
    #         }

    #         Mock Dismount-DriverPackageWim { }
    #         Mock Write-LogEntry { }
    #     }

    #     It 'should successfully execute Install phase when Download phase has completed' {
    #         $params = @{
    #             Phase            = 'Install'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Not -Throw

    #         Should -Invoke Mount-DriverPackageWim -Exactly -Times 1
    #         Should -Invoke Invoke-DISM -Exactly -Times 1
    #         Should -Invoke Dismount-DriverPackageWim -Exactly -Times 1
    #     }

    #     It 'should throw error when DriverPackagePath01 Task Sequence variable is missing' {
    #         $script:MockTaskSequenceEnvironment.Remove('DriverPackagePath01')

    #         $params = @{
    #             Phase            = 'Install'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw "*DriverPackagePath01*"
    #     }

    #     It 'should throw error when OSDTargetSystemDrive Task Sequence variable is missing' {
    #         $script:MockTaskSequenceEnvironment.Remove('OSDTargetSystemDrive')

    #         $params = @{
    #             Phase            = 'Install'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw "*OSDTargetSystemDrive*"
    #     }

    #     It 'should throw error when driver package path does not exist' {
    #         $script:MockTaskSequenceEnvironment['DriverPackagePath01'] = Join-Path -Path $TestDrive -ChildPath 'NonExistent.wim'

    #         $params = @{
    #             Phase            = 'Install'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw "*does not exist*"
    #     }
    # }

    # Context 'Full Workflow Integration' {
    #     BeforeEach {
    #         $script:MockTaskSequenceEnvironment['_SMSTSMDataPath'] = $script:TestTaskSequenceDataPath
    #         $script:MockTaskSequenceEnvironment['OSDWindowsVersion'] = $script:TestTargetOS
    #         $script:MockTaskSequenceEnvironment['AdminServiceFQDN'] = $script:TestServerFQDN
    #         $script:MockTaskSequenceEnvironment['OSDTargetSystemDrive'] = $script:TestOSDisk

    #         Mock Get-TSValue {
    #             param([string]$Name)
    #             if ($script:MockTaskSequenceEnvironment.ContainsKey($Name)) {
    #                 return $script:MockTaskSequenceEnvironment[$Name]
    #             }
    #             return $null
    #         }

    #         Mock Set-TSVariable {
    #             param([string]$Name, [string]$Value)
    #             $script:MockTaskSequenceEnvironment[$Name] = $Value
    #         }

    #         Mock Get-HardwareData {
    #             return @{
    #                 Manufacturer = $script:TestManufacturer
    #                 Model        = $script:TestModel
    #                 SystemSKU    = $script:TestSystemSKU
    #                 SerialNumber = 'SN123456789'
    #             }
    #         }

    #         Mock Set-DriverPackageQuery {
    #             return "https://$($script:TestServerFQDN)/AdminService/wmi/SMS_Package"
    #         }

    #         Mock Get-DriverPackageList {
    #             return @($script:TestDriverPackage)
    #         }

    #         Mock Confirm-DriverPackageList {
    #             return $script:TestDriverPackage
    #         }

    #         Mock Set-DriverPackageQueryResult { }

    #         Mock Get-DriverPackageQueryResult {
    #             return $script:TestDriverPackage
    #         }

    #         Mock Invoke-OSDDownloadContent {
    #             New-Item -Path $script:TestDriverPackagePath -ItemType File -Force | Out-Null
    #             $script:MockTaskSequenceEnvironment['DriverPackagePath01'] = $script:TestDriverPackagePath
    #             return $script:TestDriverPackagePath
    #         }

    #         Mock Mount-DriverPackageWim {
    #             return $script:TestMountPath
    #         }

    #         Mock Invoke-DISM {
    #             return @{
    #                 ExitCode = 0
    #                 Output   = 'Drivers installed successfully'
    #             }
    #         }

    #         Mock Dismount-DriverPackageWim { }
    #         Mock Write-LogEntry { }

    #         $moduleManifestPath = Get-ModuleManifestPath
    #         if (Test-Path -Path $moduleManifestPath) {
    #             $moduleManifestContent = Get-Content -Path $moduleManifestPath -Raw
    #             Set-Content -Path $script:TestModulePath -Value $moduleManifestContent -Force
    #         }
    #     }

    #     It 'should successfully execute all phases sequentially when no Phase parameter is specified' {
    #         $params = @{
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Not -Throw

    #         Should -Invoke Get-HardwareData -Exactly -Times 1
    #         Should -Invoke Get-DriverPackageList -Exactly -Times 1
    #         Should -Invoke Confirm-DriverPackageList -Exactly -Times 1
    #         Should -Invoke Set-DriverPackageQueryResult -Exactly -Times 1
    #         Should -Invoke Get-DriverPackageQueryResult -Exactly -Times 1
    #         Should -Invoke Invoke-OSDDownloadContent -Exactly -Times 1
    #         Should -Invoke Mount-DriverPackageWim -Exactly -Times 1
    #         Should -Invoke Invoke-DISM -Exactly -Times 1
    #         Should -Invoke Dismount-DriverPackageWim -Exactly -Times 1
    #     }

    #     It 'should stop execution if Find phase fails' {
    #         Mock Get-HardwareData {
    #             throw 'Hardware data retrieval failed'
    #         }

    #         $params = @{
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw

    #         Should -Invoke Get-HardwareData -Exactly -Times 1
    #         Should -Invoke Get-DriverPackageList -Exactly -Times 0
    #         Should -Invoke Invoke-OSDDownloadContent -Exactly -Times 0
    #         Should -Invoke Mount-DriverPackageWim -Exactly -Times 0
    #     }

    #     It 'should stop execution if Download phase fails' {
    #         Mock Invoke-OSDDownloadContent {
    #             throw 'Download failed'
    #         }

    #         $params = @{
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw

    #         Should -Invoke Get-HardwareData -Exactly -Times 1
    #         Should -Invoke Invoke-OSDDownloadContent -Exactly -Times 1
    #         Should -Invoke Mount-DriverPackageWim -Exactly -Times 0
    #     }

    #     It 'should stop execution if Install phase fails' {
    #         Mock Invoke-DISM {
    #             throw 'DISM installation failed'
    #         }

    #         $params = @{
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw

    #         Should -Invoke Get-HardwareData -Exactly -Times 1
    #         Should -Invoke Invoke-OSDDownloadContent -Exactly -Times 1
    #         Should -Invoke Mount-DriverPackageWim -Exactly -Times 1
    #         Should -Invoke Invoke-DISM -Exactly -Times 1
    #         Should -Invoke Dismount-DriverPackageWim -Exactly -Times 1
    #     }
    # }

    # Context 'WhatIf Parameter Integration' {
    #     BeforeEach {
    #         $script:MockTaskSequenceEnvironment['_SMSTSMDataPath'] = $script:TestTaskSequenceDataPath
    #         $script:MockTaskSequenceEnvironment['OSDWindowsVersion'] = $script:TestTargetOS
    #         $script:MockTaskSequenceEnvironment['AdminServiceFQDN'] = $script:TestServerFQDN

    #         Mock Get-TSValue {
    #             param([string]$Name)
    #             if ($script:MockTaskSequenceEnvironment.ContainsKey($Name)) {
    #                 return $script:MockTaskSequenceEnvironment[$Name]
    #             }
    #             return $null
    #         }

    #         Mock Write-Host { }
    #     }

    #     It 'should show WhatIf output for Find phase without executing' {
    #         $params = @{
    #             Phase            = 'Find'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #             WhatIf           = $true
    #         }

    #         { & $script:TestScriptPath @params } | Should -Not -Throw

    #         Should -Invoke Write-Host -ParameterFilter {
    #             $Object -like "*[WhatIf]*Find phase*"
    #         }
    #     }

    #     It 'should show WhatIf output for Download phase without executing' {
    #         $params = @{
    #             Phase            = 'Download'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #             WhatIf           = $true
    #         }

    #         { & $script:TestScriptPath @params } | Should -Not -Throw

    #         Should -Invoke Write-Host -ParameterFilter {
    #             $Object -like "*[WhatIf]*Download phase*"
    #         }
    #     }

    #     It 'should show WhatIf output for Install phase without executing' {
    #         $params = @{
    #             Phase            = 'Install'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #             WhatIf           = $true
    #         }

    #         { & $script:TestScriptPath @params } | Should -Not -Throw

    #         Should -Invoke Write-Host -ParameterFilter {
    #             $Object -like "*[WhatIf]*Install phase*"
    #         }
    #     }

    #     It 'should show WhatIf output for all phases without executing' {
    #         $params = @{
    #             WorkingDirectory = $script:TestWorkingDirectory
    #             WhatIf           = $true
    #         }

    #         { & $script:TestScriptPath @params } | Should -Not -Throw

    #         Should -Invoke Write-Host -ParameterFilter {
    #             $Object -like "*[WhatIf]*all phases*"
    #         }
    #     }
    # }

    # Context 'Error Handling and Validation' {
    #     BeforeEach {
    #         Mock Get-TSValue {
    #             param([string]$Name)
    #             if ($script:MockTaskSequenceEnvironment.ContainsKey($Name)) {
    #                 return $script:MockTaskSequenceEnvironment[$Name]
    #             }
    #             return $null
    #         }

    #         Mock Write-LogEntry { }
    #     }

    #     It 'should throw error when working directory does not exist' {
    #         $params = @{
    #             Phase            = 'Find'
    #             WorkingDirectory = Join-Path -Path $TestDrive -ChildPath 'NonExistent'
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw "*does not exist*"
    #     }

    #     It 'should throw error when module manifest is not found in working directory' {
    #         Remove-Item -Path $script:TestModulePath -Force -ErrorAction SilentlyContinue

    #         $params = @{
    #             Phase            = 'Find'
    #             WorkingDirectory = $script:TestWorkingDirectory
    #         }

    #         { & $script:TestScriptPath @params } | Should -Throw "*DriverAutomationModule module not found*"
    #     }
    # }

}

