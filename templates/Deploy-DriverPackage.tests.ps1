# BeforeDiscovery {
#     Set-Location -Path $PSScriptRoot
#     $ModuleName = 'DriverAutomationModule'
#     $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
#     if (-not (Test-Path -Path $PathToManifest)) {
#         $PathToManifest = [System.IO.Path]::Combine('..', '..', 'Artifacts', "$ModuleName.psd1")
#     }
#     Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
#     Import-Module $PathToManifest -Force
# }

BeforeAll {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', $ModuleName, "$ModuleName.psd1")
    if (-not (Test-Path -Path $PathToManifest)) {
        $PathToManifest = [System.IO.Path]::Combine('..', '..', 'Artifacts', "$ModuleName.psd1")
    }

    if (-not (Test-Path -Path $PathToManifest)) {
        throw "Module manifest not found at: $PathToManifest"
    }

    # Resolve to absolute path to ensure module loads correctly
    $PathToManifest = Resolve-Path -Path $PathToManifest | Select-Object -ExpandProperty Path

    #if the module is already in memory, remove it
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force

    # Import module and capture any errors
    try {
        Import-Module $PathToManifest -Force -ErrorAction Stop
    }
    catch {
        throw "Failed to import module: $_"
    }

    # Verify module is loaded
    $module = Get-Module $ModuleName
    if (-not $module) {
        throw "Module $ModuleName failed to import - module not found after import"
    }
}


Describe 'Deploy-DriverPackage.Improved Integration Tests' -Tag Integration {
    Context 'Live Server Integration Tests' -Tag LiveServer {
        BeforeAll {
            # Pester Test Drive: https://pester.dev/docs/usage/testdrive
            $testDrive = "TestDrive:\"

            # Test session variables
            $testVars = @{
                'ServerFQDN'           = 'escsccm.amaisd.org'
                'TargetOS'             = 'Windows 11 x64'
                'TaskSequenceDataPath' = Join-Path -Path $testDrive -ChildPath 'TSData'
                'CustomLocation'       = Join-Path -Path $testDrive -ChildPath 'DriverPackage'
                '_SMSTSMDataPath'      = Join-Path -Path $testDrive -ChildPath 'TSData'
                'OSDWindowsVersion'    = 'Windows 11 x64'
                'AdminServiceFQDN'     = 'escsccm.amaisd.org'
            }

            # Create test directories in pesters test drive
            New-Item -Path $testVars.TaskSequenceDataPath -ItemType Directory -Force | Out-Null
            New-Item -Path $testVars.CustomLocation -ItemType Directory -Force | Out-Null

            Mock Set-TSVariable -ModuleName 'DriverAutomationModule' { }
        }

        It 'should successfully connect to AdminService server and query driver packages' {
            $params = @{
                TargetOS   = $testVars['TargetOS']
                ServerFQDN = $testVars['ServerFQDN']
            }

            $result = Find-DriverPackage @params

            $result | Should -Not -BeNullOrEmpty
            $result.PackageID | Should -Not -BeNullOrEmpty
            $result.Name | Should -Not -BeNullOrEmpty
        }

        # It 'should successfully execute Find phase against live server' {
        #     $moduleManifestPath = Get-ModuleManifestPath
        #     if (Test-Path -Path $moduleManifestPath) {
        #         $moduleManifestContent = Get-Content -Path $moduleManifestPath -Raw
        #         Set-Content -Path $script:TestModulePath -Value $moduleManifestContent -Force
        #     }

        #     $params = @{
        #         Phase            = 'Find'
        #         WorkingDirectory = $script:TestWorkingDirectory
        #     }

        #     { & $script:TestScriptPath @params } | Should -Not -Throw

        #     $driverPackageQueryResult = Get-DriverPackageQueryResult
        #     $driverPackageQueryResult | Should -Not -BeNullOrEmpty
        #     $driverPackageQueryResult.PackageID | Should -Not -BeNullOrEmpty
        # }

        # It 'should verify server connectivity' {
        #     $testUri = "https://$($script:LiveServerFQDN)/AdminService"

        #     try {
        #         $response = Invoke-WebRequest -Uri $testUri -Method Get -UseDefaultCredentials -TimeoutSec 10 -ErrorAction Stop
        #         $response.StatusCode | Should -Be 200
        #     }
        #     catch {
        #         Write-Warning "Cannot connect to AdminService at $testUri. Verify network connectivity and server availability."
        #         $_.Exception.Message | Should -Not -BeNullOrEmpty
        #     }
        # }
    }

}

