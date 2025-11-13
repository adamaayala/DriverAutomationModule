BeforeDiscovery {
    Set-Location -Path $PSScriptRoot
    $ModuleName = 'DriverAutomationModule'
    $PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
    Get-Module $ModuleName -ErrorAction SilentlyContinue | Remove-Module -Force
    Import-Module $PathToManifest -Force
}

InModuleScope 'DriverAutomationModule' {
    Describe Get-HardwareData -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
        }

        Context 'Success - Dell Manufacturer' {
            It 'should return normalized Dell hardware data with SystemSKU and SerialNumber' {
                $testSystemSKU = '0ABC123'
                $testSerialNumber = 'SN123456789'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\wmi'
                } {
                    return [PSCustomObject]@{
                        SystemSKU = "  $testSystemSKU  "
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_SystemEnclosure'
                } {
                    return @([PSCustomObject]@{
                        SerialNumber = "  $testSerialNumber  "
                    })
                }

                $result = Get-HardwareData -Manufacturer 'Dell Inc.' -Model 'OptiPlex 7090'

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 3
                $result.Manufacturer | Should -Be 'Dell'
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.SerialNumber | Should -Be $testSerialNumber
            }

            It 'should handle Dell manufacturer with wildcard matching' {
                $testSystemSKU = '0XYZ789'
                $testSerialNumber = 'SN987654321'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\wmi'
                } {
                    return [PSCustomObject]@{
                        SystemSKU = $testSystemSKU
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_SystemEnclosure'
                } {
                    return @([PSCustomObject]@{
                        SerialNumber = $testSerialNumber
                    })
                }

                $result = Get-HardwareData -Manufacturer 'Dell Technologies' -Model 'Latitude 5520'

                $result.Manufacturer | Should -Be 'Dell'
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.SerialNumber | Should -Be $testSerialNumber
            }
        }

        Context 'Success - ClearTouch Manufacturer' {
            It 'should return normalized ClearTouch hardware data using Model as SystemSKU and SerialNumber' {
                $testModel = 'CT-12345'

                $result = Get-HardwareData -Manufacturer 'Clear Touch Interactive' -Model $testModel

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 3
                $result.Manufacturer | Should -Be 'ClearTouch'
                $result.SystemSKU | Should -Be $testModel
                $result.SerialNumber | Should -Be $testModel
            }

            It 'should handle ClearTouch Interactive manufacturer variant' {
                $testModel = 'CT-67890'

                $result = Get-HardwareData -Manufacturer 'ClearTouch Interactive' -Model $testModel

                $result.Manufacturer | Should -Be 'ClearTouch'
                $result.SystemSKU | Should -Be $testModel
                $result.SerialNumber | Should -Be $testModel
            }

            It 'should handle ClearTouch manufacturer variant' {
                $testModel = 'CT-11111'

                $result = Get-HardwareData -Manufacturer 'ClearTouch' -Model $testModel

                $result.Manufacturer | Should -Be 'ClearTouch'
                $result.SystemSKU | Should -Be $testModel
                $result.SerialNumber | Should -Be $testModel
            }

            It 'should handle MAINBRD manufacturer variant' {
                $testModel = 'CT-22222'

                $result = Get-HardwareData -Manufacturer 'MAINBRD' -Model $testModel

                $result.Manufacturer | Should -Be 'ClearTouch'
                $result.SystemSKU | Should -Be $testModel
                $result.SerialNumber | Should -Be $testModel
            }
        }

        Context 'Success - Alienware Manufacturer' {
            It 'should return normalized Alienware hardware data with SystemSKU and SerialNumber' {
                $testSystemSKU = '0ALIEN123'
                $testSerialNumber = 'ALIEN123456'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\wmi'
                } {
                    return [PSCustomObject]@{
                        SystemSKU = $testSystemSKU
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_SystemEnclosure'
                } {
                    return @([PSCustomObject]@{
                        SerialNumber = $testSerialNumber
                    })
                }

                $result = Get-HardwareData -Manufacturer 'Alienware Corporation' -Model 'Aurora R13'

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 3
                $result.Manufacturer | Should -Be 'Alienware'
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.SerialNumber | Should -Be $testSerialNumber
            }
        }

        Context 'Success - Microsoft Manufacturer' {
            It 'should return normalized Microsoft hardware data with SystemSKU only' {
                $testSystemSKU = 'SurfacePro9'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\wmi'
                } {
                    return [PSCustomObject]@{
                        SystemSKU = $testSystemSKU
                    }
                }

                $result = Get-HardwareData -Manufacturer 'Microsoft Corporation' -Model 'Surface Pro 9'

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 2
                $result.Manufacturer | Should -Be 'Microsoft'
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.ContainsKey('SerialNumber') | Should -Be $false
            }
        }

        Context 'Success - HP/Hewlett-Packard Manufacturer' {
            It 'should return normalized HP hardware data with Model and SystemSKU' {
                $testModel = 'EliteBook 850 G8'
                $testSystemSKU = 'HP850G8'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = "  $testModel  "
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\WMI'
                } {
                    return [PSCustomObject]@{
                        BaseBoardProduct = "  $testSystemSKU  "
                    }
                }

                $result = Get-HardwareData -Manufacturer 'HP' -Model $testModel

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 3
                $result.Manufacturer | Should -Be 'Hewlett-Packard'
                $result.Model | Should -Be $testModel
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.ContainsKey('SerialNumber') | Should -Be $false
            }

            It 'should handle Hewlett-Packard manufacturer with wildcard matching' {
                $testModel = 'ProBook 450 G8'
                $testSystemSKU = 'HP450G8'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = $testModel
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\WMI'
                } {
                    return [PSCustomObject]@{
                        BaseBoardProduct = $testSystemSKU
                    }
                }

                $result = Get-HardwareData -Manufacturer 'Hewlett-Packard' -Model $testModel

                $result.Manufacturer | Should -Be 'Hewlett-Packard'
                $result.Model | Should -Be $testModel
                $result.SystemSKU | Should -Be $testSystemSKU
            }
        }

        Context 'Success - Lenovo Manufacturer' {
            It 'should return normalized Lenovo hardware data with Model and SystemSKU' {
                $testModel = 'ThinkPad X1 Carbon'
                $testVersion = 'ThinkPad X1 Carbon Gen 9'
                $testSystemSKU = '20X1'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystemProduct'
                } {
                    return [PSCustomObject]@{
                        Version = "  $testVersion  "
                    }
                }
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = "${testSystemSKU}2345"
                    }
                }

                $result = Get-HardwareData -Manufacturer 'Lenovo' -Model $testModel

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 3
                $result.Manufacturer | Should -Be 'Lenovo'
                $result.Model | Should -Be $testVersion
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.ContainsKey('SerialNumber') | Should -Be $false
            }

            It 'should handle Lenovo manufacturer with wildcard matching' {
                $testModel = 'ThinkPad T14'
                $testVersion = 'ThinkPad T14 Gen 2'
                $testSystemSKU = '20Y6'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystemProduct'
                } {
                    return [PSCustomObject]@{
                        Version = $testVersion
                    }
                }
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = "${testSystemSKU}7890"
                    }
                }

                $result = Get-HardwareData -Manufacturer 'Lenovo Group Limited' -Model $testModel

                $result.Manufacturer | Should -Be 'Lenovo'
                $result.Model | Should -Be $testVersion
                $result.SystemSKU | Should -Be $testSystemSKU
            }
        }

        Context 'Success - Panasonic Manufacturer' {
            It 'should return normalized Panasonic hardware data with Model and SystemSKU' {
                $testModel = 'Toughbook CF-33'
                $testSystemSKU = 'CF33SKU'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = "  $testModel  "
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\WMI'
                } {
                    return [PSCustomObject]@{
                        BaseBoardProduct = "  $testSystemSKU  "
                    }
                }

                $result = Get-HardwareData -Manufacturer 'Panasonic Corporation' -Model $testModel

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 3
                $result.Manufacturer | Should -Be 'Panasonic Corporation'
                $result.Model | Should -Be $testModel
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.ContainsKey('SerialNumber') | Should -Be $false
            }

            It 'should handle Panasonic manufacturer with wildcard matching' {
                $testModel = 'Toughbook CF-54'
                $testSystemSKU = 'CF54SKU'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = $testModel
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\WMI'
                } {
                    return [PSCustomObject]@{
                        BaseBoardProduct = $testSystemSKU
                    }
                }

                $result = Get-HardwareData -Manufacturer 'Panasonic' -Model $testModel

                $result.Manufacturer | Should -Be 'Panasonic Corporation'
                $result.Model | Should -Be $testModel
                $result.SystemSKU | Should -Be $testSystemSKU
            }
        }

        Context 'Success - Viglen Manufacturer' {
            It 'should return normalized Viglen hardware data with Model and SystemSKU' {
                $testModel = 'Viglen Desktop'
                $testSystemSKU = 'VIGLEN-SKU-123'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = "  $testModel  "
                    }
                }
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_BaseBoard'
                } {
                    return [PSCustomObject]@{
                        SKU = "  $testSystemSKU  "
                    }
                }

                $result = Get-HardwareData -Manufacturer 'Viglen' -Model $testModel

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 3
                $result.Manufacturer | Should -Be 'Viglen'
                $result.Model | Should -Be $testModel
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.ContainsKey('SerialNumber') | Should -Be $false
            }

            It 'should handle Viglen manufacturer with wildcard matching' {
                $testModel = 'Viglen Laptop'
                $testSystemSKU = 'VIGLEN-SKU-456'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = $testModel
                    }
                }
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_BaseBoard'
                } {
                    return [PSCustomObject]@{
                        SKU = $testSystemSKU
                    }
                }

                $result = Get-HardwareData -Manufacturer 'Viglen Limited' -Model $testModel

                $result.Manufacturer | Should -Be 'Viglen'
                $result.Model | Should -Be $testModel
                $result.SystemSKU | Should -Be $testSystemSKU
            }
        }

        Context 'Success - AZW Manufacturer' {
            It 'should return normalized AZW hardware data with Model and SystemSKU' {
                $testModel = 'AZW Mini PC'
                $testSystemSKU = 'AZW-SKU-789'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = "  $testModel  "
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\WMI'
                } {
                    return [PSCustomObject]@{
                        BaseBoardProduct = "  $testSystemSKU  "
                    }
                }

                $result = Get-HardwareData -Manufacturer 'AZW' -Model $testModel

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 3
                $result.Manufacturer | Should -Be 'AZW'
                $result.Model | Should -Be $testModel
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.ContainsKey('SerialNumber') | Should -Be $false
            }

            It 'should handle AZW manufacturer with wildcard matching' {
                $testModel = 'AZW Desktop'
                $testSystemSKU = 'AZW-SKU-012'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = $testModel
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\WMI'
                } {
                    return [PSCustomObject]@{
                        BaseBoardProduct = $testSystemSKU
                    }
                }

                $result = Get-HardwareData -Manufacturer 'AZW International' -Model $testModel

                $result.Manufacturer | Should -Be 'AZW'
                $result.Model | Should -Be $testModel
                $result.SystemSKU | Should -Be $testSystemSKU
            }
        }

        Context 'Success - Fujitsu Manufacturer' {
            It 'should return normalized Fujitsu hardware data with Model and SystemSKU' {
                $testModel = 'Fujitsu Lifebook'
                $testSystemSKU = 'FUJITSU-SKU-345'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = "  $testModel  "
                    }
                }
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_BaseBoard'
                } {
                    return [PSCustomObject]@{
                        SKU = "  $testSystemSKU  "
                    }
                }

                $result = Get-HardwareData -Manufacturer 'Fujitsu' -Model $testModel

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 3
                $result.Manufacturer | Should -Be 'Fujitsu'
                $result.Model | Should -Be $testModel
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.ContainsKey('SerialNumber') | Should -Be $false
            }

            It 'should handle Fujitsu manufacturer with wildcard matching' {
                $testModel = 'Fujitsu Desktop'
                $testSystemSKU = 'FUJITSU-SKU-678'
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Model = $testModel
                    }
                }
                Mock Get-WmiObject -ParameterFilter {
                    $Class -eq 'Win32_BaseBoard'
                } {
                    return [PSCustomObject]@{
                        SKU = $testSystemSKU
                    }
                }

                $result = Get-HardwareData -Manufacturer 'Fujitsu Technology Solutions' -Model $testModel

                $result.Manufacturer | Should -Be 'Fujitsu'
                $result.Model | Should -Be $testModel
                $result.SystemSKU | Should -Be $testSystemSKU
            }
        }

        Context 'Success - Unknown Manufacturer' {
            It 'should return empty hashtable for unknown manufacturer' {
                $result = Get-HardwareData -Manufacturer 'Unknown Manufacturer' -Model 'Unknown Model'

                $result | Should -BeOfType [System.Collections.Hashtable]
                $result.Count | Should -Be 0
            }
        }

        Context 'Success - Retrieving from System' {
            It 'should retrieve Manufacturer and Model from system when not provided' {
                $testManufacturer = 'Dell Inc.'
                $testModel = 'OptiPlex 7090'
                $testSystemSKU = '0ABC123'
                $testSerialNumber = 'SN123456789'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Manufacturer = "  $testManufacturer  "
                        Model = "  $testModel  "
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\wmi'
                } {
                    return [PSCustomObject]@{
                        SystemSKU = $testSystemSKU
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_SystemEnclosure'
                } {
                    return @([PSCustomObject]@{
                        SerialNumber = $testSerialNumber
                    })
                }

                $result = Get-HardwareData

                Should -Invoke Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1
                $result.Manufacturer | Should -Be 'Dell'
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.SerialNumber | Should -Be $testSerialNumber
            }

            It 'should retrieve Manufacturer from system when only Model is provided' {
                $testManufacturer = 'Microsoft Corporation'
                $testModel = 'Surface Pro 9'
                $testSystemSKU = 'SurfacePro9'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Manufacturer = $testManufacturer
                        Model = $testModel
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\wmi'
                } {
                    return [PSCustomObject]@{
                        SystemSKU = $testSystemSKU
                    }
                }

                $result = Get-HardwareData -Model $testModel

                Should -Invoke Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1
                $result.Manufacturer | Should -Be 'Microsoft'
            }

            It 'should retrieve Model from system when only Manufacturer is provided' {
                $testManufacturer = 'Dell Inc.'
                $testModel = 'OptiPlex 7090'
                $testSystemSKU = '0ABC123'
                $testSerialNumber = 'SN123456789'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Manufacturer = $testManufacturer
                        Model = $testModel
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\wmi'
                } {
                    return [PSCustomObject]@{
                        SystemSKU = $testSystemSKU
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_SystemEnclosure'
                } {
                    return @([PSCustomObject]@{
                        SerialNumber = $testSerialNumber
                    })
                }

                $result = Get-HardwareData -Manufacturer $testManufacturer

                Should -Invoke Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } -Exactly -Times 1
                $result.Manufacturer | Should -Be 'Dell'
            }
        }

        Context 'Success - Trimming Whitespace' {
            It 'should trim whitespace from Manufacturer and Model retrieved from system' {
                $testManufacturer = '  Dell Inc.  '
                $testModel = '  OptiPlex 7090  '
                $testSystemSKU = '0ABC123'
                $testSerialNumber = 'SN123456789'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Manufacturer = $testManufacturer
                        Model = $testModel
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\wmi'
                } {
                    return [PSCustomObject]@{
                        SystemSKU = "  $testSystemSKU  "
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_SystemEnclosure'
                } {
                    return @([PSCustomObject]@{
                        SerialNumber = "  $testSerialNumber  "
                    })
                }

                $result = Get-HardwareData

                $result.Manufacturer | Should -Be 'Dell'
                $result.SystemSKU | Should -Be $testSystemSKU
                $result.SerialNumber | Should -Be $testSerialNumber
            }
        }

        Context 'Error - Get-CimInstance Failures' {
            It 'should throw error when Get-CimInstance fails for Win32_ComputerSystem' {
                $errorMessage = 'Failed to retrieve computer system information'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } {
                    throw $errorMessage
                }

                { Get-HardwareData } | Should -Throw -ExpectedMessage 'Failed to retrieve hardware data: *'
            }

            It 'should throw error when Get-CimInstance fails for MS_SystemInformation' {
                $testManufacturer = 'Dell Inc.'
                $testModel = 'OptiPlex 7090'
                $errorMessage = 'Failed to retrieve system information'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Manufacturer = $testManufacturer
                        Model = $testModel
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\wmi'
                } {
                    throw $errorMessage
                }

                { Get-HardwareData } | Should -Throw -ExpectedMessage 'Failed to retrieve hardware data: *'
            }

            It 'should throw error when Get-CimInstance fails for Win32_SystemEnclosure' {
                $testManufacturer = 'Dell Inc.'
                $testModel = 'OptiPlex 7090'
                $testSystemSKU = '0ABC123'
                $errorMessage = 'Failed to retrieve system enclosure information'
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_ComputerSystem'
                } {
                    return [PSCustomObject]@{
                        Manufacturer = $testManufacturer
                        Model = $testModel
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'MS_SystemInformation' -and $Namespace -eq 'root\wmi'
                } {
                    return [PSCustomObject]@{
                        SystemSKU = $testSystemSKU
                    }
                }
                Mock Get-CimInstance -ParameterFilter {
                    $ClassName -eq 'Win32_SystemEnclosure'
                } {
                    throw $errorMessage
                }

                { Get-HardwareData } | Should -Throw -ExpectedMessage 'Failed to retrieve hardware data: *'
            }
        }
    }
}

