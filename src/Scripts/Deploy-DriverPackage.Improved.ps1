<#
.SYNOPSIS
Deploys a driver package to a target system by searching, downloading, and installing the appropriate driver package.

.DESCRIPTION
This script deploys a driver package to a target system as part of an OSD Task Sequence. It orchestrates the complete driver package deployment process by executing three distinct phases: Find, Download, and Install.

The script performs the following operations:
1. Imports the DriverAutomationModule from the specified working directory
2. Executes the specified phase(s) of driver package deployment:
    - Find: Searches for the appropriate driver package by querying the Configuration Manager AdminService
    - Download: Downloads the driver package content from the AdminService to a custom location
    - Install: Mounts the driver package WIM file and installs drivers to the target system using DISM
3. Validates Task Sequence variables and prerequisites before executing each phase
4. Provides comprehensive error handling and logging throughout the deployment process

If no Phase parameter is specified, the script executes all phases sequentially (Find, Download, Install).

The script requires a Task Sequence environment to be available and relies on several Task Sequence variables:
- _SMSTSMDataPath: The Task Sequence data path
- OSDWindowsVersion: The target Windows version (for Find phase)
- AdminServiceFQDN: The FQDN of the AdminService server (for Find phase)
- AdminServiceUser: Optional username for AdminService authentication (for Find phase)
- AdminServicePass: Optional password for AdminService authentication (for Find phase)
- DriverPackagePath01: The path to the downloaded driver package (for Install phase)
- OSDTargetSystemDrive: The target system drive letter (for Install phase)

The script uses the DriverAutomationModule functions:
- Find-DriverPackage: Searches for driver packages
- Get-DriverPackageContent: Downloads driver package content
- Install-DriverPackage: Installs drivers to the target system
- Write-LogEntry: Logs all operations

.PARAMETER Phase
The phase of the driver package deployment to execute. This parameter is optional.

Valid values are:
- Find: Executes only the Find phase to search for a driver package
- Download: Executes only the Download phase to download the driver package content
- Install: Executes only the Install phase to install the driver package

If not specified, the script runs all phases sequentially (Find, Download, Install).

The Download phase requires that the Find phase has completed successfully and stored the driver package query result in Task Sequence variables.
The Install phase requires that the Download phase has completed successfully and the driver package content is available.

.PARAMETER WorkingDirectory
The working directory path where the DriverAutomationModule module is located. This parameter is optional.

If not specified, the script defaults to the directory where the script file is located ($PSScriptRoot).

The script expects to find the DriverAutomationModule.psd1 manifest file in this directory.
The path will be validated to ensure it exists and is accessible before attempting to import the module.

.PARAMETER WhatIf
Shows what would happen if the script runs without actually executing the operations. This parameter is optional.

When specified, the script displays what operations would be performed for each phase without actually executing them.
This is useful for testing and validating the script configuration before running it in a production environment.

.INPUTS
None
This script does not accept pipeline input.

.OUTPUTS
None
This script does not return any output. Success or failure is indicated through log entries and exception handling.

All operations are logged using Write-LogEntry, which writes to both the console and the Configuration Manager log file.

.EXAMPLE
.\Deploy-DriverPackage.Improved.ps1 -Phase Find
Searches for a driver package for the target OS and stores the result in Task Sequence variables.
The script retrieves hardware information from the system, queries the AdminService for matching driver packages,
and stores the selected driver package information for use in subsequent phases.

.EXAMPLE
.\Deploy-DriverPackage.Improved.ps1 -Phase Download
Downloads the driver package from the AdminService to the custom location specified in the Task Sequence data path.
This phase requires that the Find phase has completed successfully and the driver package query result is available.

.EXAMPLE
.\Deploy-DriverPackage.Improved.ps1 -Phase Install
Installs the driver package from the downloaded location to the target system.
The script mounts the driver package WIM file, applies drivers using DISM, and then dismounts the WIM file.
This phase requires that the Download phase has completed successfully.

.EXAMPLE
.\Deploy-DriverPackage.Improved.ps1
Runs all phases of the driver package deployment sequentially: Find, Download, and Install.
The script executes each phase in order and stops if any phase fails with an error.

