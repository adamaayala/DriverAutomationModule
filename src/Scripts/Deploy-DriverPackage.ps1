<#
.SYNOPSIS
Deploy a driver package to a target system.
.DESCRIPTION
This script deploys a driver package to a target system. It searches for the driver package, downloads it, and installs it.
.PARAMETER Phase
The phase of the driver package deployment. Valid values are: Find, Download, Install. If not specified, the script runs all phases.
.PARAMETER WorkingDirectory
The working directory for the driver package deployment.
.EXAMPLE
.\Deploy-DriverPackage.ps1 -Phase Find
Searches for a driver package for the target OS and stores the result in the registry.
.EXAMPLE
.\Deploy-DriverPackage.ps1 -Phase Download
Downloads the driver package from the admin service to the specified custom location.
.EXAMPLE
.\Deploy-DriverPackage.ps1 -Phase Install
Installs the driver package from the specified custom location to the target system.
.EXAMPLE
.\Deploy-DriverPackage.ps1
Runs all phases of the driver package deployment.
.NOTES
This script is intended to be run as part of an OSD Task Sequence.
Part of the OSDeploymentKit module.
.LINK
https://github.com/adamaayala/OSDeploymentKit
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Find', 'Download', 'Install')]
    [string]$Phase,

    [Parameter(Mandatory = $false)]
    [string]$WorkingDirectory = $PSScriptRoot
)

#region Initialize Variables
$cmdletName = $MyInvocation.MyCommand.Name
$modulePath = Join-Path -Path $WorkingDirectory -ChildPath 'DriverAutomationModule.psd1'
if (-not (Test-Path -Path $modulePath)) { throw "DriverAutomationModule module not found at $modulePath" }; Import-Module -Name $modulePath -Force
$CustomLocation = Join-Path -Path (Get-TSValue -Name '_SMSTSMDataPath') -ChildPath 'DriverPackage'
#endregion Initialize Variables

switch ($Phase) {
    'Find' {
        Write-LogEntry -Message "Starting the driver package search" -Source $cmdletName
        $params = @{
            TargetOS         = Get-TSValue -Name 'OSDWindowsVersion'
            ServerFQDN       = Get-TSValue -Name 'AdminServiceFQDN'
            AdminServiceUser = Get-TSValue -Name 'AdminServiceUser'
            AdminServicePass = Get-TSValue -Name 'AdminServicePass'
        }
        Find-DriverPackage @params
        Write-LogEntry -Message "Driver package search completed" -Source $cmdletName -Severity 0
        break
    }
    'Download' {
        Write-LogEntry -Message "Starting the driver package download" -Source $cmdletName
        Get-DriverPackageContent -CustomLocation $CustomLocation
        Write-LogEntry -Message "Driver package download completed" -Source $cmdletName -Severity 0
        break
    }
    'Install' {
        Write-LogEntry -Message "Starting the driver package installation" -Source $cmdletName
        $params = @{
            DriverPackagePath = Get-TSValue -Name 'DriverPackagePath01'
            OSDisk            = Get-TSValue -Name 'OSDTargetSystemDrive'
            MountPath         = Join-Path -Path (Get-TSValue -Name '_SMSTSMDataPath') -ChildPath 'Drivers'
        }
        Install-DriverPackage @params
        Write-LogEntry -Message "Driver package installation completed" -Source $cmdletName -Severity 0
        break
    }
    default {
        Write-LogEntry -Message "Running all phases of driver package deployment" -Source $cmdletName
        . $PSCommandPath -Phase 'Find'
        . $PSCommandPath -Phase 'Download'
        . $PSCommandPath -Phase 'Install'
        break
    }
}
