function Dismount-DriverPackageWim {
    <#
    .SYNOPSIS
        Dismounts the driver package content WIM file from the specified mount path.

    .DESCRIPTION
        This function dismounts the driver package content WIM file from the specified mount path.
        The function uses the Dismount-WindowsImage function from the OSDeploymentKit module to perform the dismount operation.
        The -Discard parameter is used to discard any changes made to the mounted image, ensuring the WIM file remains unchanged.
        All operations are logged using Write-LogEntry for debugging and audit purposes.
        If the dismount operation fails, the function logs an error and throws an exception.

    .PARAMETER MountPath
        The mount location for the driver package content WIM file.
        This should be the same path that was used when mounting the WIM file.
        The path must exist and contain a mounted WIM image.
        This parameter is mandatory and must not be null or empty.

    .EXAMPLE
        PS C:\> Dismount-DriverPackageWim -MountPath "C:\Temp\DriverPackageMount"
        Dismounts the driver package content WIM file from the mount path "C:\Temp\DriverPackageMount" and discards any changes.

    .INPUTS
        None
        This function does not accept pipeline input.

    .OUTPUTS
        None
        This function does not return any output. It performs the dismount operation and logs the result.

    .NOTES
        Part of the DriverAutomationModule module.
        The function uses the Dismount-WindowsImage function from the OSDeploymentKit module to dismount the driver package content WIM file.
        The -Discard parameter ensures that any modifications made to the mounted image are not saved back to the WIM file.
        This function should be called after completing operations on the mounted driver package content.
        All operations are logged using Write-LogEntry for debugging and audit purposes.

    .LINK
        https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the mount location for the driver package content.")]
        [ValidateNotNullOrEmpty()]
        [string]$MountPath
    )

    begin {
        $cmdletName = $MyInvocation.MyCommand.Name
    }

    process {
        try {
            Dismount-WindowsImage -Path $MountPath -Discard -ErrorAction Stop
            Write-LogEntry -Message "Driver package content WIM file dismounted successfully." -Source $cmdletName
        }
        catch {
            $errorMessage = "Failed to dismount driver package content WIM file: $_"
            Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
            throw $errorMessage
        }
    }
}