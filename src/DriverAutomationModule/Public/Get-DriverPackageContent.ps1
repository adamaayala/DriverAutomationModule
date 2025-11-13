function Get-DriverPackageContent {
    <#
    .SYNOPSIS
    Downloads the driver package content from Microsoft Endpoint Manager (SCCM) to a specified custom location.

    .DESCRIPTION
    This function downloads the driver package content from Microsoft Endpoint Manager (SCCM) to a specified custom location.
    The function retrieves the driver package information from Task Sequence variables (set by Find-DriverPackage) and uses
    the OSDDownloadContent utility to download the package content.

    The function performs the following steps:
    1. Retrieves the driver package query result from Task Sequence variables using Get-DriverPackageQueryResult
    2. Validates that the driver package query result exists and contains a PackageID
    3. Downloads the driver package content to the specified custom location using Invoke-OSDDownloadContent
    4. Sets the download location path in the Task Sequence variable "DriverPackagePath"

    This function requires that Find-DriverPackage has been executed previously to set the driver package information
    in Task Sequence variables. If the driver package query result is not found or does not contain a PackageID,
    the function will throw an error.

    The function uses the OSDDownloadContent utility which must be available in the system PATH (WinPE) or at
    $env:WINDIR\CCM\OSDDownloadContent.exe (full OS). The function requires a Task Sequence environment to be available.

    .PARAMETER CustomLocation
    The custom location path where the driver package content will be downloaded.
    This parameter is mandatory and must be a valid, non-empty string.
    The path will be created if it does not exist during the download process.
    Example: "C:\DriverPackageContent" or "D:\Downloads\Drivers\Dell"

    .EXAMPLE
    Get-DriverPackageContent -CustomLocation "C:\DriverPackageContent"
    Downloads the driver package content to C:\DriverPackageContent. The driver package information must have been
    previously set by Find-DriverPackage.

    .EXAMPLE
    Get-DriverPackageContent -CustomLocation "D:\Downloads\Drivers\Dell"
    Downloads the driver package content to D:\Downloads\Drivers\Dell. The download location path will be stored
    in the Task Sequence variable "DriverPackagePath".

    .INPUTS
    None
    This function does not accept pipeline input.

    .OUTPUTS
    None
    This function does not return any output. Success or failure is indicated through log entries and exception handling.
    The download location path is stored in the Task Sequence variable "DriverPackagePath".

    .NOTES
    Part of the DriverAutomationModule module.
    This function requires:
    - A Task Sequence environment to be initialized
    - Find-DriverPackage to have been executed previously to set driver package information in Task Sequence variables
    - The OSDDownloadContent utility to be available in the system PATH (WinPE) or at $env:WINDIR\CCM\OSDDownloadContent.exe (full OS)
    - The Get-DriverPackageQueryResult function to retrieve driver package information from Task Sequence variables
    - The Invoke-OSDDownloadContent function to perform the actual download

    The function uses Write-LogEntry for logging all operations and errors.
    If the driver package query result is not found or does not contain a PackageID, the function will throw an error.
    If the download process fails, the function will log the error and re-throw it with a descriptive message.

    .LINK
    https://github.com/adamaayala/OSDeploymentKit
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The custom location to download the driver package content to.")]
        [ValidateNotNullOrEmpty()]
        [string]$CustomLocation
    )

    begin {
        $cmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    process {
        try {
            # Get the driver package query result from the registry
            $driverPackageQueryResult = Get-DriverPackageQueryResult
            Write-LogEntry -Message "Driver package query result retrieved successfully." -Source $cmdletName -Severity 0

            if (-not $driverPackageQueryResult) {
                throw "Driver package query result not found"
            }

            # Download the driver package content
            $downloadParams = @{
                PackageID               = $driverPackageQueryResult.PackageID
                DestinationLocationType = "Custom"
                DestinationVariableName = "DriverPackagePath"
                CustomLocationPath      = $CustomLocation
            }
            Invoke-OSDDownloadContent @downloadParams
            Write-LogEntry -Message "Driver package content downloaded successfully." -Source $cmdletName -Severity 0
        }
        catch {
            $errorMessage = "Failed to download the driver package content: $_"
            Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
            throw $errorMessage
        }
    }
}