---
external help file: DriverAutomationModule-help.xml
Module Name: DriverAutomationModule
online version: https://github.com/adamaayala/DriverAutomationModule
schema: 2.0.0.0
---

# Write-LogEntry

## SYNOPSIS
Writes a message to the Configuration Manager log file and console.

## SYNTAX

```
Write-LogEntry [-Message] <String[]> [[-Source] <String>] [[-Severity] <Int16>]
    [<CommonParameters>]
```

## DESCRIPTION
This function writes a message to the Configuration Manager log file and console for debugging purposes.
The function writes log entries in CMTrace-compatible format and also displays formatted messages to the console.
If the module variable $script:LogFilePath is not set, it will be automatically initialized using Set-LogFilePath with the default log file name 'OSDeploymentKit.log'.
The function supports pipeline input and can accept multiple messages as an array. Empty messages are automatically skipped.

## EXAMPLES

### Example 1
```
PS C:\> Write-LogEntry -Message 'This is a test message.' -Source 'Test Source' -Severity 1
```
Writes a single informational message to the log file and console.

### Example 2
```
PS C:\> Write-LogEntry -Message @('First message', 'Second message') -Source 'MyScript' -Severity 2
```
Writes multiple warning messages to the log file and console.

### Example 3
```
PS C:\> 'Pipeline message' | Write-LogEntry -Source 'PipelineTest' -Severity 0
```
Writes a success message using pipeline input.

### Example 4
```
PS C:\> Write-LogEntry -Text 'Using alias' -Source 'AliasTest'
```
Writes a message using the 'Text' alias for the Message parameter.

## PARAMETERS

### -Message
The message or messages to write to the log file. Accepts a single string or an array of strings. Can accept pipeline input.
Empty messages are automatically skipped. This parameter also accepts aliases 'Text' and 'Value'.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Text, Value

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue, ByPropertyName)
Accept wildcard characters: False
```

### -Source
The source of the message. Default is 'Unknown Source'. This value appears in the log file's component attribute.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Unknown Source
Accept pipeline input: False
Accept wildcard characters: False
```

### -Severity
The severity of the message. Default is 1 (Informational). Valid values are:
- 0 (Success)
- 1 (Informational)
- 2 (Warning)
- 3 (Error)

```yaml
Type: Int16
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]
You can pipe string objects to this function. Each piped string will be written as a separate log entry.

## OUTPUTS

### None
This function does not return any output.

## NOTES
Part of the DriverAutomationModule module.
The log file format is compatible with Microsoft Configuration Manager CMTrace log viewer.
Log entries include timestamp, date, component name, security context, severity type, thread ID, and the message content.

## RELATED LINKS
https://github.com/adamaayala/DriverAutomationModule