.EXAMPLE
.\Deploy-DriverPackage.Improved.ps1 -WhatIf
Shows what operations would be performed for each phase without actually executing them.
Useful for testing and validating the script configuration before running in a production environment.

.EXAMPLE
.\Deploy-DriverPackage.Improved.ps1 -WorkingDirectory "C:\Modules\DriverAutomationModule" -Phase Find
Specifies a custom working directory where the DriverAutomationModule is located and executes only the Find phase.

.NOTES
Part of the DriverAutomationModule module.

This script is intended to be run as part of an OSD Task Sequence during Windows deployment.
The script requires:
- A Task Sequence environment to be initialized
- The DriverAutomationModule to be available in the working directory
- Appropriate Task Sequence variables to be set
- Administrative privileges for mounting WIM files and installing drivers
- Network connectivity to the Configuration Manager AdminService (for Find and Download phases)

The script uses comprehensive error handling and will stop execution if any phase fails.
All operations are logged using Write-LogEntry for debugging and audit purposes.

The script validates prerequisites before executing each phase to provide clear error messages if required conditions are not met.

.LINK
https://github.com/adamaayala/DriverAutomationModule
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Find', 'Download', 'Install')]
    [string]$Phase,

    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if (-not (Test-Path -Path $_ -PathType Container)) {
            throw "Working directory does not exist: $_"
        }
        $true
    })]
    [string]$WorkingDirectory = $PSScriptRoot
)

#region Initialize Variables
$cmdletName = $MyInvocation.MyCommand.Name
$ErrorActionPreference = 'Stop'

# Validate and resolve working directory path
$WorkingDirectory = [System.IO.Path]::GetFullPath($WorkingDirectory)
if (-not (Test-Path -Path $WorkingDirectory -PathType Container)) {
    throw "Working directory does not exist: $WorkingDirectory"
}

# Locate and import module
$modulePath = Join-Path -Path $WorkingDirectory -ChildPath 'DriverAutomationModule.psd1'
if (-not (Test-Path -Path $modulePath)) {
    throw "DriverAutomationModule module not found at $modulePath"
}

try {
    Import-Module -Name $modulePath -Force -ErrorAction Stop
    Write-Verbose "Successfully imported DriverAutomationModule from $modulePath"
}
catch {
    throw "Failed to import DriverAutomationModule from $modulePath : $_"
}

# Get Task Sequence data path
$TaskSequenceDataPath = Get-TSValue -Name '_SMSTSMDataPath'
if ([string]::IsNullOrWhiteSpace($TaskSequenceDataPath)) {
    throw "Task Sequence variable '_SMSTSMDataPath' is not set or is empty"
}

$CustomLocation = Join-Path -Path $TaskSequenceDataPath -ChildPath 'DriverPackage'
#endregion Initialize Variables

#region Helper Functions
function Invoke-FindPhase {
    [CmdletBinding()]
    param()

    if ($WhatIfPreference) {
        Write-Host "[WhatIf] Would execute Find phase: Search for driver package"
        return
    }

    Write-LogEntry -Message "Starting the driver package search" -Source $cmdletName -Severity 1

    try {
        $targetOS = Get-TSValue -Name 'OSDWindowsVersion'
        $serverFQDN = Get-TSValue -Name 'AdminServiceFQDN'
        $adminServiceUser = Get-TSValue -Name 'AdminServiceUser'
        $adminServicePass = Get-TSValue -Name 'AdminServicePass'

        if ([string]::IsNullOrWhiteSpace($serverFQDN)) {
            throw "Task Sequence variable 'AdminServiceFQDN' is not set or is empty"
        }

        $params = @{
            TargetOS   = $targetOS
            ServerFQDN = $serverFQDN
        }

        if (-not [string]::IsNullOrWhiteSpace($adminServiceUser) -and -not [string]::IsNullOrWhiteSpace($adminServicePass)) {
            $params['AdminServiceUser'] = $adminServiceUser
            $params['AdminServicePass'] = $adminServicePass
        }

        $result = Find-DriverPackage @params
        Write-LogEntry -Message "Driver package search completed successfully. PackageID: $($result.PackageID)" -Source $cmdletName -Severity 0
        return $result
    }
    catch {
        $errorMessage = "Driver package search failed: $_"
        Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
        throw $errorMessage
    }
}

