function Get-HardwareData {
    <#
    .SYNOPSIS
        Gets the normalized hardware information of the computer.

    .DESCRIPTION
        This function retrieves and normalizes hardware information from the computer system, particularly standardizing manufacturer names and retrieving system-specific identifiers such as SystemSKU and SerialNumber.

        The function supports the following manufacturers:
        - Dell: Returns normalized manufacturer name "Dell", SystemSKU (from MS_SystemInformation), and SerialNumber (from Win32_SystemEnclosure)
        - ClearTouch (including variants: "Clear Touch Interactive", "ClearTouch Interactive", "ClearTouch", "MAINBRD"): Returns normalized manufacturer name "ClearTouch", and uses the Model parameter as both SystemSKU and SerialNumber
        - Alienware: Returns normalized manufacturer name "Alienware", SystemSKU (from MS_SystemInformation), and SerialNumber (from Win32_SystemEnclosure)
        - Microsoft: Returns normalized manufacturer name "Microsoft" and SystemSKU (from MS_SystemInformation, no SerialNumber)
        - HP/Hewlett-Packard: Returns normalized manufacturer name "Hewlett-Packard", Model (from Win32_ComputerSystem), and SystemSKU (from MS_SystemInformation BaseBoardProduct)
        - Lenovo: Returns normalized manufacturer name "Lenovo", Model (from Win32_ComputerSystemProduct Version), and SystemSKU (first 4 characters of Win32_ComputerSystem Model)
        - Panasonic: Returns normalized manufacturer name "Panasonic Corporation", Model (from Win32_ComputerSystem), and SystemSKU (from MS_SystemInformation BaseBoardProduct)
        - Viglen: Returns normalized manufacturer name "Viglen", Model (from Win32_ComputerSystem), and SystemSKU (from Win32_BaseBoard SKU)
        - AZW: Returns normalized manufacturer name "AZW", Model (from Win32_ComputerSystem), and SystemSKU (from MS_SystemInformation BaseBoardProduct)
        - Fujitsu: Returns normalized manufacturer name "Fujitsu", Model (from Win32_ComputerSystem), and SystemSKU (from Win32_BaseBoard SKU)

        For unsupported manufacturers, an empty hashtable is returned.

        If Manufacturer or Model parameters are not provided, the function will automatically retrieve them from the Win32_ComputerSystem WMI class.
        All retrieved values are trimmed of leading and trailing whitespace.

    .PARAMETER Manufacturer
        The manufacturer of the computer. If not provided, it will be retrieved from the Win32_ComputerSystem WMI class.
        The value will be trimmed of leading and trailing whitespace.

    .PARAMETER Model
        The model of the computer. If not provided, it will be retrieved from the Win32_ComputerSystem WMI class.
        The value will be trimmed of leading and trailing whitespace.

    .INPUTS
        None
        This function does not accept pipeline input.

    .OUTPUTS
        [System.Collections.Hashtable]
        Returns a hashtable containing normalized hardware information. The hashtable may contain the following keys:
        - Manufacturer: The normalized manufacturer name (e.g., "Dell", "ClearTouch", "Alienware", "Microsoft", "Hewlett-Packard", "Lenovo", "Panasonic Corporation", "Viglen", "AZW", "Fujitsu")
        - Model: The system model (included for HP, Lenovo, Panasonic, Viglen, AZW, and Fujitsu)
        - SystemSKU: The system SKU identifier (retrieved from various WMI classes depending on manufacturer)
        - SerialNumber: The system serial number (retrieved from Win32_SystemEnclosure WMI class for Dell and Alienware; uses Model parameter for ClearTouch; not included for Microsoft, HP, Lenovo, Panasonic, Viglen, AZW, or Fujitsu)

        For unsupported manufacturers, an empty hashtable is returned.

    .EXAMPLE
        PS C:\> Get-HardwareData
        Retrieves hardware information from the system automatically and returns normalized hardware data.

    .EXAMPLE
        PS C:\> Get-HardwareData -Manufacturer "Dell Inc." -Model "OptiPlex 7090"
        Returns normalized Dell hardware data with SystemSKU and SerialNumber.

    .EXAMPLE
        PS C:\> Get-HardwareData -Manufacturer "Clear Touch Interactive" -Model "CT-12345"
        Returns normalized ClearTouch hardware data where the Model is used as both SystemSKU and SerialNumber.

    .EXAMPLE
        PS C:\> Get-HardwareData -Manufacturer "Microsoft Corporation" -Model "Surface Pro 9"
        Returns normalized Microsoft hardware data with SystemSKU only.

    .EXAMPLE
        PS C:\> Get-HardwareData -Manufacturer "Hewlett-Packard" -Model "EliteBook 850 G8"
        Returns normalized HP hardware data with Model and SystemSKU.

    .EXAMPLE
        PS C:\> Get-HardwareData -Manufacturer "Lenovo" -Model "ThinkPad X1 Carbon"
        Returns normalized Lenovo hardware data with Model and SystemSKU.

    .NOTES
        Part of the DriverAutomationModule module.
        The function uses wildcard matching for manufacturer names, allowing for variations in manufacturer naming.
        Supported wildcard patterns include: "*Dell*", "*Alienware*", "*Microsoft*", "*HP*", "*Hewlett-Packard*", "*Lenovo*", "*Panasonic*", "*Viglen*", "*AZW*", "*Fujitsu*"
        ClearTouch uses exact matching for specific variants: "Clear Touch Interactive", "ClearTouch Interactive", "ClearTouch", "MAINBRD"
        All retrieved values are trimmed of leading and trailing whitespace.

    .LINK
        https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "The manufacturer of the computer.")]
        [ValidateNotNullOrEmpty()]
        [string]$Manufacturer,

        [Parameter(Mandatory = $false, HelpMessage = "The model of the computer.")]
        [ValidateNotNullOrEmpty()]
        [string]$Model
    )

    try {
        if (-not $Manufacturer -or -not $Model) {
            $computerSystem = Get-CimInstance -ClassName "Win32_ComputerSystem"
            $Manufacturer = $computerSystem.Manufacturer.Trim()
            $Model = $computerSystem.Model.Trim()
        }

        $hardware = @{}

        switch -Wildcard ($Manufacturer) {
            "*Dell*" {
                $hardware.Add("Manufacturer", "Dell")
                $hardware.Add("SystemSKU", (Get-CimInstance -ClassName "MS_SystemInformation" -Namespace "root\wmi").SystemSKU.Trim())
                $hardware.Add("SerialNumber", (Get-CimInstance -ClassName 'Win32_SystemEnclosure' | Select-Object -ExpandProperty SerialNumber).Trim())
                break
            }
            { @("Clear Touch Interactive", "ClearTouch Interactive", "ClearTouch", "MAINBRD") -contains $_ } {
                $hardware.Add("Manufacturer", "ClearTouch")
                $hardware.Add("SystemSKU", $Model)
                $hardware.Add("SerialNumber", $Model)
                break
            }
            "*Alienware*" {
                $hardware.Add("Manufacturer", "Alienware")
                $hardware.Add("SystemSKU", (Get-CimInstance -ClassName "MS_SystemInformation" -Namespace "root\wmi").SystemSKU.Trim())
                $hardware.Add("SerialNumber", (Get-CimInstance -ClassName 'Win32_SystemEnclosure' | Select-Object -ExpandProperty SerialNumber).Trim())
                break
            }
            "*Microsoft*" {
                $hardware.Add("Manufacturer", "Microsoft")
                $hardware.Add("SystemSKU", (Get-CimInstance -ClassName "MS_SystemInformation" -Namespace "root\wmi").SystemSKU.Trim())
                break
            }
            "*HP*" {
                $hardware.Add("Manufacturer", "Hewlett-Packard")
                $hardware.Add("Model", (Get-WmiObject -Class "Win32_ComputerSystem" | Select-Object -ExpandProperty Model).Trim())
                $hardware.Add("SystemSKU", (Get-CimInstance -ClassName "MS_SystemInformation" -Namespace "root\WMI").BaseBoardProduct.Trim())
                break
            }
            "*Hewlett-Packard*" {
                $hardware.Add("Manufacturer", "Hewlett-Packard")
                $hardware.Add("Model", (Get-WmiObject -Class "Win32_ComputerSystem" | Select-Object -ExpandProperty Model).Trim())
                $hardware.Add("SystemSKU", (Get-CimInstance -ClassName "MS_SystemInformation" -Namespace "root\WMI").BaseBoardProduct.Trim())
                break
            }
            "*Lenovo*" {
                $hardware.Add("Manufacturer", "Lenovo")
                $hardware.Add("Model", (Get-WmiObject -Class "Win32_ComputerSystemProduct" | Select-Object -ExpandProperty Version).Trim())
                $hardware.Add("SystemSKU", ((Get-WmiObject -Class "Win32_ComputerSystem" | Select-Object -ExpandProperty Model).SubString(0, 4)).Trim())
                break
            }
            "*Panasonic*" {
                $hardware.Add("Manufacturer", "Panasonic Corporation")
                $hardware.Add("Model", (Get-WmiObject -Class "Win32_ComputerSystem" | Select-Object -ExpandProperty Model).Trim())
                $hardware.Add("SystemSKU", (Get-CimInstance -ClassName "MS_SystemInformation" -Namespace "root\WMI").BaseBoardProduct.Trim())
                break
            }
            "*Viglen*" {
                $hardware.Add("Manufacturer", "Viglen")
                $hardware.Add("Model", (Get-WmiObject -Class "Win32_ComputerSystem" | Select-Object -ExpandProperty Model).Trim())
                $hardware.Add("SystemSKU", (Get-WmiObject -Class "Win32_BaseBoard" | Select-Object -ExpandProperty SKU).Trim())
                break
            }
            "*AZW*" {
                $hardware.Add("Manufacturer", "AZW")
                $hardware.Add("Model", (Get-WmiObject -Class "Win32_ComputerSystem" | Select-Object -ExpandProperty Model).Trim())
                $hardware.Add("SystemSKU", (Get-CimInstance -ClassName "MS_SystemInformation" -Namespace "root\WMI").BaseBoardProduct.Trim())
                break
            }
            "*Fujitsu*" {
                $hardware.Add("Manufacturer", "Fujitsu")
                $hardware.Add("Model", (Get-WmiObject -Class "Win32_ComputerSystem" | Select-Object -ExpandProperty Model).Trim())
                $hardware.Add("SystemSKU", (Get-WmiObject -Class "Win32_BaseBoard" | Select-Object -ExpandProperty SKU).Trim())
                break
            }
        }

        return $hardware
    }
    catch {
        throw "Failed to retrieve hardware data: $_"
    }
}
