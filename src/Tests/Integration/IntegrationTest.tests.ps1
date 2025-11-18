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
                TargetOS = 'Windows 11 x64'
                ServerFQDN = 'escsccm.amaisd.org'
                Manufacturer = 'Dell'
            }
        }
        It 'should find a driver package for the local machine with CIM queries' {
            # Mock Get-TSValue {}
            $params = @{
                TargetOS         = $actual.TargetOS
                ServerFQDN       = $actual.ServerFQDN
            }
            $result = Find-DriverPackage @params
            $result | Should -Not -BeNullOrEmpty
            $result.PackageID | Should -Not -BeNullOrEmpty
            $result.Name | Should -Not -BeNullOrEmpty
        }
    }
}
