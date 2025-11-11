function Set-LogFilePath {
    <#
    .SYNOPSIS
    Sets the log file path based on the script execution context.

    .DESCRIPTION
    Determines the appropriate log file path based on the execution environment.
    If running in Windows PE (WinPE) and a task sequence environment is available, uses the task sequence log directory (_SMSTSLogPath).
    If the task sequence environment is not available or not running in WinPE, uses the user's temporary directory.
    The function attempts to connect to the Task Sequence Environment COM object to retrieve the log path.

    .PARAMETER LogFileName
    The name of the log file (e.g., 'myLog.log'). This parameter is mandatory.

    .EXAMPLE
    Set-LogFilePath -LogFileName 'myLog.log'
    Returns the full path to the log file based on the current execution context.

    .INPUTS
    None
    This function does not accept pipeline input.

    .OUTPUTS
    System.String
    Returns the full path to the log file as a string.

    .NOTES
    Part of the DriverAutomationModule module.
    The function checks for the presence of the X:\ drive to determine if running in WinPE.
    If the Task Sequence Environment COM object cannot be accessed, the function falls back to using the temporary directory.

    .LINK
    https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the name of the log file")]
        [string]$LogFileName
    )

    process {
        try {
            Confirm-TSEnvironmentSetup
            $taskSequenceLogDirectory = $script:TaskSequenceEnvironment.Value('_SMSTSLogPath')
        }
        catch {
            Write-Host "Unable to connect to the Task Sequence Environment."
        }

        $logFilePath = if (Test-Path -Path 'X:\') {
            Join-Path -Path $taskSequenceLogDirectory -ChildPath $LogFileName
        }
        else {
            Join-Path -Path $env:TEMP -ChildPath $LogFileName
        }

        Write-Output $logFilePath
    }
}
