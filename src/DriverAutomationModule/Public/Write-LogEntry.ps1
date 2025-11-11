function Write-LogEntry {
    <#
    .SYNOPSIS
    Writes a message to the Configuration Manager log file and console.

    .DESCRIPTION
    This function writes a message to the Configuration Manager log file and console for debugging purposes.
    The function writes log entries in CMTrace-compatible format and also displays formatted messages to the console.
    If the module variable $script:LogFilePath is not set, it will be automatically initialized using Set-LogFilePath with the default log file name 'OSDeploymentKit.log'.
    The function supports pipeline input and can accept multiple messages as an array. Empty messages are automatically skipped.

    .PARAMETER Message
    The message or messages to write to the log file. Accepts a single string or an array of strings. Can accept pipeline input.
    Empty messages are automatically skipped. This parameter also accepts aliases 'Text' and 'Value'.

    .PARAMETER Source
    The source of the message. Default is 'Unknown Source'. This value appears in the log file's component attribute.

    .PARAMETER Severity
    The severity of the message. Default is 1 (Informational). Valid values are:
    - 0 (Success)
    - 1 (Informational)
    - 2 (Warning)
    - 3 (Error)

    .EXAMPLE
    Write-LogEntry -Message 'This is a test message.' -Source 'Test Source' -Severity 1
    Writes a single informational message to the log file and console.

    .EXAMPLE
    Write-LogEntry -Message @('First message', 'Second message') -Source 'MyScript' -Severity 2
    Writes multiple warning messages to the log file and console.

    .EXAMPLE
    'Pipeline message' | Write-LogEntry -Source 'PipelineTest' -Severity 0
    Writes a success message using pipeline input.

    .EXAMPLE
    Write-LogEntry -Text 'Using alias' -Source 'AliasTest'
    Writes a message using the 'Text' alias for the Message parameter.

    .INPUTS
    System.String[]
    You can pipe string objects to this function. Each piped string will be written as a separate log entry.

    .OUTPUTS
    None
    This function does not return any output.

    .NOTES
    Part of the DriverAutomationModule module.
    The log file format is compatible with Microsoft Configuration Manager CMTrace log viewer.
    Log entries include timestamp, date, component name, security context, severity type, thread ID, and the message content.

    .LINK
    https://github.com/adamaayala/DriverAutomationModule
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "The message to write to the log file.")]
        [AllowEmptyCollection()]
        [Alias('Text', 'Value')]
        [string[]]$Message,

        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "The source of the message. Default is 'Unknown Source'.")]
        [ValidateNotNullOrEmpty()]
        [string]$Source = 'Unknown Source',

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "The severity of the message. Default is 1 (Informational). Valid values are 0 (Success), 1 (Informational), 2 (Warning), and 3 (Error).")]
        [ValidateRange(0, 3)]
        [int16]$Severity = 1
    )
    process {
        if (-not $script:LogFilePath) {
            $script:LogFilePath = Set-LogFilePath -LogFileName ($MyInvocation.MyCommand.ModuleName + '.log')
        }

        $dateTimeNow = Get-Date
        $logTime = $dateTimeNow.ToString("HH:mm:ss.fff")
        $logDate = $dateTimeNow.ToString("MM-dd-yyyy")
        $logTimeZoneBias = [timezone]::CurrentTimeZone.GetUtcOffset($dateTimeNow).TotalMinutes
        $logTimeStamp = $logTime + $logTimeZoneBias

        $cmTraceLogString = {
            param ($lMessage, $lSource, $lSeverity)
            "<![LOG[$lMessage]LOG]!><time=`"$logTimeStamp`" date=`"$logDate`" component=`"$lSource`" context=`"$([Security.Principal.WindowsIdentity]::GetCurrent().Name)`" type=`"$lSeverity`" thread=`"$PID`" file=`"`">"
        }

        foreach ($msg in $Message) {
            if ($msg) {
                $timeStamp = "[$logDate $logTime]"
                $severityLabel = @('Success', 'Info', 'Warning', 'Error')[$Severity]
                $consoleLogLine = "$timeStamp $Source [$severityLabel] :: $msg"

                $cmTraceLogLine = & $cmTraceLogString $msg $Source $Severity

                try {
                    $cmTraceLogLine | Out-File -FilePath $script:LogFilePath -Append -NoClobber -Force -Encoding UTF8 -ErrorAction Stop
                }
                catch {
                    Write-Host "Failed to write message [$msg] to the log file."
                }

                Write-Host $consoleLogLine
            }
        }
    }
}
