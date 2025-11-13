function Find-DriverPackage {
    <#
    .SYNOPSIS
    Finds the appropriate driver package for the computer by querying the Configuration Manager AdminService.

    .DESCRIPTION
    This function finds the appropriate driver package for the computer by gathering hardware data, querying the Configuration Manager AdminService for matching driver packages, and setting the DriverPackageQueryResult in Task Sequence variables.

    The function performs the following steps:
    1. Retrieves hardware data using Get-HardwareData (either from provided parameters or automatically from the system)
    2. Validates that required hardware information (Manufacturer and SystemSKU) is available
    3. Constructs an OData query URL using Set-DriverPackageQuery
    4. Retrieves driver packages from the AdminService using Get-DriverPackageList
    5. Confirms and selects the latest driver package using Confirm-DriverPackageList (if multiple packages are found)
    6. Sets the driver package information to Task Sequence variables using Set-DriverPackageQueryResult
    7. Returns the confirmed driver package object

    If Manufacturer or Model parameters are not provided, the function will automatically retrieve them from the system using WMI queries.
    Authentication with the AdminService can be performed using either provided credentials or default Windows credentials.
    If both AdminServiceUser and AdminServicePass are provided, explicit credentials will be used. If both are omitted, default Windows credentials will be used.
    The function validates that both credential parameters are provided together or both are omitted - providing only one will result in an error.

    If the hardware manufacturer is not supported or required hardware information cannot be retrieved, the function will throw an error.
    If no driver packages are found or confirmed, the function will throw an error.

    .PARAMETER Manufacturer
    The manufacturer of the computer. This parameter is optional.
    If not provided, the function will automatically retrieve the manufacturer from the Win32_ComputerSystem WMI class.
    If provided, this value will be passed to Get-HardwareData for hardware data retrieval.
    The manufacturer name will be normalized by Get-HardwareData (e.g., "Dell Inc." becomes "Dell").

    .PARAMETER Model
    The model of the computer. This parameter is optional.
    If not provided, the function will automatically retrieve the model from the Win32_ComputerSystem WMI class.
    If provided, this value will be passed to Get-HardwareData for hardware data retrieval.

    .PARAMETER TargetOS
    The target Operating System for the driver package. This parameter is optional.
    Valid values are "Windows 10 x64" and "Windows 11 x64".
    If provided, the query will filter driver packages that contain the TargetOS in the package name.
    If not provided, driver packages for all supported operating systems may be returned.

    .PARAMETER ServerFQDN
    The fully qualified domain name (FQDN) of the Configuration Manager server hosting the AdminService.
    This parameter is mandatory.
    Example: "cm01.contoso.com" or "adminservice.contoso.com"

    .PARAMETER AdminServiceUser
    The username to use for authentication with the AdminService endpoint. This parameter is optional.
    If both AdminServiceUser and AdminServicePass are provided, the function will use these credentials for authentication.
    If either parameter is omitted or empty, the function will use default Windows credentials (UseDefaultCredentials).
    AdminServiceUser and AdminServicePass must be provided together - providing only one will result in an error.

    .PARAMETER AdminServicePass
    The password to use for authentication with the AdminService endpoint. This parameter is optional.
    If both AdminServiceUser and AdminServicePass are provided, the function will use these credentials for authentication.
    If either parameter is omitted or empty, the function will use default Windows credentials (UseDefaultCredentials).
    AdminServiceUser and AdminServicePass must be provided together - providing only one will result in an error.

    .EXAMPLE
    Find-DriverPackage -Manufacturer "Dell" -Model "Latitude 7480" -TargetOS "Windows 10 x64" -ServerFQDN "cm01.contoso.com" -AdminServiceUser "DOMAIN\ServiceAccount" -AdminServicePass "SecurePassword123"
    Finds a driver package for a Dell Latitude 7480 running Windows 10 x64 using explicit credentials for AdminService authentication.

    .EXAMPLE
    Find-DriverPackage -ServerFQDN "cm01.contoso.com"
    Finds a driver package using only the required ServerFQDN parameter. The function will automatically retrieve Manufacturer and Model from the system, and use default Windows credentials for authentication.

    .EXAMPLE
    Find-DriverPackage -TargetOS "Windows 11 x64" -ServerFQDN "cm01.contoso.com"
    Finds a driver package for Windows 11 x64. The function will automatically retrieve Manufacturer and Model from the system, and use default Windows credentials for authentication.

    .EXAMPLE
    Find-DriverPackage -Manufacturer "Dell" -Model "OptiPlex 7090" -ServerFQDN "cm01.contoso.com"
    Finds a driver package for a Dell OptiPlex 7090 without specifying TargetOS. The function will use default Windows credentials for authentication.

    .INPUTS
    None
    This function does not accept pipeline input.

    .OUTPUTS
    System.Object
    Returns a driver package object containing the following properties:
    - Description: The description of the driver package
    - Manufacturer: The manufacturer of the driver package
    - Name: The name of the driver package
    - PackageID: The unique package identifier
    - Version: The version of the driver package
    - SourceDate: The source date of the driver package (ISO 8601 format)
    - MIFName: The MIF name (if available)
    - MIFVersion: The MIF version (if available)

    If multiple driver packages are found, the function returns the one with the most recent SourceDate.
    The driver package information is also set to Task Sequence variables with the prefix "XDriver" (e.g., XDriverPackageID, XDriverName, etc.).

    .NOTES
    Part of the DriverAutomationModule module.
    The function relies on several other module functions:
    - Get-HardwareData: Retrieves and normalizes hardware information
    - Set-DriverPackageQuery: Constructs the OData query URL
    - Get-DriverPackageList: Retrieves driver packages from the AdminService
    - Confirm-DriverPackageList: Confirms and selects the latest package if multiple are found
    - Set-DriverPackageQueryResult: Sets the package information to Task Sequence variables

    The function validates hardware data to ensure Manufacturer and SystemSKU are present before proceeding with the query.
    If the hardware manufacturer is not supported by Get-HardwareData, an empty hashtable will be returned and the function will throw an error.
    All operations are logged using Write-LogEntry for debugging and audit purposes.
    Errors are logged with severity level 3 (Error) and then re-thrown to allow calling code to handle them appropriately.

    .LINK
    https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "The manufacturer of the computer.")]
        [string]$Manufacturer,

        [Parameter(Mandatory = $false, HelpMessage = "The model of the computer.")]
        [string]$Model,

        [Parameter(Mandatory = $false, HelpMessage = "The target Operating System.")]
        [ValidateSet("Windows 10 x64", "Windows 11 x64")]
        [string]$TargetOS,

        [Parameter(Mandatory = $true, HelpMessage = "The FQDN of the AdminService.")]
        [ValidateNotNullOrEmpty()]
        [string]$ServerFQDN,

        [Parameter(Mandatory = $false, HelpMessage = "The username for the AdminService.")]
        [string]$AdminServiceUser,

        [Parameter(Mandatory = $false, HelpMessage = "The password for the AdminService.")]
        [string]$AdminServicePass
    )

    begin {
        $cmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    process {
        try {
            # Validate credential parameters - both must be provided together or neither
            $hasUser = $PSBoundParameters.ContainsKey('AdminServiceUser') -and -not [string]::IsNullOrWhiteSpace($AdminServiceUser)
            $hasPass = $PSBoundParameters.ContainsKey('AdminServicePass') -and -not [string]::IsNullOrWhiteSpace($AdminServicePass)

            if ($hasUser -xor $hasPass) {
                throw "AdminServiceUser and AdminServicePass must be provided together, or both omitted to use default credentials."
            }

            # Build hardware data parameters
            $hardwareDataParams = @{}
            if ($PSBoundParameters.ContainsKey('Manufacturer') -and -not [string]::IsNullOrWhiteSpace($Manufacturer)) {
                $hardwareDataParams['Manufacturer'] = $Manufacturer
            }
            if ($PSBoundParameters.ContainsKey('Model') -and -not [string]::IsNullOrWhiteSpace($Model)) {
                $hardwareDataParams['Model'] = $Model
            }

            $hardwareData = Get-HardwareData @hardwareDataParams

            # Validate hardware data contains required properties
            if (-not $hardwareData -or $hardwareData.Count -eq 0) {
                throw "Hardware data could not be retrieved. The manufacturer may not be supported."
            }

            if (-not $hardwareData.ContainsKey('Manufacturer') -or [string]::IsNullOrWhiteSpace($hardwareData.Manufacturer)) {
                throw "Manufacturer information is missing from hardware data."
            }

            if (-not $hardwareData.ContainsKey('SystemSKU') -or [string]::IsNullOrWhiteSpace($hardwareData.SystemSKU)) {
                throw "SystemSKU information is missing from hardware data."
            }

            Write-LogEntry -Message "Hardware data retrieved successfully." -Source $cmdletName -Severity 0
            $logMessage = "Manufacturer: $($hardwareData.Manufacturer), SystemSKU: $($hardwareData.SystemSKU)"
            if ($hardwareData.ContainsKey('Model')) {
                $logMessage += ", Model: $($hardwareData.Model)"
            }
            if ($hardwareData.ContainsKey('SerialNumber')) {
                $logMessage += ", SerialNumber: $($hardwareData.SerialNumber)"
            }
            Write-LogEntry -Message $logMessage -Source $cmdletName -Severity 0

            # Build the query parameters
            $queryParams = @{
                ServerFQDN   = $ServerFQDN
                Manufacturer = $hardwareData.Manufacturer
                SystemSKU    = $hardwareData.SystemSKU
            }

            if ($PSBoundParameters.ContainsKey('TargetOS') -and -not [string]::IsNullOrWhiteSpace($TargetOS)) {
                $queryParams['TargetOS'] = $TargetOS
            }

            $uri = Set-DriverPackageQuery @queryParams
            Write-LogEntry -Message "Driver package query set successfully." -Source $cmdletName -Severity 0

            # Get the driver package list
            $params = @{ Uri = $uri }
            if ($hasUser -and $hasPass) {
                $params['AdminServiceUser'] = $AdminServiceUser
                $params['AdminServicePass'] = $AdminServicePass
            }

            $driverPackage = Get-DriverPackageList @params | Confirm-DriverPackageList

            if ($null -eq $driverPackage) {
                throw "No driver package was found or confirmed."
            }

            Write-LogEntry -Message "Driver package found and confirmed successfully. PackageID: $($driverPackage.PackageID)" -Source $cmdletName -Severity 0

            # Set the driver package query result
            $driverPackage | Set-DriverPackageQueryResult
            Write-Output $driverPackage
        }
        catch {
            $errorMessage = "An error occurred while finding the driver package: $_"
            Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
            throw
        }
    }
}