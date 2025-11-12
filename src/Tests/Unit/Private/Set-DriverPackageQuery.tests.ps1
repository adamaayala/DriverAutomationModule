BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Set-DriverPackageQuery -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
            $script:ServerFQDN = "escsccm.amaisd.org"
            Mock Write-LogEntry { }
        }
        Context 'Success' {
            It "Should create a basic query with only ServerFQDN" {
                $result = Set-DriverPackageQuery -ServerFQDN $script:ServerFQDN
                $expected = "https://$($script:ServerFQDN)/AdminService/wmi/SMS_Package?`$filter=startswith(Name,'Drivers%20-')&`$select=Name,Description,Manufacturer,Version,SourceDate,PackageID,MIFName,MIFVersion"
                $result | Should -Be $expected
            }

            It "Should include Manufacturer in the query" {
                $result = Set-DriverPackageQuery -ServerFQDN $script:ServerFQDN -Manufacturer "Dell"
                $result | Should -Match "and%20contains\(Name,'Dell'\)"
            }

            It "Should include SystemSKU in the query" {
                $result = Set-DriverPackageQuery -ServerFQDN $script:ServerFQDN -SystemSKU "0A52"
                $result | Should -Match "and%20contains\(Description,'0A52'\)"
            }

            It "Should include TargetOS in the query" {
                $result = Set-DriverPackageQuery -ServerFQDN $script:ServerFQDN -TargetOS "Windows 11 x64"
                $result | Should -Match "and%20contains\(Name,'Windows%2011%20x64'\)"
            }

            It "Should include all parameters in the query" {
                $result = Set-DriverPackageQuery -ServerFQDN $script:ServerFQDN -Manufacturer "Dell" -SystemSKU "0A52" -TargetOS "Windows 11 x64"
                $result | Should -Match "and%20contains\(Description,'0A52'\)"
                $result | Should -Match "and%20contains\(Name,'Dell'\)"
                $result | Should -Match "and%20contains\(Name,'Windows%2011%20x64'\)"
            }

            It "Should properly escape special characters in parameters" {
                $expected = "https://$($script:ServerFQDN)/AdminService/wmi/SMS_Package?`$filter=startswith(Name,'Drivers%20-')%20and%20contains(Name,'Lenovo%20&%20Co.')&`$select=Name,Description,Manufacturer,Version,SourceDate,PackageID,MIFName,MIFVersion"
                $result = Set-DriverPackageQuery -ServerFQDN $script:ServerFQDN -Manufacturer "Lenovo & Co."
                $result | Should -Be $expected
            }
        }

        # Context 'Error' {
            # It 'should ...' {
            # }
        # }

    }
}

