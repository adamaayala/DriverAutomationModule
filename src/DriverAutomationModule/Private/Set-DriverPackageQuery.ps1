function Set-DriverPackageQuery {
    <#
    .SYNOPSIS
    Builds an OData query URL for the Configuration Manager AdminService to retrieve driver packages.

    .DESCRIPTION
    This function constructs an OData query URL string for the Configuration Manager AdminService to retrieve driver packages.
    The query filters driver packages based on the provided parameters: SystemSKU, Manufacturer, and TargetOS.
    The function builds a URL-encoded query string that filters packages by name (starting with 'Drivers -') and optionally filters by SystemSKU in the description, Manufacturer in the name, and TargetOS in the name.
    The query selects specific properties: Name, Description, Manufacturer, Version, SourceDate, PackageID, MIFName, and MIFVersion.

    .PARAMETER ServerFQDN
    The internal fully qualified domain name of the server hosting the AdminService, e.g. CM01.domain.local.

    .PARAMETER Manufacturer
    The manufacturer of the device, if available. This parameter is optional. If provided, the query will filter packages that contain the manufacturer name in the package name.

    .PARAMETER SystemSKU
    The SKU of the device, if available. This parameter is optional. If provided, the query will filter packages that contain the SystemSKU in the package description.

    .PARAMETER TargetOS
    The target operating system. Valid values are 'Windows 10 x64' and 'Windows 11 x64'. This parameter is optional. If provided, the query will filter packages that contain the TargetOS in the package name.

    .EXAMPLE
    $url = Set-DriverPackageQuery -ServerFQDN "CM01.domain.local" -Manufacturer "Dell" -SystemSKU "0A52" -TargetOS "Windows 11 x64"
    Constructs a query URL for Dell driver packages with SystemSKU 0A52 for Windows 11 x64.

    .EXAMPLE
    $url = Set-DriverPackageQuery -ServerFQDN "CM01.domain.local" -TargetOS "Windows 10 x64"
    Constructs a query URL for all driver packages for Windows 10 x64 without filtering by manufacturer or SystemSKU.

    .INPUTS
    None
    This function does not accept pipeline input.

    .OUTPUTS
    System.String
    Returns a URL-encoded OData query string that can be used with the Configuration Manager AdminService to retrieve driver packages.

    .NOTES
    Part of the DriverAutomationModule module.
    The function constructs an OData query using $filter and $select parameters. The base filter always includes packages that start with 'Drivers -' in the name.
    Additional filters are appended based on the optional parameters provided. The final URL is URI-encoded to ensure proper formatting.

    .LINK
    https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the internal FQDN of the AdminService server.")]
        [ValidateNotNullOrEmpty()]
        [string]$ServerFQDN,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the device manufacturer.")]
        [ValidateNotNullOrEmpty()]
        [string]$Manufacturer,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the device SKU.")]
        [ValidateNotNullOrEmpty()]
        [string]$SystemSKU,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the target OS.")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Windows 10 x64", "Windows 11 x64")]
        [string]$TargetOS
    )
    begin {
        $cmdletName = $MyInvocation.MyCommand.Name
    }

    process {
        # Set the base URL for the AdminService query
        $baseURL = "https://$ServerFQDN/AdminService/wmi/SMS_Package?"

        # Select the desired properties to retrieve
        $select = "`$select=Name,Description,Manufacturer,Version,SourceDate,PackageID,MIFName,MIFVersion"

        # Set the base filter for the query
        $filter = "`$filter=startswith(Name,'Drivers -')"

        # Add the SystemSKU filter if provided
        if ($SystemSKU) {
            $filter += " and contains(Description,'$SystemSKU')"
        }

        # Add the Manufacturer filter if provided
        if ($Manufacturer) {
            $filter += " and contains(Name,'$Manufacturer')"
        }

        # Add the TargetOS filter if provided
        if ($TargetOS) {
            $filter += " and contains(Name,'$TargetOS')"
        }

        # Construct the final URL string
        $urlString = [uri]::EscapeUriString("$baseURL$filter&$select")

        Write-LogEntry -Message "Driver package query: $urlString" -Severity 1 -Source $cmdletName

        return $urlString

    }
}