function Invoke-DownloadPhase {
    [CmdletBinding()]
    param()

    if ($WhatIfPreference) {
        Write-Host "[WhatIf] Would execute Download phase: Download driver package to $CustomLocation"
        return
    }

    Write-LogEntry -Message "Starting the driver package download" -Source $cmdletName -Severity 1

    try {
        # Validate that Find phase has completed
        $driverPackageQueryResult = Get-DriverPackageQueryResult
        if (-not $driverPackageQueryResult -or [string]::IsNullOrWhiteSpace($driverPackageQueryResult.PackageID)) {
            throw "Driver package query result not found. Ensure the Find phase has completed successfully."
        }

        Write-LogEntry -Message "Downloading driver package to: $CustomLocation" -Source $cmdletName -Severity 1
        Get-DriverPackageContent -CustomLocation $CustomLocation
        Write-LogEntry -Message "Driver package download completed successfully" -Source $cmdletName -Severity 0
    }
    catch {
        $errorMessage = "Driver package download failed: $_"
        Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
        throw $errorMessage
    }
}

function Invoke-InstallPhase {
    [CmdletBinding()]
    param()

    if ($WhatIfPreference) {
        Write-Host "[WhatIf] Would execute Install phase: Install driver package"
        return
    }

    Write-LogEntry -Message "Starting the driver package installation" -Source $cmdletName -Severity 1

    try {
        $driverPackagePath = Get-TSValue -Name 'DriverPackagePath01'
        $osDisk = Get-TSValue -Name 'OSDTargetSystemDrive'
        $TaskSequenceDataPath = Get-TSValue -Name '_SMSTSMDataPath'

        if ([string]::IsNullOrWhiteSpace($driverPackagePath)) {
            throw "Task Sequence variable 'DriverPackagePath01' is not set or is empty"
        }
        if ([string]::IsNullOrWhiteSpace($osDisk)) {
            throw "Task Sequence variable 'OSDTargetSystemDrive' is not set or is empty"
        }
        if ([string]::IsNullOrWhiteSpace($TaskSequenceDataPath)) {
            throw "Task Sequence variable '_SMSTSMDataPath' is not set or is empty"
        }

        if (-not (Test-Path -Path $driverPackagePath)) {
            throw "Driver package path does not exist: $driverPackagePath"
        }

        $mountPath = Join-Path -Path $TaskSequenceDataPath -ChildPath 'Drivers'

        $params = @{
            DriverPackagePath = $driverPackagePath
            OSDisk           = $osDisk
            MountPath        = $mountPath
        }

        Install-DriverPackage @params
        Write-LogEntry -Message "Driver package installation completed successfully" -Source $cmdletName -Severity 0
    }
    catch {
        $errorMessage = "Driver package installation failed: $_"
        Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
        throw $errorMessage
    }
}
#endregion Helper Functions

#region Main Execution
try {
    switch ($Phase) {
        'Find' {
            Invoke-FindPhase
        }
        'Download' {
            Invoke-DownloadPhase
        }
        'Install' {
            Invoke-InstallPhase
        }
        default {
            Write-LogEntry -Message "Running all phases of driver package deployment" -Source $cmdletName -Severity 1

            if ($WhatIfPreference) {
                Write-Host "[WhatIf] Would execute all phases: Find, Download, Install"
                return
            }

            # Execute all phases sequentially with error handling
            $findResult = Invoke-FindPhase
            if ($null -eq $findResult) {
                throw "Find phase did not return a valid driver package result"
            }

            Invoke-DownloadPhase
            Invoke-InstallPhase

            Write-LogEntry -Message "All phases of driver package deployment completed successfully" -Source $cmdletName -Severity 0
        }
    }
}
catch {
    Write-LogEntry -Message "Driver package deployment failed: $_" -Source $cmdletName -Severity 3
    throw
}
#endregion Main Execution