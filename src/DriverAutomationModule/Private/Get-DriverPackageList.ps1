function Get-DriverPackageList {
    <#
    .SYNOPSIS
    Retrieves driver package(s) from the Configuration Manager AdminService endpoint.

    .DESCRIPTION
    This function retrieves driver package(s) from the Configuration Manager AdminService endpoint using a REST API call.
    The function performs a GET request to the specified AdminService URI and returns an array of driver package objects.
    Authentication can be performed using either provided credentials or default Windows credentials.
    Default Windows credentials are used when credentials are not provided, which is the recommended approach for local testing scenarios.
    If no driver packages are found, the function throws an error and logs a warning message.

    .PARAMETER Uri
    The full URI of the AdminService endpoint, including the OData query string and filter parameters.
    This should be a complete URL pointing to the SMS_Package endpoint, typically constructed using Set-DriverPackageQuery.
    Example: 'https://cm01.contoso.com/AdminService/wmi/SMS_Package?$filter=startswith(Name,'Drivers -')&$select=Name,Description,Manufacturer,Version,SourceDate,PackageID,MIFName,MIFVersion'

    .PARAMETER AdminServiceUser
    The username to use for authentication with the AdminService endpoint. This parameter is optional.
    If both AdminServiceUser and AdminServicePass are provided, the function will use these credentials for authentication.
    If either parameter is omitted, the function will use default Windows credentials (UseDefaultCredentials), which is typically used for local testing scenarios.

    .PARAMETER AdminServicePass
    The password to use for authentication with the AdminService endpoint. This parameter is optional.
    If both AdminServiceUser and AdminServicePass are provided, the function will use these credentials for authentication.
    If either parameter is omitted, the function will use default Windows credentials (UseDefaultCredentials), which is typically used for local testing scenarios.

    .EXAMPLE
    $uri = Set-DriverPackageQuery -ServerFQDN "CM01.contoso.com" -Manufacturer "Dell" -SystemSKU "0A52" -TargetOS "Windows 11 x64"
    $driverPackages = Get-DriverPackageList -Uri $uri
    Retrieves driver packages using default Windows credentials (useful for local testing) for a Dell device with SystemSKU 0A52 running Windows 11 x64.

    .EXAMPLE
    $uri = Set-DriverPackageQuery -ServerFQDN "CM01.contoso.com" -TargetOS "Windows 10 x64"
    $driverPackages = Get-DriverPackageList -Uri $uri -AdminServiceUser "DOMAIN\ServiceAccount" -AdminServicePass "SecurePassword123"
    Retrieves driver packages for Windows 10 x64 using explicit credentials for authentication.

    .EXAMPLE
    $driverPackages = Get-DriverPackageList -Uri 'https://cm01.contoso.com/AdminService/wmi/SMS_Package?$filter=startswith(Name,''Drivers -'')&$select=Name,PackageID'
    Retrieves all driver packages using default Windows credentials (useful for local testing) with a custom query string.

    .INPUTS
    None
    This function does not accept pipeline input.

    .OUTPUTS
    System.Object[]
    Returns an array of driver package objects retrieved from the AdminService endpoint.
    Each object contains properties such as Name, Description, Manufacturer, Version, SourceDate, PackageID, MIFName, and MIFVersion (depending on the $select clause in the URI).
    If no packages are found, the function throws an error and does not return any output.

    .NOTES
    Part of the DriverAutomationModule module.
    The function uses Invoke-RestMethod to perform the REST API call to the AdminService endpoint.
    The response from the AdminService is expected to be in OData JSON format with a 'value' property containing the array of packages.
    If the response does not contain a 'value' property or the value array is empty, the function will throw an error.
    All authentication attempts and errors are logged using Write-LogEntry.
    Default Windows credentials are used when credentials are not provided, which is the recommended approach for local testing scenarios.

    .LINK
    https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the URI of the AdminService endpoint.")]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the username for AdminService authentication.")]
        [ValidateNotNullOrEmpty()]
        [string]$AdminServiceUser,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the password for AdminService authentication.")]
        [ValidateNotNullOrEmpty()]
        [string]$AdminServicePass
    )
    begin {
        $cmdletName = $MyInvocation.MyCommand.Name
    }

    process {
        try {
            $params = @{
                Uri         = $Uri
                Method      = 'Get'
                ErrorAction = 'Stop'
            }

            if ($AdminServiceUser -and $AdminServicePass) {
                Write-LogEntry -Message "Using provided credentials for AdminService authentication." -Source $cmdletName
                $secureString = ConvertTo-SecureString -String $AdminServicePass -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PSCredential ($AdminServiceUser, $secureString)
                $params.Credential = $credential
            }
            else {
                Write-LogEntry -Message "Using default credentials for AdminService authentication." -Source $cmdletName
                $params.UseDefaultCredentials = $true
            }

            $response = Invoke-RestMethod @params

            if ($null -eq $response.value -or $response.value.Count -eq 0) {
                Write-LogEntry -Message "No driver package(s) found on the AdminService endpoint." -Source $cmdletName -Severity 3
                throw "No driver package(s) found on the AdminService endpoint."
            }

            Write-Output @($response.value)
        }
        catch {
            Write-LogEntry -Message "Failed to retrieve driver package list: $_" -Source $cmdletName
            throw
        }
    }
}