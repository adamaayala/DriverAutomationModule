#region Function Install-DriverPackage
function Install-DriverPackage {
    <#
    .SYNOPSIS
    Installs a driver package on the target system.
    .DESCRIPTION
    This function mounts a driver package WIM file, applies the drivers to the target system using DISM, and then dismounts the WIM file.
    .PARAMETER None
    This function does not accept any parameters.
    .EXAMPLE
    Install-DriverPackage
    .INPUTS
    None
    .OUTPUTS
    None
    .NOTES
    Part of the DriverAutomationModule module.
    .LINK
    https://github.com/adamaayala/OSDeploymentKit
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the driver package content.")]
        [ValidateNotNullOrEmpty()]
        [string]$DriverPackagePath,

        [Parameter(Mandatory = $true, HelpMessage = "The target system drive.")]
        [ValidateNotNullOrEmpty()]
        [string]$OSDisk,

        [Parameter(Mandatory = $true, HelpMessage = "The mount path.")]
        [ValidateNotNullOrEmpty()]
        [string]$MountPath
    )

    begin {
        $cmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    process {
        try {
            # Mount the driver package WIM file
            $mountParams = @{
                PackageDirectory = $driverPackagePath
                MountPath        = $mountPath
            }
            Mount-DriverPackageWim @mountParams

            # Apply the drivers to the target system using DISM
            $dismParams = @{
                MountPath = $mountPath
                OSDisk    = $osDisk
            }
            Invoke-DISM @dismParams

            # Dismount the driver package WIM file
            Dismount-DriverPackageWim -MountPath $mountPath
        }
        catch {
            $errorMessage = "Failed to install the driver package: $_"
            Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
            throw $errorMessage
        }
    }
}
#endregion Function Install-DriverPackage