function Invoke-OSDDownloadContent {
    <#
    .SYNOPSIS
        Starts the OSDDownloadContent executable during a task sequence.

    .DESCRIPTION
        This function initiates the OSDDownloadContent executable during a task sequence,
        utilizing OSDDownloadContent task sequence variables as parameters.

        The function uses Set-TSVariable to set the following task sequence variables before execution:
        - OSDDownloadDownloadPackages: The PackageID to download
        - OSDDownloadDestinationLocationType: The destination location type (Custom, TSCache, or CCMCache)
        - OSDDownloadDestinationVariable: The task sequence variable name to store the download location
        - OSDDownloadDestinationPath: The custom path (set to the CustomLocationPath value when provided, otherwise null/empty)

        The function automatically determines the OSDDownloadContent executable path:
        - In WinPE: Uses "OSDDownloadContent.exe" (assumes it's in the PATH)
        - In full OS: Uses "$env:WINDIR\CCM\OSDDownloadContent.exe"

        After execution, all task sequence variables are automatically cleared using Set-TSVariable with empty string values in the finally block, regardless of success or failure.

        This function supports two parameter sets:
        - NoPath: Used when DestinationLocationType is TSCache or CCMCache (CustomLocationPath not required)
        - CustomPath: Used when DestinationLocationType is Custom (CustomLocationPath is required)

    .PARAMETER PackageID
        The PackageID of the content to download. Must match the pattern "^[A-Z0-9]{3}[A-F0-9]{5}$" (e.g., "PKG00001", "ABC12345").

    .PARAMETER DestinationLocationType
        The location type for content download. Valid values are:
        - Custom: Download to a custom path specified by CustomLocationPath
        - TSCache: Download to the task sequence cache
        - CCMCache: Download to the Configuration Manager cache

    .PARAMETER DestinationVariableName
        The task sequence variable name to store the download location. This variable will contain the path where the content was downloaded after successful execution.

    .PARAMETER CustomLocationPath
        The custom path for content download when DestinationLocationType is set to Custom. This parameter is required when using the CustomPath parameter set.

    .INPUTS
        None
        This function does not accept pipeline input.

    .OUTPUTS
        None
        This function does not return any output. Success or failure is indicated through log entries and exception handling.

    .EXAMPLE
        PS C:\> Invoke-OSDDownloadContent -PackageID "PKG00001" -DestinationLocationType "TSCache" -DestinationVariableName "OSDDownloadDestinationPath"
        Downloads package PKG00001 to the task sequence cache and stores the path in the OSDDownloadDestinationPath task sequence variable.

    .EXAMPLE
        PS C:\> Invoke-OSDDownloadContent -PackageID "PKG00001" -DestinationLocationType "CCMCache" -DestinationVariableName "OSDDownloadDestinationPath"
        Downloads package PKG00001 to the Configuration Manager cache and stores the path in the OSDDownloadDestinationPath task sequence variable.

    .EXAMPLE
        PS C:\> Invoke-OSDDownloadContent -PackageID "PKG00001" -DestinationLocationType "Custom" -DestinationVariableName "OSDDownloadDestinationPath" -CustomLocationPath "C:\Temp"
        Downloads package PKG00001 to the custom path C:\Temp and stores the path in the OSDDownloadDestinationPath task sequence variable.

    .NOTES
        Part of the DriverAutomationModule module.
        This function requires a task sequence environment to be available.
        The function uses Confirm-TSEnvironmentSetup to verify the task sequence environment is properly initialized.
        The function uses Set-TSVariable to set and clear task sequence variables.
        All task sequence variables set by this function are automatically cleared after execution using Set-TSVariable with empty string values, regardless of success or failure.
        The OSDDownloadContent executable must be available in the system PATH (WinPE) or at $env:WINDIR\CCM\OSDDownloadContent.exe (full OS).

    .LINK
        https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "NoPath", HelpMessage = "Specify a PackageID to be downloaded.")]
        [Parameter(ParameterSetName = "CustomPath")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[A-Z0-9]{3}[A-F0-9]{5}$")]
        [string]$PackageID,

        [Parameter(Mandatory = $true, ParameterSetName = "NoPath", HelpMessage = "Specify the download location type.")]
        [Parameter(ParameterSetName = "CustomPath")]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Custom", "TSCache", "CCMCache")]
        [string]$DestinationLocationType,

        [Parameter(Mandatory = $true, ParameterSetName = "NoPath", HelpMessage = "Specify the variable name to save the download location.")]
        [Parameter(ParameterSetName = "CustomPath")]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationVariableName,

        [Parameter(Mandatory = $true, ParameterSetName = "CustomPath", HelpMessage = "Specify the custom path when location type is Custom.")]
        [ValidateNotNullOrEmpty()]
        [string]$CustomLocationPath
    )

    begin {
        $cmdletName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    process {
        try {
            Confirm-TSEnvironmentSetup
            # Set task sequence variables for OSDDownloadContent
            $tsVariables = @{
                "OSDDownloadDownloadPackages"        = $PackageID
                "OSDDownloadDestinationLocationType" = $DestinationLocationType
                "OSDDownloadDestinationVariable"     = $DestinationVariableName
                "OSDDownloadDestinationPath"         = $CustomLocationPath
            }

            foreach ($key in $tsVariables.Keys) {
                Set-TSVariable -Name $key -Value $tsVariables[$key]
                Write-LogEntry -Message "Set TS variable $key to $($tsVariables[$key])" -Source $cmdletName
            }

            # Determine OSDDownloadContent executable path
            $osdDownloadContentExecutablePath = if (Test-Path -Path 'HKLM:\SYSTEM\CurrentControlset\Control\MiniNT') {
                "OSDDownloadContent.exe"
            }
            else {
                Join-Path -Path $env:WINDIR -ChildPath "CCM\OSDDownloadContent.exe"
            }

            # Start OSDDownloadContent executable
            $processParams = @{
                FilePath    = $osdDownloadContentExecutablePath
                NoNewWindow = $true
                Wait        = $true
                ErrorAction = 'Stop'
            }
            Start-Process @processParams
            Write-LogEntry -Message "Successfully executed OSDDownloadContent" -Source $cmdletName
        }
        catch {
            $errorMessage = "Failed to execute OSDDownloadContent. Error: $_"
            Write-LogEntry -Message $errorMessage -Source $cmdletName -Severity 3
            throw $errorMessage
        }
        finally {
            # Clear task sequence variables
            $tsVariables.Keys | ForEach-Object {
                Set-TSVariable -Name $_ -Value [string]::Empty
            }
        }
    }

    end {
    }
}