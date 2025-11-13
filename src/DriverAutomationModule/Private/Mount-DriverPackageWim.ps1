function Mount-DriverPackageWim {
    <#
    .SYNOPSIS
        Mounts the driver package content WIM file.

    .DESCRIPTION
        This function locates and mounts the driver package content WIM file from the specified package directory to the given mount path.

        The function performs the following operations:
        - Recursively searches the PackageDirectory for a file named "DriverPackage.wim"
        - Creates the MountPath directory if it does not exist
        - Mounts the WIM file using Mount-WindowsImage with Index 1
        - Logs the operation progress and results

        If the WIM file is not found in the specified directory (including subdirectories), the function will throw an error.
        If the mount operation fails, the function will log the error and throw an exception with details.

    .PARAMETER PackageDirectory
        The full local path to the downloaded driver package content. The function will recursively search this directory and all subdirectories for a file named "DriverPackage.wim".

    .PARAMETER MountPath
        The mount location for the driver package content. This path will be created automatically if it does not exist.
        The WIM file will be mounted to this location using Mount-WindowsImage with Index 1.

    .INPUTS
        None
        This function does not accept pipeline input.

    .OUTPUTS
        None
        This function does not return any output. Success or failure is indicated through log entries and exception handling.

    .EXAMPLE
        PS C:\> Mount-DriverPackageWim -PackageDirectory "C:\Temp\DriverPackage" -MountPath "C:\Temp\DriverPackageMount"
        Searches for DriverPackage.wim in C:\Temp\DriverPackage and mounts it to C:\Temp\DriverPackageMount.

    .EXAMPLE
        PS C:\> Mount-DriverPackageWim -PackageDirectory "D:\Downloads\Drivers\Dell" -MountPath "D:\Mount\DellDrivers"
        Searches for DriverPackage.wim in D:\Downloads\Drivers\Dell (including subdirectories) and mounts it to D:\Mount\DellDrivers.

    .EXAMPLE
        PS C:\> Mount-DriverPackageWim -PackageDirectory "C:\DriverPackages\HP" -MountPath "C:\MountedDrivers"
        Searches for DriverPackage.wim in C:\DriverPackages\HP and mounts it to C:\MountedDrivers. The mount path will be created if it does not exist.

    .NOTES
        Part of the DriverAutomationModule module.
        This function requires administrative privileges to mount WIM files.
        The function uses Mount-WindowsImage with Index 1 to mount the WIM file.
        The function will recursively search all subdirectories for the DriverPackage.wim file.
        If the MountPath does not exist, it will be created automatically.

    .LINK
        https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the full local path to the downloaded driver package content.")]
        [ValidateNotNullOrEmpty()]
        [string]$PackageDirectory,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the mount location for the driver package content.")]
        [ValidateNotNullOrEmpty()]
        [string]$MountPath
    )

    begin {
        $cmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    process {
        # Get the driver package content WIM file
        $driverPackage = Get-ChildItem -Path $PackageDirectory -Filter "DriverPackage.wim" -Recurse -ErrorAction SilentlyContinue
        Write-LogEntry -Message "Driver package content WIM file: $($driverPackage.FullName)" -Source $cmdletName -Severity 0

        if (-not $driverPackage) {
            throw "No driver package content found in the specified directory."
        }

        # Create the mount path if it doesn't exist
        if (-not (Test-Path -Path $MountPath)) {
            New-Item -Path $MountPath -ItemType Directory -Force | Out-Null
        }

        # Mount the driver package content WIM file
        try {
            Mount-WindowsImage -ImagePath $driverPackage.FullName -Path $MountPath -Index 1 -ErrorAction Stop
            Write-LogEntry -Message "Driver package content WIM file mounted successfully." -Source $cmdletName
        }
        catch {
            $errorMessage = "Failed to mount driver package content WIM file: $_"
            Write-LogEntry -Message $errorMessage -Source $MyInvocation.MyCommand.Name -Severity 3
            throw $errorMessage
        }
    }
}