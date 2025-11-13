function Invoke-DISM {
    <#
    .SYNOPSIS
        Invokes the DISM utility to apply drivers to the target system disk.

    .DESCRIPTION
        This function uses the DISM (Deployment Image Servicing and Management) utility to apply drivers from a specified path to the target system disk.

        The function executes DISM with the following parameters:
        - /Image: Specifies the target system disk (default: C:)
        - /Add-Driver: Instructs DISM to add drivers to the image
        - /Driver: Specifies the path to the driver package content
        - /Recurse: Recursively searches subdirectories for driver files (.inf files)

        If a log path is specified, DISM will write detailed operation logs to that location. If not specified, DISM will use its default logging behavior.

        The function uses Start-Process to execute DISM and waits for completion. On success, a log entry is written. On failure, an error is logged and thrown.

    .PARAMETER MountPath
        The full local path to the downloaded driver package content. This path should contain driver files (.inf files) that will be applied to the target system disk.
        The function will recursively search subdirectories for driver files.

    .PARAMETER OSDisk
        The target system disk where drivers will be applied. Default is "C:".
        This should be the drive letter of the system disk (e.g., "C:", "D:").

    .PARAMETER LogPath
        The full path for the DISM log file. If not specified, DISM will use its default logging behavior.
        Specifying a log path allows for detailed tracking of the driver installation process.

    .INPUTS
        None
        This function does not accept pipeline input.

    .OUTPUTS
        None
        This function does not return any output. Success or failure is indicated through log entries and exception handling.

    .EXAMPLE
        PS C:\> Invoke-DISM -MountPath "C:\Drivers" -OSDisk "C:"
        Applies drivers from C:\Drivers to the C: drive using default DISM logging.

    .EXAMPLE
        PS C:\> Invoke-DISM -MountPath "C:\Drivers" -OSDisk "C:" -LogPath "C:\Logs\DISM.log"
        Applies drivers from C:\Drivers to the C: drive and writes detailed logs to C:\Logs\DISM.log.

    .EXAMPLE
        PS C:\> Invoke-DISM -MountPath "D:\DriverPackages\Dell" -OSDisk "D:"
        Applies drivers from D:\DriverPackages\Dell to the D: drive.

    .NOTES
        Part of the DriverAutomationModule module.
        This function requires administrative privileges to modify the system disk.
        The DISM utility must be available in the system PATH.
        The function will recursively search subdirectories for driver files when using the /Recurse parameter.

    .LINK
        https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the full local path to the downloaded driver package content.")]
        [ValidateNotNullOrEmpty()]
        [string]$MountPath,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the target system disk. Default is C:")]
        [ValidateNotNullOrEmpty()]
        [string]$OSDisk = "C:",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the log file path.")]
        [ValidateNotNullOrEmpty()]
        [string]$LogPath
    )

    begin {
        $cmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    process {
        try {
            $dismArgs = @(
                "/Image:$OSDisk\"
                "/Add-Driver"
                "/Driver:$MountPath"
                "/Recurse"
            )

            if ($LogPath) {
                $dismArgs += "/LogPath:$LogPath"
            }

            $params = @{
                FilePath     = "dism.exe"
                ArgumentList = $dismArgs
                Wait         = $true
                NoNewWindow  = $true
                ErrorAction  = 'Stop'
            }
            Start-Process @params
            Write-LogEntry -Message "Applied drivers to the target system disk successfully." -Source $cmdletName
        }
        catch {
            $errorMessage = "Failed to apply drivers to the target system disk. Error: $_"
            Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
            throw $errorMessage
        }
    }
}